import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart' as models;
import 'sync_service.dart';

/// Firestore-based implementation of [SyncService].
///
/// This implementation stores transactions in Cloud Firestore with the following
/// data structure for user data isolation:
///
/// ```
/// users/{userId}/transactions/{transactionId}
/// ```
///
/// Security is enforced by Firestore security rules that ensure users can only
/// access their own transactions.
///
/// Migration Note: If switching to a different backend, data can be exported
/// from Firestore using the Firebase Admin SDK or Cloud Functions.
class FirestoreSyncService implements SyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Collection name for user transactions (subcollection under users)
  static const String _transactionsCollection = 'transactions';

  /// Collection name for users
  static const String _usersCollection = 'users';

  /// Field name for storing sync metadata
  static const String _metadataDoc = '_sync_metadata';

  /// Creates a new FirestoreSyncService instance.
  ///
  /// Uses default Firebase instances if not provided.
  FirestoreSyncService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Gets the current authenticated user ID.
  ///
  /// Throws [SyncException] if no user is authenticated.
  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw SyncException(
        code: SyncException.notAuthenticated,
        message: 'User must be authenticated to sync transactions',
      );
    }
    return user.uid;
  }

  /// Gets the reference to the user's transactions collection.
  CollectionReference<Map<String, dynamic>> _transactionsRef() {
    return _firestore
        .collection(_usersCollection)
        .doc(_userId)
        .collection(_transactionsCollection);
  }

  /// Gets the reference to the user's sync metadata document.
  DocumentReference<Map<String, dynamic>> _metadataRef() {
    return _firestore
        .collection(_usersCollection)
        .doc(_userId)
        .collection(_transactionsCollection)
        .doc(_metadataDoc);
  }

  @override
  Future<List<models.Transaction>> loadTransactions() async {
    try {
      // Get all transactions, excluding metadata document
      final querySnapshot =
          await _transactionsRef().orderBy('date', descending: true).get();

      // Filter out metadata document and map to Transaction objects
      return querySnapshot.docs
          .where((doc) => doc.id != _metadataDoc)
          .map((doc) => _transactionFromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'loadTransactions');
    }
  }

  @override
  Future<void> saveTransactions(List<models.Transaction> transactions) async {
    try {
      // Firestore batch limit is 500 operations per batch.
      const batchLimit = 450; // Leave room for metadata operations

      // First, delete all existing transactions (except metadata) in batches
      final existingDocs = await _transactionsRef().get();
      final docsToDelete =
          existingDocs.docs.where((doc) => doc.id != _metadataDoc).toList();
      for (var i = 0; i < docsToDelete.length; i += batchLimit) {
        final chunk = docsToDelete.skip(i).take(batchLimit);
        final deleteBatch = _firestore.batch();
        for (final doc in chunk) {
          deleteBatch.delete(doc.reference);
        }
        await deleteBatch.commit();
      }

      // Then add all new transactions in batches
      if (transactions.isNotEmpty) {
        for (var i = 0; i < transactions.length; i += batchLimit) {
          final chunk = transactions.skip(i).take(batchLimit);
          final isLastBatch = i + batchLimit >= transactions.length;
          final createBatch = _firestore.batch();
          for (final transaction in chunk) {
            final docRef = _transactionsRef().doc(transaction.id.toString());
            createBatch.set(docRef, _transactionToFirestore(transaction));
          }
          // Update sync metadata on the last batch
          if (isLastBatch) {
            createBatch.set(
              _metadataRef(),
              {
                'lastSyncTime': FieldValue.serverTimestamp(),
                'transactionCount': transactions.length,
              },
              SetOptions(merge: true),
            );
          }
          await createBatch.commit();
        }
      } else {
        // If no transactions, still update metadata
        await _metadataRef().set(
          {
            'lastSyncTime': FieldValue.serverTimestamp(),
            'transactionCount': 0,
          },
          SetOptions(merge: true),
        );
      }
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'saveTransactions');
    }
  }

  @override
  Future<void> addTransaction(models.Transaction transaction) async {
    try {
      final batch = _firestore.batch();

      // Add the transaction
      final docRef = _transactionsRef().doc(transaction.id.toString());
      batch.set(docRef, _transactionToFirestore(transaction));

      // Update sync metadata
      batch.set(
        _metadataRef(),
        {
          'lastSyncTime': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'addTransaction');
    }
  }

  @override
  Future<void> deleteTransaction(int transactionId) async {
    try {
      final batch = _firestore.batch();

      // Delete the transaction
      final docRef = _transactionsRef().doc(transactionId.toString());
      batch.delete(docRef);

      // Update sync metadata
      batch.set(
        _metadataRef(),
        {
          'lastSyncTime': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'deleteTransaction');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      const batchLimit = 500;
      QuerySnapshot querySnapshot;
      do {
        querySnapshot = await _transactionsRef().limit(batchLimit).get();
        if (querySnapshot.docs.isEmpty) break;
        final batch = _firestore.batch();
        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } while (querySnapshot.docs.length == batchLimit);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'clearAll');
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        return false;
      }

      // Verify Firestore access by attempting to get user document
      // This will fail if rules prevent access
      await _firestore.collection(_usersCollection).doc(_userId).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    try {
      final doc = await _metadataRef().get();
      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      if (data == null || data['lastSyncTime'] == null) {
        return null;
      }

      return (data['lastSyncTime'] as Timestamp).toDate();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'getLastSyncTime');
    }
  }

  /// Converts a Firestore document to a Transaction.
  models.Transaction _transactionFromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final id = int.tryParse(doc.id);
    if (id == null) {
      throw SyncException(
        code: SyncException.unknown,
        message: 'Invalid transaction ID format: ${doc.id}',
      );
    }
    return models.Transaction(
      id: id,
      description: data['description'] as String,
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] as String,
      category: data['category'] as String,
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  /// Converts a Transaction to a Firestore document map.
  Map<String, dynamic> _transactionToFirestore(models.Transaction transaction) {
    return {
      'description': transaction.description,
      'amount': transaction.amount,
      'type': transaction.type,
      'category': transaction.category,
      'date': Timestamp.fromDate(transaction.date),
    };
  }

  /// Handles Firestore errors and converts them to SyncExceptions.
  SyncException _handleFirestoreError(FirebaseException e, String operation) {
    String code;
    String message;

    switch (e.code) {
      case 'permission-denied':
        code = SyncException.permissionDenied;
        message = 'Access denied. Please check your authentication.';
        break;
      case 'not-found':
        code = SyncException.notFound;
        message = 'The requested data was not found.';
        break;
      case 'unavailable':
      case 'network-request-failed':
        code = SyncException.networkError;
        message = 'Network error. Please check your connection and try again.';
        break;
      default:
        code = SyncException.unknown;
        message =
            'An unexpected error occurred during $operation: ${e.message}';
    }

    return SyncException(
      code: code,
      message: message,
      cause: e,
    );
  }
}
