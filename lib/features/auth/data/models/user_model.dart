class UserModel {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? bio;
  final String? specialty;
  final double? consultationFee;
  final bool isAvailable;
  final String role;
  final String? avatarUrl;
  final bool confirmed;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.bio,
    this.specialty,
    this.consultationFee,
    this.isAvailable = true,
    required this.role,
    this.avatarUrl,
    required this.confirmed,
  });

  String get fullName {
    if (firstName != null && lastName != null) return '$firstName $lastName';
    if (firstName != null) return firstName!;
    return username;
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: (json['username'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      specialty: json['specialty'] as String?,
      consultationFee: (json['consultationFee'] as num?)?.toDouble(),
      isAvailable: (json['isAvailable'] as bool?) ?? true,
      role: _extractRole(json),
      avatarUrl: _extractAvatarUrl(json),
      confirmed: (json['confirmed'] as bool?) ?? false,
    );
  }

  static String _extractRole(Map<String, dynamic> json) {
    final appRole = json['appRole'];
    if (appRole is String && appRole.isNotEmpty) return appRole;
    final roleObj = json['role'];
    if (roleObj is Map) {
      final type = (roleObj['type'] as String?) ?? '';
      if (type == 'doctor') return 'doctor';
      if (type == 'admin') return 'admin';
    }
    return 'patient';
  }

  static String? _extractAvatarUrl(Map<String, dynamic> json) {
    final avatar = json['avatar'];
    if (avatar is Map) {
      final formats = avatar['formats'] as Map?;
      final thumb = formats?['thumbnail'] as Map?;
      if (thumb != null) return thumb['url'] as String?;
      return avatar['url'] as String?;
    }
    if (avatar is String) return avatar;
    return null;
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? specialty,
    double? consultationFee,
    bool? isAvailable,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      username: username,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      specialty: specialty ?? this.specialty,
      consultationFee: consultationFee ?? this.consultationFee,
      isAvailable: isAvailable ?? this.isAvailable,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      confirmed: confirmed,
    );
  }
}
