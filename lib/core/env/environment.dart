class Environment {
  static const String dev = 'dev';
  static const String prod = 'prod';
  static const String test = 'test';

  static const String _currentEnvironment = String.fromEnvironment(
    'ENV',
    defaultValue: dev,
  );

  // API URLs
  static final String _devApiUrl = 'https://5eb1-202-28-7-39.ngrok-free.app';
  static const String _prodApiUrl = 'https://api.aspeak.com'; // Replace with your production API
  static const String _testApiUrl = 'https://test-api.aspeak.com'; // Replace with your test API

  // Current environment properties
  static bool get isDev => _currentEnvironment == dev;
  static bool get isProd => _currentEnvironment == prod;
  static bool get isTest => _currentEnvironment == test;

  // API URL based on environment
  static String get apiBaseUrl {
    if (isDev) return _devApiUrl;
    if (isProd) return _prodApiUrl;
    if (isTest) return _testApiUrl;
    return _devApiUrl; // Default to dev
  }
}