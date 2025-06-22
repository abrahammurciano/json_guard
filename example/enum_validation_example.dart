import "package:json_guard/json_guard.dart" show Field, Schema;

enum ForceSide { light, dark, neutral }

enum LightsaberColor { blue, green, red, purple, yellow, white, black }

class ForceUser {
  final String name;
  final ForceSide side;
  final LightsaberColor saberColor;

  ForceUser({required this.name, required this.side, required this.saberColor});

  static final schema = Schema<ForceUser>(
    fields: [
      Field.string("name").field(),
      Field.enumeration<ForceSide>("side", values: ForceSide.values.asNameMap(), caseSensitive: false).field(),
      Field.enumeration<LightsaberColor>(
        "lightsaber",
        aliases: ["color", "bladeColor"],
        values: {for (final color in LightsaberColor.values) color.name.toUpperCase(): color},
        caseSensitive: true,
        fallback: LightsaberColor.blue,
      ).field(),
    ],
    constructor: (data) => ForceUser(name: data["name"], side: data["side"], saberColor: data["lightsaber"]),
  );

  @override
  String toString() => "ForceUser(name: $name, side: $side, saberColor: $saberColor)";
}

void main() {
  final lukeJson = {
    "name": "Luke Skywalker",
    "side": "light", // Case insensitive match
    "saber": "GREEN", // Using alias and case-sensitive match
  };

  final vaderJson = {
    "name": "Darth Vader",
    "side": "DARK", // Case insensitive match
    "bladeColor": "RED", // Using alias
  };

  try {
    final luke = ForceUser.schema.fromJson(lukeJson);
    print("Force user: $luke");

    final vader = ForceUser.schema.fromJson(vaderJson);
    print("Force user: $vader");

    // Validation error - invalid enum value
    final invalidJson = {
      "name": "Rey",
      "side": "light",
      "lightsaber": "green", // Wrong case, should be "GREEN"
    };

    ForceUser.schema.fromJson(invalidJson);
  } catch (e) {
    print("$e");
    // Field 'lightsaber': Validation failed for value 'green': Expected one of: BLUE, GREEN, RED, PURPLE, YELLOW, WHITE, BLACK (at $.lightsaber)
  }

  // Using fallback value for missing lightsaber
  final obiWanJson = {
    "name": "Obi-Wan Kenobi",
    "side": "light",
    // lightsaber missing, will use blue as fallback
  };

  final obiWan = ForceUser.schema.fromJson(obiWanJson);
  print("Force user with fallback: $obiWan");
}
