import "package:json_guard/json_guard.dart" show Field, Schema;

class Weapon {
  final String name;
  final int damage;

  Weapon({required this.name, required this.damage});

  static final schema = Schema(
    fields: [Field.string("name"), Field.integer("damage", min: 1)],
    constructor: (data) => Weapon(name: data["name"], damage: data["damage"]),
  );

  @override
  String toString() => "Weapon(name: $name, damage: $damage)";
}

class Starship {
  final String model;
  final int crewSize;
  final Map<String, String> systems;
  final Map<String, Weapon> weapons;

  Starship({required this.model, required this.crewSize, required this.systems, required this.weapons});

  static final schema = Schema(
    fields: [
      Field.string("model"),
      Field.integer("crewSize", min: 1),
      Field.string("systems").map(fallback: {"BSC": "Basic"}),
      Field.nested("weapons", schema: Weapon.schema).map(),
    ],
    constructor: (data) {
      return Starship(
        model: data["model"],
        crewSize: data["crewSize"],
        systems: data["systems"],
        weapons: data["weapons"],
      );
    },
  );

  @override
  String toString() {
    final systemsStr = systems.values.map((s) => '"$s"').join(", ");
    return "Starship(model: $model, crewSize: $crewSize, systems: [$systemsStr], weapons: $weapons)";
  }
}

void main() {
  final millenniumFalcon = {
    "model": "YT-1300 Corellian light freighter",
    "crewSize": 4,
    "systems": {"HDR": "Hyperdrive", "SHD": "Shields", "NAC": "Navigation computer", "SLE": "Sublight engines"},
    "weapons": {
      "cannons": {"name": "Quad laser cannon", "damage": 10},
      "missiles": {"name": "Concussion missiles", "damage": 15},
    },
  };

  try {
    final falcon = Starship.schema.fromJson(millenniumFalcon);
    print("Valid starship: $falcon");

    // Invalid starship - weapon with negative damage
    final invalidStarship = {
      "model": "X-wing starfighter",
      "crewSize": 1,
      "systems": {"HDR": "Hyperdrive", "TCD": "Targeting computer"},
      "weapons": {
        "cannons": {
          "name": "Laser cannons",
          "damage": -5, // Invalid: negative damage
        },
      },
    };

    Starship.schema.fromJson(invalidStarship);
  } catch (e) {
    print("$e");
    // Validation error at $.weapons.cannons.damage (value: -5, type: int): Must be at least 1
  }
}
