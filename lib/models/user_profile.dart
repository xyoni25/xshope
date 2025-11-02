class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime joinDate;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.joinDate,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      joinDate: data['joinDate'] != null 
          ? DateTime.parse(data['joinDate']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'joinDate': joinDate.toIso8601String(),
    };
  }
}