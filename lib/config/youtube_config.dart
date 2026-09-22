/*
 * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *
 * This source code is licensed under the GPL-2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

class YouTubeConfig {
  YouTubeConfig._();

  /// API key provided at compile time via:
  /// `flutter run --dart-define=YOUTUBE_API_KEY=your_key_here`
  /// or configured default key.
  static const String apiKeyFromEnv = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: 'AIzaSyCkG3liYmQjAIHp6MHXAClh00AgN3mEDCU',
  );

  /// Runtime override if entered in the UI
  static String _runtimeApiKey = '';

  static String get runtimeApiKey => _runtimeApiKey;

  static set runtimeApiKey(String value) {
    _runtimeApiKey = value.trim();
  }

  /// Returns active key: prefers runtime override, then environment definition
  static String get activeApiKey {
    if (_runtimeApiKey.isNotEmpty) return _runtimeApiKey;
    return apiKeyFromEnv;
  }

  /// Whether an API key is available
  static bool get hasApiKey => activeApiKey.isNotEmpty;
}
