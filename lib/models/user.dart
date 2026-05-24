class User {
  final int id;
  final int roleId;
  final String name;
  final String email;
  final String? roleName;
  final String? roleDisplayName;
  final String? token;

  User({
    required this.id,
    required this.roleId,
    required this.name,
    required this.email,
    this.roleName,
    this.roleDisplayName,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as Map<String, dynamic>?;
    return User(
      id: json['id'] ?? 0,
      roleId: json['role_id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      roleName: role?['name'] ?? json['role_name'],
      roleDisplayName: role?['display_name'] ?? json['role_display_name'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role_id': roleId,
    'name': name,
    'email': email,
    'role_name': roleName,
    'role_display_name': roleDisplayName,
  };

  bool get isAdmin => roleName == 'admin' || roleId == 1;
  bool get isCashier => roleName == 'cashier' || roleId == 2;
}
