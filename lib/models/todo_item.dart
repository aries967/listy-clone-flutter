import 'package:listy/models/collection.dart';

class TodoItem implements FirestoreSavable {
  String name;
  bool isCompleted;
  bool isEditing;

  TodoItem({
    required this.name,
    this.isCompleted = false,
    this.isEditing = false,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      name: json['name'],
      isCompleted: json['isCompleted'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isCompleted': isCompleted,
    };
  }
  
  @override
  bool canBeSavedToFirestore() {
    return !isEditing;
  }
}