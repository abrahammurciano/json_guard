import "package:json_guard/json_guard.dart" show Field, Schema;
import "package:json_guard/src/validators/string_validator.dart";

class Planet {
  final String name;
  final String sector;
  final String climate;
  final String terrain;

  Planet({required this.name, required this.sector, required this.climate, required this.terrain});

  static final schema = Schema<Planet>(
    fields: [
      Field.string("name", minLength: 3, maxLength: 30, trim: true).field(),
      Field.string("sector", pattern: RegExp(r"^[a-zA-Z0-9\- ]+$"), caseType: StringCase.upper).field(),
      Field.string("climate", options: {"temperate", "tropical", "arid", "frozen", "hot"}).field(),
      Field.string("terrain", aliases: ["surface", "geography"], fallback: "unknown").field(),
    ],
    constructor: (data) {
      return Planet(name: data["name"], sector: data["sector"], climate: data["climate"], terrain: data["terrain"]);
    },
  );

  @override
  String toString() => "Planet(name: $name, sector: $sector, climate: $climate, terrain: $terrain)";
}

void main() {
  final tatooine = {
    "name": "  Tatooine  ", // Will be trimmed
    "sector": "ARKANIS SECTOR",
    "climate": "arid",
    "surface": "desert", // Using alias
  };

  final naboo = {
    "name": "Naboo",
    "sector": "Chommell Sector", // Will be converted to uppercase
    "climate": "temperate",
    // terrain is missing, will use fallback
  };

  try {
    final tatooineResult = Planet.schema.fromJson(tatooine);
    print("Tatooine: $tatooineResult");

    final nabooResult = Planet.schema.fromJson(naboo);
    print("Naboo: $nabooResult");

    // Validation error - invalid climate
    final invalidPlanet = {
      "name": "Mustafar",
      "sector": "OUTER RIM",
      "climate": "volcanic", // Not in options
    };

    Planet.schema.fromJson(invalidPlanet);
  } catch (e) {
    print("$e");
    // Field 'climate': Validation failed for value 'volcanic': String must be one of: temperate, tropical, arid, frozen, hot (at $.climate)
  }
}
