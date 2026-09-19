

class OneSignalConfig {
  final String appId;
  final bool requiresUserPrivacyConsent;

  const OneSignalConfig({
    required this.appId,
    this.requiresUserPrivacyConsent = false,
  });
}
