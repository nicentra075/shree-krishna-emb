/// User role stored in `users/{uid}.role` and mirrored to Firebase Auth
/// custom claims by the `onUserWrite` Cloud Function.
enum UserRole {
  admin('admin'),
  designer('designer'),
  user('user');

  final String value;
  const UserRole(this.value);

  /// Unknown/legacy values (e.g. old 'buyer'/'vendor') normalize to [user].
  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.user,
    );
  }
}
