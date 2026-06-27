class HouseholdMemberInfo {
  const HouseholdMemberInfo({
    required this.userId,
    required this.username,
    required this.role,
    required this.joinedAt,
    this.avatarUrl,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;

  bool get isAdmin => role == 'admin';
}
