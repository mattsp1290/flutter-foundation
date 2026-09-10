import 'appearance_mode.dart';

/// Persists one application's selected appearance.
abstract interface class AppearanceStore {
  /// Reads the stored mode, resolving missing or unknown data to system mode.
  Future<AppearanceMode> read();

  /// Durably writes [mode].
  Future<void> write(AppearanceMode mode);
}
