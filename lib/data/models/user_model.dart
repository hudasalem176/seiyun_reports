class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  // هذي بيانات المشرف والمواطن تضاف لاحقا
  final String? street;
  final String? district;
  final String? type; // للمشرف

  UserModel({
    required this.id, 
    required this.name, 
    required this.email, 
    required this.role,
    this.street,
    this.district,
    this.type,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      street: json['street'], 
      district: json['district'], 
      type: json['type'],
    );
  }
}