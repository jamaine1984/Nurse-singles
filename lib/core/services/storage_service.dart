import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Provides the singleton [StorageService] instance.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(
    storage: FirebaseStorage.instance,
    functions: FirebaseFunctions.instance,
  );
});

/// Firebase Cloud Storage helper for uploading and deleting app media.
class StorageService {
  StorageService({FirebaseStorage? storage, FirebaseFunctions? functions})
    : _storage = storage ?? FirebaseStorage.instance,
      _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  static const _uuid = Uuid();

  /// Uploads a profile image only after backend SafeSearch approval.
  Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    final ext = _extension(file.path);
    return _uploadModeratedImage(
      userId: userId,
      file: file,
      category: 'profile',
      pendingFolder: 'profile_images',
      destinationPath: 'profile_images/$userId/profile$ext',
    );
  }

  /// Uploads a gallery image only after backend SafeSearch approval.
  Future<String> uploadGalleryImage({
    required String userId,
    required File file,
  }) async {
    final uniqueId = _uuid.v4();
    final ext = _extension(file.path);
    return _uploadModeratedImage(
      userId: userId,
      file: file,
      category: 'gallery',
      pendingFolder: 'gallery_images',
      destinationPath: 'gallery_images/$userId/$uniqueId$ext',
    );
  }

  /// Uploads an image sent in chat only after backend SafeSearch approval.
  Future<String> uploadChatImage({
    required String userId,
    required String chatId,
    required File file,
  }) async {
    final uniqueId = _uuid.v4();
    final ext = _extension(file.path);
    return _uploadModeratedImage(
      userId: userId,
      file: file,
      category: 'chat',
      pendingFolder: 'chat_images/$chatId',
      destinationPath: 'chat_images/$chatId/$uniqueId$ext',
    );
  }

  /// Uploads a community post image only after backend SafeSearch approval.
  Future<String> uploadPostImage({
    required String userId,
    required File file,
  }) async {
    final uniqueId = _uuid.v4();
    final ext = _extension(file.path);
    return _uploadModeratedImage(
      userId: userId,
      file: file,
      category: 'post',
      pendingFolder: 'post_images',
      destinationPath: 'post_images/$userId/$uniqueId$ext',
    );
  }

  /// Deletes a file from Storage given its full download [url].
  ///
  /// Silently succeeds if the file no longer exists.
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  Future<String> _uploadModeratedImage({
    required String userId,
    required File file,
    required String category,
    required String pendingFolder,
    required String destinationPath,
  }) async {
    final uniqueId = _uuid.v4();
    final ext = _extension(file.path);
    final contentType = _contentType(file.path);
    final pendingPath = 'pending_uploads/$userId/$pendingFolder/$uniqueId$ext';
    final ref = _storage.ref().child(pendingPath);

    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {
        'uploadedBy': userId,
        'moderationStatus': 'pending',
        'category': category,
        'destinationPath': destinationPath,
      },
    );

    try {
      await ref.putFile(file, metadata);
      final callable = _functions.httpsCallable('moderateUploadedImage');
      final result = await callable.call<Map<String, dynamic>>({
        'storagePath': pendingPath,
        'destinationPath': destinationPath,
        'category': category,
        'contentType': contentType,
      });
      final downloadUrl = result.data['downloadUrl'];
      if (downloadUrl is String && downloadUrl.isNotEmpty) {
        return downloadUrl;
      }
      throw FirebaseFunctionsException(
        code: 'internal',
        message: 'Image moderation did not return a download URL.',
      );
    } catch (_) {
      try {
        await ref.delete();
      } catch (_) {
        // The backend may already delete rejected or failed pending uploads.
      }
      rethrow;
    }
  }

  /// Resolves a MIME content type from the file extension.
  String _contentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  /// Extracts the file extension, including the dot.
  String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    return path.substring(dot);
  }
}
