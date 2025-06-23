import "package:json_guard/json_guard.dart" show Field, Schema;

class Weapon {
  final String name;
  final int damage;

  Weapon({required this.name, required this.damage});

  static final schema = Schema<Weapon>(
    fields: [Field.string("name").field(), Field.integer("damage", min: 1).field()],
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

  static final schema = Schema<Starship>(
    fields: [
      Field.string("model").field(),
      Field.integer("crewSize", min: 1).field(),
      Field.string("systems").map(fallback: {"BSC": "Basic"}).field(),
      Field.nested("weapons", schema: Weapon.schema).map().field(),
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
    // Field 'damage': Validation failed for value '-5': Must be at least 1 (at $.weapons.cannons.damage)
  }
}
