class User {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String? profileImage;
  final String? profileImageUrl;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.profileImage,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      emailVerifiedAt: json['email_verified_at'],
      profileImage: json['profile_image'],
      profileImageUrl: json['profile_image_url'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'profile_image': profileImage,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}