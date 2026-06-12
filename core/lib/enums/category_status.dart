/// Category lifecycle status. Categories with designs are archived, never
/// deleted, so existing designs keep a valid categoryId.
enum CategoryStatus {
  active('active'),
  archived('archived');

  final String value;
  const CategoryStatus(this.value);

  static CategoryStatus fromString(String? value) {
    return CategoryStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CategoryStatus.active,
    );
  }
}
