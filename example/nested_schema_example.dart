import "package:json_guard/json_guard.dart" show Field, Schema;

class Coordinates {
  final int x;
  final int y;

  Coordinates({required this.x, required this.y});

  static final schema = Schema<Coordinates>(
    fields: [Field.integer("x").field(), Field.integer("y").field()],
    constructor: (data) => Coordinates(x: data["x"], y: data["y"]),
  );

  @override
  String toString() => "Coordinates(x: $x, y: $y)";
}

class StarSystem {
  final String name;
  final int planets;
  final Coordinates location;

  StarSystem({required this.name, required this.planets, required this.location});

  static final schema = Schema<StarSystem>(
    fields: [
      Field.string("name", minLength: 3).field(),
      Field.integer("planets", min: 0).field(),
      Field.nested("location", schema: Coordinates.schema).field(),
    ],
    constructor: (data) => StarSystem(name: data["name"], planets: data["planets"], location: data["location"]),
  );

  @override
  String toString() => "StarSystem(name: $name, planets: $planets, location: $location)";
}

void main() {
  final tatooineSystem = {
    "name": "Tatoo",
    "planets": 2,
    "location": {"x": 43, "y": -15},
  };

  final coruscantSystem = {
    "name": "Coruscant",
    "planets": 1,
    "location": {
      "x": 0,
      "y": 0, // Galactic center
    },
  };

  try {
    final tatoo = StarSystem.schema.fromJson(tatooineSystem);
    print("Valid star system: $tatoo");

    final coruscant = StarSystem.schema.fromJson(coruscantSystem);
    print("Valid star system: $coruscant");

    // Invalid system - nested schema validation error
    final invalidSystem = {
      "name": "Alderaan",
      "planets": 1,
      "location": {
        "x": "invalid", // Not a number
        "y": 12,
      },
    };

    StarSystem.schema.fromJson(invalidSystem);
  } catch (e) {
    print("$e");
    // Field 'location.x': Validation failed for value 'invalid': Failed to parse integer (at $.location.x)
  }
}
