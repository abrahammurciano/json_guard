import "package:json_guard/json_guard.dart" show Field, Schema;

class Movie {
  final String name;
  final DateTime releaseDate;

  Movie({required this.name, required this.releaseDate});

  static final schema = Schema(
    fields: [
      Field.string("name"),
      Field.datetime("releaseDate", min: DateTime(1977), max: DateTime.now()),
    ],
    constructor: (data) => Movie(name: data["name"], releaseDate: data["releaseDate"]),
  );

  @override
  String toString() => "Movie(name: $name, releaseDate: ${_formatDate(releaseDate)})";

  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

void main() {
  final starWars = {
    "name": "Star Wars: A New Hope",
    "releaseDate": "1977-05-25T00:00:00Z", // ISO 8601 format
  };

  try {
    final movie = Movie.schema.fromJson(starWars);
    print("Valid movie: $movie");

    // Invalid movie - release date before minimum
    final invalidMovie = {
      "name": "Old Movie",
      "releaseDate": "1960-01-01T00:00:00Z", // Before 1977
    };

    Movie.schema.fromJson(invalidMovie);
  } catch (e) {
    print("$e");
    // Validation error at $.releaseDate (value: 1960-01-01T00:00:00Z, type: String): Date must be at or after 1977-01-01 00:00:00.000
  }
}
