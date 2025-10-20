class AppSettings {
  final bool notificationsEnabled;
  final bool autoRefreshEnabled;
  final int refreshInterval;

  const AppSettings({
    this.notificationsEnabled = true,
    this.autoRefreshEnabled = true,
    this.refreshInterval = 30,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? autoRefreshEnabled,
    int? refreshInterval,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
      refreshInterval: refreshInterval ?? this.refreshInterval,
    );
  }
}