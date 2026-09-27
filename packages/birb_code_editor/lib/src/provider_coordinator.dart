import 'dart:async';

import 'package:flutter/foundation.dart';

import 'controller.dart';
import 'language_provider.dart';
import 'provider_response_validation.dart';
import 'snapshot.dart';
import 'source_coordinates.dart';

/// One attached view's provider work. Disposing this never disposes the host's
/// provider or controller. Each channel has one active and one latest pending
/// logical request; timed-out transport futures may finish but cannot publish.
class EditorProviderCoordinator extends ChangeNotifier {
  EditorProviderCoordinator({
    required this.controller,
    this._provider,
    this.timeout = BirbEditorProviderLimits.timeout,
    this.onError,
  }) {
    if (timeout <= Duration.zero) throw ArgumentError.value(timeout, 'timeout');
    _snapshot = controller.snapshot;
    _completion = _RequestChannel<List<BirbEditorCompletion>>(
      timeout,
      _changed,
      onError,
    );
    _hover = _RequestChannel<BirbEditorHover?>(timeout, _changed, onError);
    _diagnostics = _RequestChannel<List<BirbEditorDiagnostic>>(
      timeout,
      _changed,
      onError,
    );
    controller.addListener(_controllerChanged);
  }

  final BirbEditorController controller;
  final Duration timeout;
  final ValueChanged<BirbEditorProviderStatus>? onError;
  BirbEditorProvider? _provider;
  late BirbEditorSnapshot _snapshot;
  late final _RequestChannel<List<BirbEditorCompletion>> _completion;
  late final _RequestChannel<BirbEditorHover?> _hover;
  late final _RequestChannel<List<BirbEditorDiagnostic>> _diagnostics;
  bool _disposed = false;
  int _requestId = 0;

  List<BirbEditorCompletion> get completions => _completion.value ?? const [];
  BirbEditorHover? get hover => _hover.value;
  int? get hoverPosition => _hover.acceptedRequest?.position;
  List<BirbEditorDiagnostic> get diagnostics => _diagnostics.value ?? const [];
  BirbEditorProviderStatus get completionStatus => _provider == null
      ? BirbEditorProviderStatus.unavailable
      : _completion.status;
  BirbEditorProviderStatus get hoverStatus =>
      _provider == null ? BirbEditorProviderStatus.unavailable : _hover.status;
  BirbEditorProviderStatus get diagnosticStatus => _provider == null
      ? BirbEditorProviderStatus.unavailable
      : _diagnostics.status;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _controllerChanged() {
    final next = controller.snapshot;
    final sourceChanged =
        next.documentId != _snapshot.documentId ||
        next.generation != _snapshot.generation;
    final selectionChanged = next.selection != _snapshot.selection;
    final readonlyChanged = next.readOnly != _snapshot.readOnly;
    _snapshot = next;
    if (sourceChanged || readonlyChanged) {
      _invalidateAll();
    } else if (selectionChanged) {
      _completion.invalidate();
      _hover.invalidate();
      _changed();
    }
  }

  void _invalidateAll() {
    _completion.invalidate();
    _hover.invalidate();
    _diagnostics.invalidate();
    _changed();
  }

  void setProvider(BirbEditorProvider? provider) {
    if (_disposed || identical(provider, _provider)) return;
    _provider = provider;
    _invalidateAll();
  }

  BirbEditorRequest? _request(int? position) {
    if (_disposed || _provider == null) return null;
    final snapshot = controller.snapshot;
    final offset = position ?? snapshot.selection.extentOffset;
    if (!BirbSourceCoordinates(snapshot.source).isBoundary(offset)) return null;
    return BirbEditorRequest(
      documentId: snapshot.documentId,
      generation: snapshot.generation,
      source: snapshot.source,
      position: offset,
      requestId: ++_requestId,
    );
  }

  void requestCompletion() {
    final request = _request(null);
    final provider = _provider;
    if (request == null || provider == null) return;
    _completion.enqueue(
      request,
      () => provider.complete(request),
      validCompletions,
      (items) => List.unmodifiable(items),
    );
  }

  void requestHover([int? position]) {
    final request = _request(position);
    final provider = _provider;
    if (request == null || provider == null) return;
    _hover.enqueue(
      request,
      () => provider.hover(request),
      validHover,
      (value) => value,
    );
  }

  void requestDiagnostics() {
    final request = _request(null);
    final provider = _provider;
    if (request == null || provider == null) return;
    _diagnostics.enqueue(
      request,
      () => provider.diagnose(request),
      validDiagnostics,
      (items) => List.unmodifiable(items),
    );
  }

  BirbEditorEditResult acceptCompletion(BirbEditorCompletion item) {
    if (_disposed) return BirbEditorEditResult.disposed;
    final request = _completion.acceptedRequest;
    if (request == null ||
        !completions.any((candidate) => identical(item, candidate))) {
      return BirbEditorEditResult.stale;
    }
    return controller.applyEdits(
      expectedDocumentId: request.documentId,
      expectedGeneration: request.generation,
      edits: [item.edit, ...item.additionalEdits],
      selectionAfter: item.selectionAfter,
    );
  }

  void dismiss() {
    if (_disposed) return;
    _completion.invalidate();
    _hover.invalidate();
    _changed();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    controller.removeListener(_controllerChanged);
    _completion.dispose();
    _hover.dispose();
    _diagnostics.dispose();
    super.dispose();
  }
}

class _ProviderWork<T> {
  _ProviderWork(this.token, this.request, this.run, this.validate, this.freeze);
  final int token;
  final BirbEditorRequest request;
  final Future<T> Function() run;
  final bool Function(BirbEditorRequest, T) validate;
  final T Function(T) freeze;
}

class _RequestChannel<T> {
  _RequestChannel(this.timeout, this.changed, this.onError);
  final Duration timeout;
  final VoidCallback changed;
  final ValueChanged<BirbEditorProviderStatus>? onError;
  T? value;
  BirbEditorRequest? acceptedRequest;
  BirbEditorProviderStatus status = BirbEditorProviderStatus.idle;
  int _token = 0;
  bool _disposed = false;
  _ProviderWork<T>? _active;
  _ProviderWork<T>? _pending;
  Timer? _timer;

  void invalidate() {
    _token++;
    _pending = null;
    value = null;
    acceptedRequest = null;
    status = BirbEditorProviderStatus.idle;
  }

  void enqueue(
    BirbEditorRequest request,
    Future<T> Function() run,
    bool Function(BirbEditorRequest, T) validate,
    T Function(T) freeze,
  ) {
    if (_disposed) return;
    invalidate();
    status = BirbEditorProviderStatus.loading;
    final work = _ProviderWork(_token, request, run, validate, freeze);
    if (_active == null) {
      _start(work);
    } else {
      _pending = work;
    }
    changed();
  }

  void _start(_ProviderWork<T> work) {
    _active = work;
    _timer = Timer(
      timeout,
      () => _finish(work, BirbEditorProviderStatus.timedOut),
    );
    Future<T>.sync(work.run).then(
      (result) {
        if (_disposed || !identical(_active, work)) return;
        if (work.token != _token) {
          _finish(work, BirbEditorProviderStatus.idle);
          return;
        }
        try {
          if (!work.validate(work.request, result)) {
            _finish(work, BirbEditorProviderStatus.invalidResponse);
            return;
          }
          value = work.freeze(result);
          acceptedRequest = work.request;
          _finish(work, BirbEditorProviderStatus.ready);
        } catch (_) {
          _finish(work, BirbEditorProviderStatus.invalidResponse);
        }
      },
      onError: (Object _, StackTrace _) {
        _finish(work, BirbEditorProviderStatus.failed);
      },
    );
  }

  void _finish(_ProviderWork<T> work, BirbEditorProviderStatus result) {
    if (_disposed || !identical(_active, work)) return;
    _timer?.cancel();
    _timer = null;
    _active = null;
    final current = work.token == _token;
    if (current) status = result;
    final pending = _pending;
    _pending = null;
    if (pending != null) _start(pending);
    changed();
    if (!_disposed &&
        current &&
        result != BirbEditorProviderStatus.ready &&
        result != BirbEditorProviderStatus.idle) {
      try {
        onError?.call(result);
      } catch (_) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: StateError(
              'An editor provider status subscriber failed',
            ),
            library: 'birb_code_editor',
          ),
        );
      }
    }
  }

  void dispose() {
    _disposed = true;
    invalidate();
    _timer?.cancel();
    _active = null;
  }
}
