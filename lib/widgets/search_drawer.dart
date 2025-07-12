import 'package:flutter/material.dart';
import 'dart:async';
import 'package:listy/models/collection.dart';
import 'package:listy/models/book.dart';
import 'package:listy/models/movie.dart';
import 'package:listy/services/api_service.dart'; // This must point to the correct file.

class SearchDrawer extends StatefulWidget {
  final CollectionType collectionType;
  final Function(Book) onBookSelected;
  final Function(Movie) onMovieSelected;

  const SearchDrawer({
    super.key,
    required this.collectionType,
    required this.onBookSelected,
    required this.onMovieSelected,
  });

  @override
  State<SearchDrawer> createState() => _SearchDrawerState();
}

class _SearchDrawerState extends State<SearchDrawer> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch();
      } else {
        setState(() {
          _results = [];
          _errorMessage = '';
        });
      }
    });
  }

  void _performSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      dynamic searchResult;
      if (widget.collectionType == CollectionType.book) {
        searchResult = await ApiService.searchBooks(_searchController.text);
      } else if (widget.collectionType == CollectionType.movie) {
        searchResult = await ApiService.searchMovies(_searchController.text);
      }
      setState(() {
        _results = searchResult;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch results. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.collectionType == CollectionType.book ? 'Search Books' : 'Search Movies';
    String hintText = widget.collectionType == CollectionType.book ? 'e.g., The Lord of the Rings' : 'e.g., Inception';

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12.0, bottom: 12.0),
              height: 5,
              width: 40,
              decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                    : _results.isEmpty && _searchController.text.isNotEmpty
                        ? const Center(child: Text('No results found.'))
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final item = _results[index];
                              if (item is Book) {
                                return ListTile(
                                  leading: Image.network(item.thumbnailUrl, width: 40, fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.book)),
                                  title: Text(item.title),
                                  subtitle: Text(item.author),
                                  onTap: () {
                                    widget.onBookSelected(item);
                                    Navigator.pop(context);
                                  },
                                );
                              }
                              if (item is Movie) {
                                return ListTile(
                                  leading: Image.network(item.posterUrl, width: 40, fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.movie)),
                                  title: Text(item.title),
                                  subtitle: Text(item.year),
                                  onTap: () {
                                    widget.onMovieSelected(item);
                                    Navigator.pop(context);
                                  },
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}