/// Design publication status. The user app may only ever query
/// `status == 'active'` (security rules enforce this).
enum DesignStatus {
  draft('draft'),
  active('active'),
  archived('archived');

  final String value;
  const DesignStatus(this.value);

  static DesignStatus fromString(String? value) {
    return DesignStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DesignStatus.draft,
    );
  }
}

/// Image-processing state maintained by the `onDesignAssetUpload` Cloud
/// Function. Publishing (status → active) is blocked until [ready].
enum DesignProcessingStatus {
  pending('pending'),
  ready('ready'),
  failed('failed');

  final String value;
  const DesignProcessingStatus(this.value);

  static DesignProcessingStatus fromString(String? value) {
    return DesignProcessingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DesignProcessingStatus.pending,
    );
  }
}
