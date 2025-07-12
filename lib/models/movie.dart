import 'package:listy/models/collection.dart';

class Movie implements FirestoreSavable {
  final String title;
  final String year;
  final String posterUrl;

  Movie({required this.title, required this.year, required this.posterUrl});

  // Factory for creating an instance from the OMDb API JSON
  factory Movie.fromApiJson(Map<String, dynamic> json) {
    return Movie(
      title: json['Title'] ?? 'Untitled',
      year: json['Year'] ?? 'N/A',
      posterUrl:
          (json['Poster'] != null && json['Poster'] != 'N/A')
              ? json['Poster']
              : 'https://placehold.co/185x278?text=No\\nPoster',
    );
  }

  // Factory for creating an instance from local storage JSON
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['title'],
      year: json['year'],
      posterUrl: json['posterUrl'],
    );
  }

  // Method to convert an instance to JSON for local storage
  Map<String, dynamic> toJson() {
    return {'title': title, 'year': year, 'posterUrl': posterUrl};
  }

  @override
  bool canBeSavedToFirestore() => true;
}
