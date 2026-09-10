import 'package:shared_preferences/shared_preferences.dart';

import 'appearance_mode.dart';
import 'appearance_store.dart';

/// An [AppearanceStore] backed by uncached asynchronous preferences.
final class PreferencesAppearanceStore implements AppearanceStore {
  PreferencesAppearanceStore({
    required String applicationNamespace,
    SharedPreferencesAsync? preferences,
  }) : applicationNamespace = _validateNamespace(applicationNamespace),
       _preferences = preferences ?? SharedPreferencesAsync();

  /// The application-specific namespace used by this store.
  final String applicationNamespace;

  final SharedPreferencesAsync _preferences;

  /// The sole preference key owned by this store.
  String get storageKey => '$applicationNamespace.appearance.mode.v1';

  @override
  Future<AppearanceReadResult> read() async {
    final value = await _preferences.getString(storageKey);
    if (value == null) {
      return (mode: AppearanceMode.system, isPersisted: false);
    }
    try {
      return (mode: AppearanceMode.parse(value), isPersisted: true);
    } on FormatException {
      return (mode: AppearanceMode.system, isPersisted: false);
    }
  }

  @override
  Future<void> write(AppearanceMode mode) {
    return _preferences.setString(storageKey, mode.persistedValue);
  }

  static String _validateNamespace(String value) {
    if (value.isEmpty ||
        value.trim() != value ||
        !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'applicationNamespace',
        'must contain only letters, digits, underscores, or hyphens',
      );
    }
    return value;
  }
}
