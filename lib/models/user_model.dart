class UserModel {
  final String id;
  final String email;
  final String name;
  final String? profilePictureUrl;

  UserModel({required this.id, required this.email, required this.name, this.profilePictureUrl});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(id: json['id'], email: json['email'], name: json['name'], profilePictureUrl: json['profile_picture_url']);
}
