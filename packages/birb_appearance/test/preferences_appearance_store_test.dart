import 'package:birb_appearance/birb_appearance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesAppearanceStore', () {
    late InMemorySharedPreferencesAsync backend;

    setUp(() {
      backend = InMemorySharedPreferencesAsync.empty();
      SharedPreferencesAsyncPlatform.instance = backend;
    });

    test('rejects unsafe application namespaces', () {
      for (final namespace in <String>[
        '',
        ' birb',
        'birb ',
        'birb party',
        'birb.party',
        'birb:party',
        'birb/party',
      ]) {
        expect(
          () => PreferencesAppearanceStore(applicationNamespace: namespace),
          throwsArgumentError,
          reason: namespace,
        );
      }
    });

    test('reads and writes exactly one namespaced key', () async {
      backend = InMemorySharedPreferencesAsync.withData(<String, Object>{
        'other.appearance.mode.v1': 'light',
      });
      SharedPreferencesAsyncPlatform.instance = backend;
      final preferences = SharedPreferencesAsync();
      final store = PreferencesAppearanceStore(
        applicationNamespace: 'birb_party',
        preferences: preferences,
      );

      expect(store.storageKey, 'birb_party.appearance.mode.v1');
      expect(await store.read(), AppearanceMode.system);

      await store.write(AppearanceMode.dark);

      expect(await preferences.getString(store.storageKey), 'dark');
      expect(await preferences.getString('other.appearance.mode.v1'), 'light');
      expect(await preferences.getKeys(), <String>{
        'other.appearance.mode.v1',
        store.storageKey,
      });
    });

    test('resolves unknown storage to system without rewriting it', () async {
      const key = 'catalog.appearance.mode.v1';
      backend = InMemorySharedPreferencesAsync.withData(<String, Object>{
        key: 'sepia',
      });
      SharedPreferencesAsyncPlatform.instance = backend;
      final preferences = SharedPreferencesAsync();
      final store = PreferencesAppearanceStore(
        applicationNamespace: 'catalog',
        preferences: preferences,
      );

      expect(await store.read(), AppearanceMode.system);
      expect(await preferences.getString(key), 'sepia');
    });

    test('round-trips every mode', () async {
      final store = PreferencesAppearanceStore(
        applicationNamespace: 'round_trip',
        preferences: SharedPreferencesAsync(),
      );

      for (final mode in AppearanceMode.values) {
        await store.write(mode);
        expect(await store.read(), mode);
      }
    });
  });
}
