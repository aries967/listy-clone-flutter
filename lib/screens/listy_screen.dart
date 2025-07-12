import 'package:flutter/material.dart';
import 'package:listy/models/collection.dart' as app_model;
import 'package:listy/screens/collection_detail_screen.dart';
import 'package:listy/services/auth_service.dart';
import 'package:listy/services/firestore_service.dart';

class ListyScreen extends StatefulWidget {
  const ListyScreen({super.key});

  @override
  State<ListyScreen> createState() => _ListyScreenState();
}

class _ListyScreenState extends State<ListyScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _collectionNameController = TextEditingController();

  @override
  void dispose() {
    _collectionNameController.dispose();
    super.dispose();
  }

  // --- Core Logic Methods ---
  void _addCollection({
    required String name,
    required app_model.CollectionType type,
    required IconData icon,
  }) {
    if (name.isNotEmpty) {
      final newCollection = app_model.Collection(
        name: name,
        icon: icon,
        type: type,
        items: [],
      );
      // Calls Firestore service to add the collection
      _firestoreService.addCollection(newCollection);
      _collectionNameController.clear();
      Navigator.pop(context);
    }
  }

  void _editCollectionName(String collectionId, String newName) {
    if (newName.isNotEmpty) {
      // Calls Firestore service to update the name
      _firestoreService.updateCollectionName(collectionId, newName);
      Navigator.pop(context); // Close the edit dialog
    }
  }

  void _deleteCollection(String collectionId) {
    // Calls Firestore service to delete the collection
    _firestoreService.deleteCollection(collectionId);
  }

  // --- UI Methods ---
  void _showCollectionOptions(app_model.Collection collection) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Name'),
              onTap: () {
                Navigator.pop(context); // Close the options sheet
                _showEditCollectionDialog(collection);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context); // Close the options sheet
                _showDeleteConfirmationDialog(
                  title: 'Delete Collection?',
                  content: 'Are you sure you want to delete "${collection.name}"?',
                  // Pass the Firestore document ID to the delete method
                  onConfirm: () => _deleteCollection(collection.id!),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditCollectionDialog(app_model.Collection collection) {
    _collectionNameController.text = collection.name;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Collection Name'),
          content: TextField(
            controller: _collectionNameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Save'),
              // Pass the Firestore document ID to the edit method
              onPressed: () => _editCollectionName(collection.id!, _collectionNameController.text),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                onConfirm();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddCollectionDrawer({
    required app_model.CollectionType type,
    required IconData icon,
    required String typeName,
  }) {
    _collectionNameController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return _AddCollectionSheet(
          collectionNameController: _collectionNameController,
          onAdd: (name) => _addCollection(name: name, type: type, icon: icon),
          icon: icon,
          typeName: typeName,
        );
      },
    );
  }

  void _navigateToDetail(app_model.Collection collection) {
    // Pass the Firestore document ID to the detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionDetailScreen(collectionId: collection.id!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 24.0, top: 24.0),
                    child: Text("Listy", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    tooltip: "Sign Out",
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    onPressed: () async {
                      await _authService.signOut();
                    },
                  ),
                ],
              ),
              // Use a StreamBuilder to listen for real-time data from Firestore
              Expanded(
                child: StreamBuilder<List<app_model.Collection>>(
                  stream: _firestoreService.getCollections(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Something went wrong: ${snapshot.error}'));
                    }

                    final collections = snapshot.data ?? [];

                    if (collections.isEmpty) {
                      return const Center(
                        child: Text(
                          'No collections yet.\nTap the + button to add one!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      );
                    }
                    
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220.0,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 3 / 2,
                      ),
                      itemCount: collections.length,
                      itemBuilder: (context, index) {
                        final collection = collections[index];
                        return _CollectionCard(
                          collection: collection,
                          onTap: () => _navigateToDetail(collection),
                          onLongPress: () => _showCollectionOptions(collection),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return DraggableScrollableSheet(
                initialChildSize: 1.0,
                minChildSize: 0.15,
                maxChildSize: 1.0,
                builder: (_, controller) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ListView(
                      controller: controller,
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12.0, bottom: 20.0),
                            height: 5,
                            width: 40,
                            decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          child: Text("Pick a Category", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                        _CategoryCard(
                          title: "To-Do",
                          subtitle: "A simple list for your tasks.",
                          icon: Icons.list_alt,
                          onTap: () {
                            Navigator.pop(context);
                            _showAddCollectionDrawer(
                              type: app_model.CollectionType.todo,
                              icon: Icons.list_alt,
                              typeName: "To-Do List",
                            );
                          },
                        ),
                        _CategoryCard(
                          title: "Books",
                          subtitle: "A collection of your favorite reads.",
                          icon: Icons.book,
                          onTap: () {
                            Navigator.pop(context);
                            _showAddCollectionDrawer(
                              type: app_model.CollectionType.book,
                              icon: Icons.book,
                              typeName: "Book Collection",
                            );
                          },
                        ),
                        _CategoryCard(
                          title: "Movies",
                          subtitle: "A watchlist of films.",
                          icon: Icons.movie,
                          onTap: () {
                            Navigator.pop(context);
                            _showAddCollectionDrawer(
                              type: app_model.CollectionType.movie,
                              icon: Icons.movie,
                              typeName: "Movie Collection",
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final app_model.Collection collection;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CollectionCard({
    required this.collection,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(collection.icon, size: 28, color: Colors.white70),
                  Text(
                    collection.items.length.toString(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Text(
                collection.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _AddCollectionSheet extends StatefulWidget {
  final TextEditingController collectionNameController;
  final Function(String) onAdd;
  final IconData icon;
  final String typeName;

  const _AddCollectionSheet({
    required this.collectionNameController,
    required this.onAdd,
    required this.icon,
    required this.typeName,
  });

  @override
  State<_AddCollectionSheet> createState() => _AddCollectionSheetState();
}

class _AddCollectionSheetState extends State<_AddCollectionSheet> {
  bool _isInputEmpty = true;

  @override
  void initState() {
    super.initState();
    _isInputEmpty = widget.collectionNameController.text.isEmpty;
    widget.collectionNameController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {
        _isInputEmpty = widget.collectionNameController.text.isEmpty;
      });
    }
  }

  @override
  void dispose() {
    widget.collectionNameController.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    "Name your new ${widget.typeName.toLowerCase()}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widget.collectionNameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Collection Name",
                  suffixIcon: !_isInputEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () => widget.collectionNameController.clear(),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey[800],
                  ),
                  onPressed: _isInputEmpty
                      ? null
                      : () => widget.onAdd(widget.collectionNameController.text),
                  child: const Text(
                    "Create",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}