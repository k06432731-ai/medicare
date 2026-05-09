import 'user_model.dart';

class AuthResponseModel {
  final String jwt;
  final UserModel user;

  const AuthResponseModel({required this.jwt, required this.user});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      jwt: json['jwt'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
