import 'package:listy/models/collection.dart';

class Book implements FirestoreSavable {
  final String title;
  final String author;
  final String thumbnailUrl;

  Book({required this.title, required this.author, required this.thumbnailUrl});

  factory Book.fromApiJson(Map<String, dynamic> json) {
    String getAuthor(dynamic authors) {
      if (authors is List && authors.isNotEmpty) {
        return authors[0];
      }
      return 'Unknown Author';
    }
    
    String getThumbnail(dynamic coverId) {
        if (coverId != null) {
            return 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
        }
        return 'https://placehold.co/128x192?text=No\\nImage';
    }

    return Book(
      title: json['title'] ?? 'Untitled',
      author: getAuthor(json['author_name']),
      thumbnailUrl: getThumbnail(json['cover_i']),
    );
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'],
      author: json['author'],
      thumbnailUrl: json['thumbnailUrl'],
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'thumbnailUrl': thumbnailUrl,
    };
  }
  
  @override
  bool canBeSavedToFirestore() => true;
}