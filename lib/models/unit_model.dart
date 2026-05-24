class UnitModel {
  final int id;
  final String name;

  UnitModel({required this.id, required this.name});

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'name': name};
}
