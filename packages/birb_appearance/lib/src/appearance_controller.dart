import 'dart:async';

import 'package:flutter/material.dart';

import 'appearance_mode.dart';
import 'appearance_store.dart';

/// Coordinates immediate appearance selection with serialized persistence.
final class AppearanceController extends ChangeNotifier {
  factory AppearanceController({
    required AppearanceStore store,
    Duration initializationTimeout = const Duration(seconds: 2),
  }) {
    return AppearanceController._(store, initializationTimeout);
  }

  AppearanceController._(this._store, this._initializationTimeout);

  final AppearanceStore _store;
  final Duration _initializationTimeout;

  AppearanceMode _selectedMode = AppearanceMode.system;
  AppearanceMode? _lastPersistedMode;
  bool _isInitialized = false;
  Object? _readError;
  StackTrace? _readErrorStackTrace;
  Object? _saveError;
  StackTrace? _saveErrorStackTrace;
  AppearanceMode? _retryMode;
  int? _pendingSaveGeneration;
  int? _saveErrorGeneration;
  int _operationGeneration = 0;
  int _nextSaveGeneration = 0;
  Future<void>? _initialization;
  Future<void> _writeTail = Future<void>.value();
  bool _isDisposed = false;

  AppearanceMode get selectedMode => _selectedMode;
  AppearanceMode? get lastPersistedMode => _lastPersistedMode;
  ThemeMode get themeMode => _selectedMode.themeMode;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => !_isInitialized;
  Object? get readError => _readError;
  StackTrace? get readErrorStackTrace => _readErrorStackTrace;
  bool get isSavePending => _pendingSaveGeneration != null;
  int? get pendingSaveGeneration => _pendingSaveGeneration;
  Object? get saveError => _saveError;
  StackTrace? get saveErrorStackTrace => _saveErrorStackTrace;
  int? get saveErrorGeneration => _saveErrorGeneration;
  AppearanceMode? get retryMode => _retryMode;

  /// Loads the persisted mode once without delaying construction.
  Future<void> initialize() {
    if (_isDisposed) {
      return Future<void>.value();
    }
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    final readGeneration = _operationGeneration;
    try {
      final storedMode = await _store.read().timeout(
        _initializationTimeout,
        onTimeout: () => throw TimeoutException(
          'Appearance initialization exceeded $_initializationTimeout.',
          _initializationTimeout,
        ),
      );
      if (_isDisposed) {
        return;
      }
      if (_operationGeneration == readGeneration) {
        _selectedMode = storedMode;
        _lastPersistedMode = storedMode;
      }
    } catch (error, stackTrace) {
      if (_isDisposed) {
        return;
      }
      _readError = error;
      _readErrorStackTrace = stackTrace;
      if (error is TimeoutException) {
        _operationGeneration++;
      }
    }
    if (_isDisposed) {
      return;
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// Selects [mode] immediately and queues its persistence operation.
  Future<void> setMode(AppearanceMode mode) {
    if (_isDisposed) {
      return Future<void>.value();
    }
    if (mode == _selectedMode && isSavePending) {
      return _writeTail;
    }
    if (mode == _selectedMode &&
        _lastPersistedMode == mode &&
        _saveError == null) {
      return Future<void>.value();
    }

    _operationGeneration++;
    _selectedMode = mode;
    return _enqueueSave(mode);
  }

  /// Retries the latest failed selection, if one exists.
  Future<void> retry() {
    if (_isDisposed || _retryMode == null || isSavePending) {
      return Future<void>.value();
    }
    return _enqueueSave(_retryMode!);
  }

  Future<void> _enqueueSave(AppearanceMode mode) {
    final generation = ++_nextSaveGeneration;
    _pendingSaveGeneration = generation;
    _saveError = null;
    _saveErrorStackTrace = null;
    _saveErrorGeneration = null;
    _retryMode = mode;
    notifyListeners();

    final completion = Completer<void>();
    _writeTail = _writeTail.then((_) async {
      try {
        await _store.write(mode);
        if (_isDisposed) {
          return;
        }
        _lastPersistedMode = mode;
        if (_pendingSaveGeneration == generation) {
          _pendingSaveGeneration = null;
          _retryMode = null;
        }
        notifyListeners();
      } catch (error, stackTrace) {
        if (_isDisposed) {
          return;
        }
        if (_pendingSaveGeneration == generation) {
          _pendingSaveGeneration = null;
          _saveError = error;
          _saveErrorStackTrace = stackTrace;
          _saveErrorGeneration = generation;
          _retryMode = mode;
          notifyListeners();
        }
      } finally {
        if (!completion.isCompleted) {
          completion.complete();
        }
      }
    });
    return completion.future;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
