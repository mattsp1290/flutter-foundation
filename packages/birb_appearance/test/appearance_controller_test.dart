import 'dart:async';

import 'package:birb_appearance/birb_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts in explicit loading and system state', () {
    final controller = AppearanceController(
      store: _ImmediateStore(AppearanceMode.dark),
    );
    addTearDown(controller.dispose);

    expect(controller.isInitializing, isTrue);
    expect(controller.isInitialized, isFalse);
    expect(controller.selectedMode, AppearanceMode.system);
    expect(controller.themeMode, ThemeMode.system);
    expect(controller.lastPersistedMode, isNull);
  });

  test('initializes once from durable storage', () async {
    final store = _ImmediateStore(AppearanceMode.dark);
    final controller = AppearanceController(store: store);
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    final first = controller.initialize();
    final second = controller.initialize();
    expect(identical(first, second), isTrue);
    await first;

    expect(store.readCount, 1);
    expect(controller.isInitialized, isTrue);
    expect(controller.isInitializing, isFalse);
    expect(controller.selectedMode, AppearanceMode.dark);
    expect(controller.lastPersistedMode, AppearanceMode.dark);
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.readError, isNull);
    expect(notifications, 1);
  });

  test('makes read failures nonfatal and observable', () async {
    final error = StateError('read failed');
    final controller = AppearanceController(
      store: _ImmediateStore(AppearanceMode.system, readError: error),
    );
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.isInitialized, isTrue);
    expect(controller.selectedMode, AppearanceMode.system);
    expect(controller.lastPersistedMode, isNull);
    expect(controller.readError, same(error));
    expect(controller.readErrorStackTrace, isNotNull);
  });

  testWidgets('times out after two seconds and ignores the late read', (
    tester,
  ) async {
    final read = Completer<AppearanceMode>();
    final store = _ControlledStore(onRead: () => read.future);
    final controller = AppearanceController(store: store);
    addTearDown(controller.dispose);

    final initialization = controller.initialize();
    await tester.pump(const Duration(seconds: 2));

    expect(controller.isInitialized, isTrue);
    expect(controller.selectedMode, AppearanceMode.system);
    expect(controller.lastPersistedMode, isNull);
    expect(controller.readError, isA<TimeoutException>());

    read.complete(AppearanceMode.dark);
    await tester.pump();
    await initialization;

    expect(controller.selectedMode, AppearanceMode.system);
    expect(controller.lastPersistedMode, isNull);
  });

  test('a user selection wins a read race', () async {
    final read = Completer<AppearanceMode>();
    final store = _ControlledStore(onRead: () => read.future);
    final controller = AppearanceController(store: store);
    addTearDown(controller.dispose);

    final initialization = controller.initialize();
    final save = controller.setMode(AppearanceMode.dark);
    await _flushEvents();
    store.succeedWrite(0);
    await save;
    read.complete(AppearanceMode.light);
    await initialization;

    expect(controller.isInitialized, isTrue);
    expect(controller.selectedMode, AppearanceMode.dark);
    expect(controller.lastPersistedMode, AppearanceMode.dark);
    expect(store.value, AppearanceMode.dark);
  });

  test(
    'serializes A then B and exposes the partial-failure state table',
    () async {
      final store = _ControlledStore();
      final controller = AppearanceController(store: store);
      addTearDown(controller.dispose);
      await controller.initialize();

      final saveA = controller.setMode(AppearanceMode.light);
      await _flushEvents();
      expect(store.writes, <AppearanceMode>[AppearanceMode.light]);
      expect(controller.selectedMode, AppearanceMode.light);
      expect(controller.pendingSaveGeneration, 1);

      final saveB = controller.setMode(AppearanceMode.dark);
      await _flushEvents();
      expect(store.writes, <AppearanceMode>[AppearanceMode.light]);
      expect(controller.selectedMode, AppearanceMode.dark);
      expect(controller.lastPersistedMode, AppearanceMode.system);
      expect(controller.pendingSaveGeneration, 2);
      expect(controller.saveError, isNull);
      expect(controller.retryMode, AppearanceMode.dark);

      store.succeedWrite(0);
      await saveA;
      await _flushEvents();
      expect(store.writes, <AppearanceMode>[
        AppearanceMode.light,
        AppearanceMode.dark,
      ]);
      expect(store.value, AppearanceMode.light);
      expect(controller.selectedMode, AppearanceMode.dark);
      expect(controller.lastPersistedMode, AppearanceMode.light);
      expect(controller.pendingSaveGeneration, 2);
      expect(controller.saveErrorGeneration, isNull);
      expect(controller.retryMode, AppearanceMode.dark);

      final error = StateError('B failed');
      store.failWrite(1, error);
      await saveB;
      expect(store.value, AppearanceMode.light);
      expect(controller.selectedMode, AppearanceMode.dark);
      expect(controller.lastPersistedMode, AppearanceMode.light);
      expect(controller.isSavePending, isFalse);
      expect(controller.saveError, same(error));
      expect(controller.saveErrorGeneration, 2);
      expect(controller.retryMode, AppearanceMode.dark);

      final retry = controller.retry();
      await _flushEvents();
      expect(controller.pendingSaveGeneration, 3);
      expect(controller.saveError, isNull);
      expect(controller.saveErrorGeneration, isNull);
      expect(controller.retryMode, AppearanceMode.dark);
      expect(store.writes.last, AppearanceMode.dark);

      store.succeedWrite(2);
      await retry;
      expect(store.value, AppearanceMode.dark);
      expect(controller.selectedMode, AppearanceMode.dark);
      expect(controller.lastPersistedMode, AppearanceMode.dark);
      expect(controller.isSavePending, isFalse);
      expect(controller.saveError, isNull);
      expect(controller.retryMode, isNull);
    },
  );

  test('an older failure cannot replace newer pending state', () async {
    final store = _ControlledStore();
    final controller = AppearanceController(store: store);
    addTearDown(controller.dispose);
    await controller.initialize();

    final older = controller.setMode(AppearanceMode.light);
    await _flushEvents();
    final newer = controller.setMode(AppearanceMode.dark);
    final oldError = StateError('old failure');
    store.failWrite(0, oldError);
    await older;
    await _flushEvents();

    expect(controller.selectedMode, AppearanceMode.dark);
    expect(controller.pendingSaveGeneration, 2);
    expect(controller.saveError, isNull);
    expect(controller.retryMode, AppearanceMode.dark);
    expect(store.writes.last, AppearanceMode.dark);

    store.succeedWrite(1);
    await newer;
    expect(controller.lastPersistedMode, AppearanceMode.dark);
    expect(controller.saveError, isNull);
  });

  test('duplicate pending selection does not enqueue another write', () async {
    final store = _ControlledStore();
    final controller = AppearanceController(store: store);
    addTearDown(controller.dispose);
    await controller.initialize();

    final first = controller.setMode(AppearanceMode.light);
    await _flushEvents();
    final duplicate = controller.setMode(AppearanceMode.light);
    await _flushEvents();

    expect(store.writes, <AppearanceMode>[AppearanceMode.light]);
    store.succeedWrite(0);
    await Future.wait(<Future<void>>[first, duplicate]);
  });

  test('disposal makes calls and in-flight completions harmless', () async {
    final read = Completer<AppearanceMode>();
    final store = _ControlledStore(onRead: () => read.future);
    final controller = AppearanceController(store: store);
    var notifications = 0;
    controller.addListener(() => notifications++);

    final initialization = controller.initialize();
    controller.dispose();
    read.complete(AppearanceMode.dark);
    await initialization;
    await controller.initialize();
    await controller.setMode(AppearanceMode.light);
    await controller.retry();

    expect(notifications, 0);
    expect(store.writes, isEmpty);
  });

  test('initialization after disposal does not read storage', () async {
    final store = _ImmediateStore(AppearanceMode.dark);
    final controller = AppearanceController(store: store);

    controller.dispose();
    await controller.initialize();

    expect(store.readCount, 0);
    expect(controller.isInitialized, isFalse);
    expect(controller.selectedMode, AppearanceMode.system);
  });

  test(
    'an in-flight write can finish after disposal without notifying',
    () async {
      final store = _ControlledStore();
      final controller = AppearanceController(store: store);
      await controller.initialize();
      var notifications = 0;
      controller.addListener(() => notifications++);

      final save = controller.setMode(AppearanceMode.dark);
      await _flushEvents();
      expect(notifications, 1);
      controller.dispose();
      store.succeedWrite(0);

      await save;
      expect(notifications, 1);
      expect(store.value, AppearanceMode.dark);
    },
  );
}

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _ImmediateStore implements AppearanceStore {
  _ImmediateStore(this.value, {this.readError});

  AppearanceMode value;
  final Object? readError;
  int readCount = 0;

  @override
  Future<AppearanceMode> read() async {
    readCount++;
    if (readError case final error?) {
      throw error;
    }
    return value;
  }

  @override
  Future<void> write(AppearanceMode mode) async {
    value = mode;
  }
}

final class _ControlledStore implements AppearanceStore {
  _ControlledStore({this.onRead});

  final Future<AppearanceMode> Function()? onRead;
  AppearanceMode value = AppearanceMode.system;
  final List<AppearanceMode> writes = <AppearanceMode>[];
  final List<Completer<void>> _writeCompletions = <Completer<void>>[];

  @override
  Future<AppearanceMode> read() {
    return onRead?.call() ?? Future<AppearanceMode>.value(value);
  }

  @override
  Future<void> write(AppearanceMode mode) {
    writes.add(mode);
    final completion = Completer<void>();
    _writeCompletions.add(completion);
    return completion.future.then((_) => value = mode);
  }

  void succeedWrite(int index) => _writeCompletions[index].complete();

  void failWrite(int index, Object error) =>
      _writeCompletions[index].completeError(error, StackTrace.current);
}
