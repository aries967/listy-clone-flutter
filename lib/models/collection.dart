import 'package:flutter/material.dart';
import 'package:listy/models/book.dart';
import 'package:listy/models/movie.dart';
import 'package:listy/models/todo_item.dart';

// Enum remains the same
enum CollectionType { todo, book, movie }

class Collection {
  String? id; // Document ID from Firestore
  String name;
  final IconData icon;
  final CollectionType type;
  List<dynamic> items;

  Collection({
    this.id,
    required this.name,
    required this.icon,
    required this.type,
    required this.items,
  });

  // Create a Collection from a Firestore document
  factory Collection.fromFirestore(Map<String, dynamic> data, String documentId) {
    var type = CollectionType.values.byName(data['type']);
    List<dynamic> items = [];
    if (data['items'] != null) {
      switch (type) {
        case CollectionType.todo:
          items = (data['items'] as List).map((i) => TodoItem.fromJson(i)).toList();
          break;
        case CollectionType.book:
          items = (data['items'] as List).map((i) => Book.fromJson(i)).toList();
          break;
        case CollectionType.movie:
          items = (data['items'] as List).map((i) => Movie.fromJson(i)).toList();
          break;
      }
    }
    return Collection(
      id: documentId,
      name: data['name'],
      icon: IconData(data['icon'], fontFamily: 'MaterialIcons'),
      type: type,
      items: items,
    );
  }

  // Convert a Collection instance to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon.codePoint,
      'type': type.name,
      'items': items.map((item) => (item as FirestoreSavable).toJson()).toList(),
    };
  }
}

// Add an interface to ensure all item models have toJson and canBeSavedToFirestore
abstract class FirestoreSavable {
  Map<String, dynamic> toJson();
  bool canBeSavedToFirestore();
}