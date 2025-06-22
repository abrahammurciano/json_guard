import "package:json_guard/json_guard.dart" show Field, Schema;

class Character {
  final String name;
  final String species;
  final int age;

  Character({required this.name, required this.species, required this.age});

  static final schema = Schema<Character>(
    fields: [
      Field.string("name", minLength: 2).field(),
      Field.string("species", fallback: "Unknown").field(),
      Field.integer("age", min: 0, max: 1000).field(),
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
