import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project.dart';
import 'project_sync_service.dart';

/// Firestore-based implementation of [ProjectSyncService].
///
/// This implementation stores projects in Cloud Firestore with the following
/// data structure:
///
/// ```
/// users/{userId}/projects/{projectId}
/// users/{userId}/projects/{projectId}/transactions/{transactionId}
/// ```
///
/// Security is enforced by Firestore security rules.
class FirestoreProjectSyncService implements ProjectSyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Collection name for projects (subcollection under users)
  static const String _projectsCollection = 'projects';

  /// Collection name for users
  static const String _usersCollection = 'users';

  /// Field name for storing sync metadata
  static const String _metadataDoc = '_sync_metadata';

  /// Creates a new FirestoreProjectSyncService instance.
  FirestoreProjectSyncService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Gets the current authenticated user ID.
  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw ProjectSyncException(
        code: ProjectSyncException.notAuthenticated,
        message: 'User must be authenticated to sync projects',
      );
    }
    return user.uid;
  }

  /// Gets the reference to the user's projects collection.
  CollectionReference<Map<String, dynamic>> _projectsRef() {
    return _firestore
        .collection(_usersCollection)
        .doc(_userId)
        .collection(_projectsCollection);
  }

  /// Gets the reference to the projects sync metadata document.
  DocumentReference<Map<String, dynamic>> _metadataRef() {
    return _firestore
        .collection(_usersCollection)
        .doc(_userId)
        .collection(_projectsCollection)
        .doc(_metadataDoc);
  }

  @override
  Future<List<Project>> loadProjects() async {
    try {
      final querySnapshot = await _projectsRef()
          .orderBy('createdAt', descending: false)
          .get();

      // Filter out metadata document and map to Project objects
      return querySnapshot.docs
          .where((doc) => doc.id != _metadataDoc)
          .map((doc) => Project.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'loadProjects');
    }
  }

  @override
  Future<void> createProject(Project project) async {
    try {
      final batch = _firestore.batch();

      // Create the project
      final docRef = _projectsRef().doc(project.id);
      batch.set(docRef, project.toFirestore());

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
      throw _handleFirestoreError(e, 'createProject');
    }
  }

  @override
  Future<void> updateProject(Project project) async {
    try {
      final batch = _firestore.batch();

      // Update the project
      final docRef = _projectsRef().doc(project.id);
      batch.update(docRef, project.toFirestore());

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
      throw _handleFirestoreError(e, 'updateProject');
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {
    try {
      final batch = _firestore.batch();

      // Soft delete by setting deletedAt
      final docRef = _projectsRef().doc(projectId);
      batch.update(docRef, {
        'deletedAt': FieldValue.serverTimestamp(),
      });

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
      throw _handleFirestoreError(e, 'deleteProject');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      const batchLimit = 500;
      QuerySnapshot querySnapshot;
      do {
        querySnapshot = await _projectsRef().limit(batchLimit).get();
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
      if (_auth.currentUser == null) {
        return false;
      }

      // Verify Firestore access
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

  /// Handles Firestore errors and converts them to ProjectSyncExceptions.
  ProjectSyncException _handleFirestoreError(
      FirebaseException e, String operation) {
    String code;
    String message;

    switch (e.code) {
      case 'permission-denied':
        code = ProjectSyncException.permissionDenied;
        message = 'Access denied. Please check your authentication.';
        break;
      case 'not-found':
        code = ProjectSyncException.notFound;
        message = 'The requested project was not found.';
        break;
      case 'unavailable':
      case 'network-request-failed':
        code = ProjectSyncException.networkError;
        message = 'Network error. Please check your connection and try again.';
        break;
      default:
        code = ProjectSyncException.unknown;
        message =
            'An unexpected error occurred during $operation: ${e.message}';
    }

    return ProjectSyncException(
      code: code,
      message: message,
      cause: e,
    );
  }
}
