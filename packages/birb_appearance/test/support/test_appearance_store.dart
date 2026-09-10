import 'dart:async';

import 'package:birb_appearance/birb_appearance.dart';

final class TestAppearanceStore implements AppearanceStore {
  TestAppearanceStore({
    this.value = AppearanceMode.system,
    this.readError,
    this.controlWrites = false,
  });

  AppearanceMode value;
  final Object? readError;
  final bool controlWrites;
  final List<AppearanceMode> writes = <AppearanceMode>[];
  final List<Completer<void>> _writeCompletions = <Completer<void>>[];
  Completer<void> _nextWriteStarted = Completer<void>();

  @override
  Future<AppearanceReadResult> read() async {
    if (readError case final error?) throw error;
    return (mode: value, isPersisted: true);
  }

  @override
  Future<void> write(AppearanceMode mode) {
    writes.add(mode);
    if (!controlWrites) {
      value = mode;
      return Future<void>.value();
    }
    final completion = Completer<void>();
    _writeCompletions.add(completion);
    _nextWriteStarted.complete();
    _nextWriteStarted = Completer<void>();
    return completion.future.then((_) => value = mode);
  }

  Future<void> waitForWrite(int index) async {
    while (_writeCompletions.length <= index) {
      await _nextWriteStarted.future;
    }
  }

  void succeedWrite(int index) => _writeCompletions[index].complete();

  void failWrite(int index, Object error) =>
      _writeCompletions[index].completeError(error, StackTrace.current);
}
