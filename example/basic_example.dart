import "package:json_guard/json_guard.dart" show Field, Schema;

class Character {
  final String name;
  final String species;
  final int age;

  Character({required this.name, required this.species, required this.age});

  static final schema = Schema(
    fields: [
      Field.string("name", minLength: 2),
      Field.string("species", fallback: "Unknown"),
      Field.integer("age", min: 0, max: 1000),
    ],
    constructor: (data) => Character(name: data["name"], species: data["species"], age: data["age"]),
  );

  @override
  String toString() => "Character(name: $name, species: $species, age: $age)";
}

void main() {
  final jsonData = {"name": "Luke Skywalker", "species": "Human", "age": 23};

  try {
    final character = Character.schema.fromJson(jsonData);
    print("Valid character: $character");

    // Invalid character - age constraint violation
    final invalidJson = {
      "name": "Yoda",
      "age": -1, // Age below minimum
    };

    Character.schema.fromJson(invalidJson);
  } catch (e) {
    print("$e");
  }
}
