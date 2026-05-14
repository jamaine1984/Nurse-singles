import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the singleton [FirestoreService] instance.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(firestore: FirebaseFirestore.instance);
});

/// Generic Firestore helper that wraps common CRUD, streaming, and batch
/// operations so that feature-level services stay thin.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Direct access when callers need to build custom queries.
  FirebaseFirestore get instance => _firestore;

  // ─── Single Document ─────────────────────────────────────────────────

  /// Fetches a single document from [collectionPath] by [docId].
  /// Returns `null` when the document does not exist.
  Future<Map<String, dynamic>?> getDocument({
    required String collectionPath,
    required String docId,
  }) async {
    final doc = await _firestore.collection(collectionPath).doc(docId).get();
    if (!doc.exists || doc.data() == null) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  /// Creates or overwrites a document. Uses merge when [merge] is `true`.
  Future<void> setDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    await _firestore
        .collection(collectionPath)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
  }

  /// Partially updates an existing document.
  Future<void> updateDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collectionPath).doc(docId).update(data);
  }

  /// Deletes a document by ID.
  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) async {
    await _firestore.collection(collectionPath).doc(docId).delete();
  }

  // ─── Collections / Queries ───────────────────────────────────────────

  /// Fetches a collection with optional pagination.
  ///
  /// * [limit] – max documents to return (defaults to 20).
  /// * [startAfterDoc] – the last [DocumentSnapshot] from the previous page;
  ///   pass `null` for the first page.
  /// * [orderBy] – field name to order by.
  /// * [descending] – sort direction.
  /// * [whereConditions] – list of `(field, operator, value)` triples used to
  ///   build `where` clauses. Supported operators: `==`, `!=`, `<`, `<=`,
  ///   `>`, `>=`, `array-contains`, `array-contains-any`, `in`, `not-in`.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getCollection({
    required String collectionPath,
    int limit = 20,
    DocumentSnapshot? startAfterDoc,
    String? orderBy,
    bool descending = false,
    List<QueryCondition>? whereConditions,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);

    // Apply where clauses
    if (whereConditions != null) {
      for (final condition in whereConditions) {
        query = _applyWhere(query, condition);
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Pagination cursor
    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs;
  }

  /// Adds a new document with an auto-generated ID.
  /// Returns the generated document ID.
  Future<String> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    final docRef = await _firestore.collection(collectionPath).add(data);
    return docRef.id;
  }

  // ─── Streams ─────────────────────────────────────────────────────────

  /// Streams a single document as a map.
  Stream<Map<String, dynamic>?> streamDocument({
    required String collectionPath,
    required String docId,
  }) {
    return _firestore
        .collection(collectionPath)
        .doc(docId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return {'id': doc.id, ...doc.data()!};
    });
  }

  /// Streams a collection query, returning raw [QuerySnapshot]s so callers
  /// can map to their own model types.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection({
    required String collectionPath,
    int? limit,
    String? orderBy,
    bool descending = false,
    List<QueryCondition>? whereConditions,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);

    if (whereConditions != null) {
      for (final condition in whereConditions) {
        query = _applyWhere(query, condition);
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  // ─── Batch Writes ────────────────────────────────────────────────────

  /// Executes a batch of writes atomically.
  ///
  /// [operations] receives a [WriteBatch] that the caller populates.
  Future<void> batchWrite(
    void Function(WriteBatch batch) operations,
  ) async {
    final batch = _firestore.batch();
    operations(batch);
    await batch.commit();
  }

  /// Convenience: deletes a list of documents in a single batch.
  Future<void> batchDelete({
    required String collectionPath,
    required List<String> docIds,
  }) async {
    final batch = _firestore.batch();
    for (final id in docIds) {
      batch.delete(_firestore.collection(collectionPath).doc(id));
    }
    await batch.commit();
  }

  /// Convenience: sets multiple documents in a single batch.
  Future<void> batchSet({
    required String collectionPath,
    required Map<String, Map<String, dynamic>> docsById,
    bool merge = false,
  }) async {
    final batch = _firestore.batch();
    for (final entry in docsById.entries) {
      batch.set(
        _firestore.collection(collectionPath).doc(entry.key),
        entry.value,
        SetOptions(merge: merge),
      );
    }
    await batch.commit();
  }

  // ─── Transaction ─────────────────────────────────────────────────────

  /// Runs a Firestore transaction.
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) handler,
  ) {
    return _firestore.runTransaction(handler);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  /// Returns a [DocumentReference] for direct use.
  DocumentReference<Map<String, dynamic>> docRef(
    String collectionPath,
    String docId,
  ) {
    return _firestore.collection(collectionPath).doc(docId);
  }

  /// Returns a [CollectionReference] for direct use.
  CollectionReference<Map<String, dynamic>> collectionRef(
    String collectionPath,
  ) {
    return _firestore.collection(collectionPath);
  }

  /// Applies a single where condition to a query.
  Query<Map<String, dynamic>> _applyWhere(
    Query<Map<String, dynamic>> query,
    QueryCondition condition,
  ) {
    switch (condition.operator) {
      case QueryOperator.isEqualTo:
        return query.where(condition.field, isEqualTo: condition.value);
      case QueryOperator.isNotEqualTo:
        return query.where(condition.field, isNotEqualTo: condition.value);
      case QueryOperator.isLessThan:
        return query.where(condition.field, isLessThan: condition.value);
      case QueryOperator.isLessThanOrEqualTo:
        return query.where(condition.field, isLessThanOrEqualTo: condition.value);
      case QueryOperator.isGreaterThan:
        return query.where(condition.field, isGreaterThan: condition.value);
      case QueryOperator.isGreaterThanOrEqualTo:
        return query.where(condition.field,
            isGreaterThanOrEqualTo: condition.value);
      case QueryOperator.arrayContains:
        return query.where(condition.field, arrayContains: condition.value);
      case QueryOperator.arrayContainsAny:
        return query.where(condition.field,
            arrayContainsAny: condition.value as List);
      case QueryOperator.whereIn:
        return query.where(condition.field, whereIn: condition.value as List);
      case QueryOperator.whereNotIn:
        return query.where(condition.field,
            whereNotIn: condition.value as List);
    }
  }
}

// ─── Query Condition Types ───────────────────────────────────────────────────

/// Supported Firestore query operators.
enum QueryOperator {
  isEqualTo,
  isNotEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
  arrayContains,
  arrayContainsAny,
  whereIn,
  whereNotIn,
}

/// A single where-clause condition.
class QueryCondition {
  const QueryCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  final String field;
  final QueryOperator operator;
  final dynamic value;
}
