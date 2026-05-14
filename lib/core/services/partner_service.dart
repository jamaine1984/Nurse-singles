import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';

final partnerServiceProvider = Provider<PartnerService>((ref) {
  return PartnerService();
});

class PartnerService {
  PartnerService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  String? normalizePartnerCode(String? value) {
    final cleaned = value?.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9_-]'),
      '',
    );
    if (cleaned == null || cleaned.isEmpty) return null;
    return cleaned;
  }

  Stream<PartnerOrganization?> watchPartnerByCode(String? rawCode) {
    final partnerCode = normalizePartnerCode(rawCode);
    if (partnerCode == null) return Stream.value(null);

    return _firestore
        .collection(AppConstants.partnerOrganizationsCollection)
        .doc(partnerCode)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return PartnerOrganization.fromMap(partnerCode, doc.data()!);
        });
  }

  Future<PartnerOrganization> applyPartnerCode(String rawCode) async {
    final partnerCode = normalizePartnerCode(rawCode);
    if (partnerCode == null) {
      throw ArgumentError('Partner code is required.');
    }

    final callable = _functions.httpsCallable('applyPartnerCode');
    final response = await callable.call<Map<String, dynamic>>({
      'partnerCode': partnerCode,
    });
    return PartnerOrganization.fromMap(partnerCode, response.data);
  }
}

class PartnerOrganization {
  const PartnerOrganization({
    required this.partnerCode,
    required this.organizationName,
    required this.organizationTypeLabel,
    required this.preferredGiveback,
    required this.preferredGivebackLabel,
    required this.status,
    required this.signupCount,
    required this.eligibleRevenueCents,
    required this.givebackCents,
    this.lastSignupAt,
  });

  final String partnerCode;
  final String organizationName;
  final String organizationTypeLabel;
  final String preferredGiveback;
  final String preferredGivebackLabel;
  final String status;
  final int signupCount;
  final int eligibleRevenueCents;
  final int givebackCents;
  final DateTime? lastSignupAt;

  factory PartnerOrganization.fromMap(
    String fallbackCode,
    Map<String, dynamic> data,
  ) {
    return PartnerOrganization(
      partnerCode: data['partnerCode'] as String? ?? fallbackCode,
      organizationName:
          data['organizationName'] as String? ?? 'Healthcare partner',
      organizationTypeLabel:
          data['organizationTypeLabel'] as String? ?? 'Partner',
      preferredGiveback:
          data['preferredGiveback'] as String? ?? 'nursing_scholarship',
      preferredGivebackLabel:
          data['preferredGivebackLabel'] as String? ??
          'Nursing scholarship fund',
      status: data['status'] as String? ?? 'active',
      signupCount: (data['signupCount'] as num?)?.toInt() ?? 0,
      eligibleRevenueCents:
          (data['eligibleRevenueCents'] as num?)?.toInt() ?? 0,
      givebackCents: (data['givebackCents'] as num?)?.toInt() ?? 0,
      lastSignupAt: (data['lastSignupAt'] as Timestamp?)?.toDate(),
    );
  }

  String get formattedGiveback {
    final dollars = givebackCents / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }
}
