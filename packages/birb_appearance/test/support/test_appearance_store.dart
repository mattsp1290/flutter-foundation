import 'dart:async';

import 'package:birb_appearance/birb_appearance.dart';

final class TestAppearanceStore implements AppearanceStore {
  TestAppearanceStore({
    this.value = AppearanceMode.system,
    this.readError,
    this.controlWrites = false,
    this.onRead,
    this.isPersisted = true,
  });

  AppearanceMode value;
  final Object? readError;
  final bool controlWrites;
  final Future<AppearanceReadResult> Function()? onRead;
  final bool isPersisted;
  int readCount = 0;
  final List<AppearanceMode> writes = <AppearanceMode>[];
  final List<Completer<void>> _writeCompletions = <Completer<void>>[];
  Completer<void> _nextWriteStarted = Completer<void>();

  @override
  Future<AppearanceReadResult> read() async {
    readCount++;
    if (onRead case final read?) return read();
    if (readError case final error?) throw error;
    return (mode: value, isPersisted: isPersisted);
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
