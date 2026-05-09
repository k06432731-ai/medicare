import 'package:equatable/equatable.dart';

class DoctorModel extends Equatable {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? specialty;
  final String? licenseNumber;
  final String? bio;
  final double? consultationFee;
  final bool isAvailable;
  final String? avatarUrl;

  const DoctorModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.specialty,
    this.licenseNumber,
    this.bio,
    this.consultationFee,
    this.isAvailable = true,
    this.avatarUrl,
  });

  String get fullName {
    if (firstName != null && lastName != null) return '$firstName $lastName';
    return username;
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    return username.substring(0, 2).toUpperCase();
  }

  String get displaySpecialty => specialty ?? 'Généraliste';

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar'];
    String? avatarUrl;
    if (avatar is Map) {
      avatarUrl = avatar['url'] as String?;
    }

    return DoctorModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      specialty: json['specialty'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      bio: json['bio'] as String?,
      consultationFee: (json['consultationFee'] as num?)?.toDouble(),
      isAvailable: json['isAvailable'] as bool? ?? true,
      avatarUrl: avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'specialty': specialty,
        'consultationFee': consultationFee,
        'isAvailable': isAvailable,
      };

  @override
  List<Object?> get props => [id, username, email, specialty, isAvailable];
}
