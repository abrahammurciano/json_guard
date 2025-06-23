enum TestEnum { light, dark, neutral }

class TestModel {
  final String name;
  final int age;

  TestModel({required this.name, required this.age});

  @override
  bool operator ==(Object other) => other is TestModel && other.name == name && other.age == age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}
