import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:listy/models/book.dart';
import 'package:listy/models/movie.dart';

class ApiService {
  static const String _omdbApiKey = '7b125d3e';
  static const String _omdbBaseUrl = 'http://www.omdbapi.com/';
  static const String _openLibraryBaseUrl = 'https://openlibrary.org/search.json';

  // Searches for books using the Open Library API
  static Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) return [];
    
    final response = await http.get(Uri.parse('$_openLibraryBaseUrl?q=${Uri.encodeComponent(query)}&limit=10'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> docs = data['docs'] ?? [];
      // Use the dedicated factory for API responses
      return docs.map((json) => Book.fromApiJson(json)).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }

  // Searches for movies using the OMDb API
  static Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];

    final response = await http.get(Uri.parse('$_omdbBaseUrl?s=${Uri.encodeComponent(query)}&apikey=$_omdbApiKey'));

    if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Response'] == 'True') {
            final List<dynamic> searchResults = data['Search'];
            // Use the dedicated factory for API responses
            return searchResults.map((json) => Movie.fromApiJson(json)).toList();
        } else {
            return []; // Return empty list if OMDb gives an error (e.g., "Movie not found!")
        }
    } else {
      throw Exception('Failed to load movies');
    }
  }
}