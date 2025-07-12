import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listy/models/collection.dart' as app_model;
import 'package:listy/models/todo_item.dart';
import 'package:listy/models/book.dart';
import 'package:listy/models/movie.dart';
import 'package:listy/services/firestore_service.dart';
import 'package:listy/widgets/search_drawer.dart';

class CollectionDetailScreen extends StatefulWidget {
  final String collectionId;
  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _taskController = TextEditingController();
  
  // Local UI state to manage when the "add new task" field is visible
  bool _isAddingNewTask = false;

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  // --- Item Interaction Methods ---
  void _updateItems(app_model.Collection collection) {
    _firestoreService.updateItems(collection.id!, collection.items);
  }

  void _deleteItem(app_model.Collection collection, int index) {
    collection.items.removeAt(index);
    _updateItems(collection);
  }
  
  void _showDeleteItemConfirmation(app_model.Collection collection, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Item?'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                _deleteItem(collection, index);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showItemDetails(dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.2,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(24.0),
                children: [
                  if (item is Book) ...[
                    Image.network(item.thumbnailUrl, height: 200, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.book, size: 100)),
                    const SizedBox(height: 16),
                    Text(item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(item.author, style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white70)),
                  ],
                  if (item is Movie) ...[
                    Image.network(item.posterUrl, height: 250, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.movie, size: 100)),
                    const SizedBox(height: 16),
                    Text(item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(item.year, style: const TextStyle(fontSize: 18, color: Colors.white70)),
                  ],
                  if (item is TodoItem) ...[
                    Text(item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Chip(
                      label: Text(item.isCompleted ? 'Completed' : 'Pending'),
                      backgroundColor: item.isCompleted ? Colors.green : Colors.orange,
                    )
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- To-Do Methods ---
  void _enterEditMode() {
    // If we are already adding a task, do nothing.
    if (_isAddingNewTask) return;
    setState(() {
      _isAddingNewTask = true;
    });
  }

  void _saveNewTask(app_model.Collection collection) {
    if (_taskController.text.isNotEmpty) {
      final newItem = TodoItem(name: _taskController.text);
      collection.items.insert(0, newItem);
      _updateItems(collection);
    }
    _taskController.clear();
    setState(() {
      _isAddingNewTask = false;
    });
  }
  
  // --- Book/Movie Methods ---
  void _addItem(app_model.Collection collection, dynamic item) {
    collection.items.insert(0, item);
    _updateItems(collection);
  }
  
  // --- Show Search Drawer Method ---
  void _showSearchDrawer(app_model.Collection collection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 1.0,
          builder: (_, controller) {
            return SearchDrawer(
              collectionType: collection.type,
              onBookSelected: (book) => _addItem(collection, book),
              onMovieSelected: (movie) => _addItem(collection, movie),
            );
          },
        );
      },
    );
  }

  // --- Main Build Method ---
   @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestoreService.getCollectionStream(widget.collectionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Add the color property here
          return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.blue)));
        }
        if (snapshot.hasError) {
          return Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Collection not found.')));
        }
        
        final collection = app_model.Collection.fromFirestore(snapshot.data!.data()!, snapshot.data!.id);

        return _buildViewForType(collection);
      },
    );
  }
  
  Widget _buildViewForType(app_model.Collection collection) {
    switch (collection.type) {
      case app_model.CollectionType.todo:
        return _buildTodoView(collection);
      case app_model.CollectionType.book:
        return _buildMediaView(collection);
      case app_model.CollectionType.movie:
        return _buildMediaView(collection);
    }
  }

  // --- UI Build Methods ---
   Widget _buildTodoView(app_model.Collection collection) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(collection.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                // Conditionally show the "add new" text field
                if (_isAddingNewTask)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: _taskController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "Enter new task name...",
                        border: const UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _saveNewTask(collection),
                        ),
                      ),
                      onSubmitted: (_) => _saveNewTask(collection),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: collection.items.length,
                    itemBuilder: (context, index) {
                      final item = collection.items[index] as TodoItem;
                      return GestureDetector(
                        onLongPress: () =>
                            _showDeleteItemConfirmation(collection, index),
                        onTap: () => _showItemDetails(item),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Checkbox(
                            value: item.isCompleted,
                            activeColor: Colors.blue, // Checkbox color
                            onChanged: (val) {
                              item.isCompleted = val ?? false;
                              _updateItems(collection);
                            },
                          ),
                          title: Text(item.name,
                              style: TextStyle(
                                  decoration: item.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context))),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
        onPressed: _enterEditMode,
        backgroundColor: Colors.blue, // Button background color
        foregroundColor: Colors.white, // Button icon color
        shape: const CircleBorder(),
        child: const Icon(Icons.add)),
  );
}

  Widget _buildMediaView(app_model.Collection collection) {
    bool isBook = collection.type == app_model.CollectionType.book;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(collection.name, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: collection.items.length,
                      itemBuilder: (context, index) {
                        final item = collection.items[index];
                        return GestureDetector(
                          onLongPress: () => _showDeleteItemConfirmation(collection, index),
                          onTap: () => _showItemDetails(item),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: (isBook && item is Book) 
                              ? ListTile(
                                  leading: Image.network(item.thumbnailUrl, fit: BoxFit.cover, width: 50, errorBuilder: (c, e, s) => const Icon(Icons.book, size: 40)),
                                  title: Text(item.title),
                                  subtitle: Text(item.author),
                                )
                              : (!isBook && item is Movie)
                                ? ListTile(
                                    leading: Image.network(item.posterUrl, fit: BoxFit.cover, width: 50, errorBuilder: (c, e, s) => const Icon(Icons.movie, size: 40)),
                                    title: Text(item.title),
                                    subtitle: Text(item.year),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSearchDrawer(collection),
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}