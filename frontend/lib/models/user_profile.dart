class UserProfile {
  final int id;
  final String displayName;
  final String email;
  final String? phoneNumber;
  final String? location;
  final DateTime? memberSince;
  final String? bio;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.phoneNumber,
    this.location,
    this.memberSince,
    this.bio,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      location: json['location'] as String?,
      memberSince: json['memberSince'] == null ? null : DateTime.tryParse(json['memberSince'] as String),
      bio: json['bio'] as String?,
    );
  }
}
