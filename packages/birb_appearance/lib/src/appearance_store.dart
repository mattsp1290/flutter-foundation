import 'appearance_mode.dart';

/// The resolved mode and whether it came from a valid persisted value.
typedef AppearanceReadResult = ({AppearanceMode mode, bool isPersisted});

/// Persists one application's selected appearance.
abstract interface class AppearanceStore {
  /// Reads the stored mode, resolving missing or unknown data to system mode.
  Future<AppearanceReadResult> read();

  /// Durably writes [mode].
  Future<void> write(AppearanceMode mode);
}
