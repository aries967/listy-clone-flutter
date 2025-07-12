import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:listy/models/collection.dart' as app_model;

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get the current user's UID
  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  // --- Collection Methods ---

  // Get a real-time stream of collections for the current user
  Stream<List<app_model.Collection>> getCollections() {
    final userId = getUserId();
    if (userId == null) return Stream.value([]);

    return _db.collection('users').doc(userId).collection('collections').snapshots().map(
      (snapshot) => snapshot.docs.map(
        (doc) => app_model.Collection.fromFirestore(doc.data(), doc.id)
      ).toList()
    );
  }
  
  // Add a new collection
  Future<void> addCollection(app_model.Collection collection) async {
    final userId = getUserId();
    if (userId == null) return;

    await _db.collection('users').doc(userId).collection('collections').add(collection.toFirestore());
  }

  // Update a collection's name
  Future<void> updateCollectionName(String collectionId, String newName) async {
    final userId = getUserId();
    if (userId == null) return;

    await _db.collection('users').doc(userId).collection('collections').doc(collectionId).update({'name': newName});
  }

  // Delete a collection
  Future<void> deleteCollection(String collectionId) async {
    final userId = getUserId();
    if (userId == null) return;

    await _db.collection('users').doc(userId).collection('collections').doc(collectionId).delete();
  }
  
  // --- Item Methods ---

  // Get a real-time stream of a single collection's data
  Stream<DocumentSnapshot<Map<String, dynamic>>> getCollectionStream(String collectionId) {
     final userId = getUserId();
     if (userId == null) {
       // Return an empty stream or throw an error if user is not logged in
       return Stream.error('User not authenticated');
     }
     return _db.collection('users').doc(userId).collection('collections').doc(collectionId).snapshots();
  }
  
  // Update the entire list of items in a collection
  Future<void> updateItems(String collectionId, List<dynamic> items) async {
    final userId = getUserId();
    if (userId == null) return;

    // Correctly filter and map the items to a List<Map<String, dynamic>>
    final List<Map<String, dynamic>> itemsJson = items
        .where((item) => (item as app_model.FirestoreSavable).canBeSavedToFirestore())
        .map((item) => (item as app_model.FirestoreSavable).toJson())
        .toList();

    await _db.collection('users').doc(userId).collection('collections').doc(collectionId).update({'items': itemsJson});
  }
}