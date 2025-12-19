class AuthResponse {
  final int userId;
  final String email;
  final String displayName;

  AuthResponse({
    required this.userId,
    required this.email,
    required this.displayName,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId'] as int,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
    );
  }
}
