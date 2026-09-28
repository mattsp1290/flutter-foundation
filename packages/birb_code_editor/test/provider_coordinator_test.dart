import 'dart:async';

import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:birb_code_editor/src/provider_coordinator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Provider implements BirbEditorProvider {
  final requests = <BirbEditorRequest>[];
  final completions = <Completer<List<BirbEditorCompletion>>>[];
  final hovers = <Completer<BirbEditorHover?>>[];
  final diagnostics = <Completer<List<BirbEditorDiagnostic>>>[];

  @override
  Future<List<BirbEditorCompletion>> complete(BirbEditorRequest request) {
    requests.add(request);
    final result = Completer<List<BirbEditorCompletion>>();
    completions.add(result);
    return result.future;
  }

  @override
  Future<BirbEditorHover?> hover(BirbEditorRequest request) {
    final result = Completer<BirbEditorHover?>();
    hovers.add(result);
    return result.future;
  }

  @override
  Future<List<BirbEditorDiagnostic>> diagnose(BirbEditorRequest request) {
    final result = Completer<List<BirbEditorDiagnostic>>();
    diagnostics.add(result);
    return result.future;
  }
}

void main() {
  BirbEditorCompletion completion([String text = 'world']) =>
      BirbEditorCompletion(
        label: text,
        edit: BirbEditorEdit(
          range: const TextRange(start: 0, end: 5),
          text: text,
        ),
      );

  (BirbEditorController, _Provider, EditorProviderCoordinator) create() {
    final controller = BirbEditorController(documentId: 'doc', source: 'hello');
    final provider = _Provider();
    final coordinator = EditorProviderCoordinator(
      controller: controller,
      provider: provider,
    );
    addTearDown(() {
      coordinator.dispose();
      controller.dispose();
    });
    return (controller, provider, coordinator);
  }

  testWidgets(
    'only latest pending request starts and timeout releases a stalled request',
    (tester) async {
      final (controller, provider, coordinator) = create();
      coordinator.requestCompletion();
      controller.setSelection(const TextSelection.collapsed(offset: 1));
      coordinator.requestCompletion();
      controller.setSelection(const TextSelection.collapsed(offset: 2));
      coordinator.requestCompletion();
      expect(provider.requests, hasLength(1));
      await tester.pump(const Duration(seconds: 5));
      expect(provider.requests, hasLength(2));
      expect(provider.requests.last.position, 2);
      expect(coordinator.completionStatus, BirbEditorProviderStatus.loading);
      final latest = completion();
      provider.completions.last.complete([latest]);
      await tester.pump();
      expect(coordinator.completions, [latest]);
      provider.completions.first.complete([completion('late')]);
      await tester.pump();
      expect(coordinator.completions, [latest]);
      expect(
        coordinator.acceptCompletion(latest),
        BirbEditorEditResult.applied,
      );
      expect(controller.snapshot.source, 'world');
      expect(coordinator.completions, isEmpty);
      controller.undo();
      expect(controller.snapshot.source, 'hello');
    },
  );

  testWidgets(
    'selection readonly reload and provider swap invalidate acceptance',
    (tester) async {
      final (controller, provider, coordinator) = create();
      for (final invalidate in <void Function()>[
        () {
          controller.setSelection(const TextSelection.collapsed(offset: 1));
        },
        () {
          controller.setReadOnly(true);
          controller.setReadOnly(false);
        },
        () {
          controller.replaceDocument(documentId: 'doc', source: 'hello');
        },
        () {
          coordinator.setProvider(_Provider());
        },
      ]) {
        coordinator.setProvider(provider);
        coordinator.requestCompletion();
        final item = completion();
        provider.completions.last.complete([item]);
        await tester.pump();
        expect(coordinator.completions, [item]);
        invalidate();
        expect(coordinator.acceptCompletion(item), BirbEditorEditResult.stale);
        expect(controller.snapshot.source, 'hello');
      }
    },
  );

  testWidgets(
    'diagnostics survive selection but clear immediately on source change',
    (tester) async {
      final (controller, provider, coordinator) = create();
      coordinator.requestDiagnostics();
      const item = BirbEditorDiagnostic(
        range: TextRange(start: 0, end: 5),
        severity: BirbEditorDiagnosticSeverity.warning,
        message: 'Example',
      );
      provider.diagnostics.single.complete([item]);
      await tester.pump();
      controller.selectAll();
      expect(coordinator.diagnostics, [item]);
      controller.replaceDocument(documentId: 'doc', source: 'hello');
      expect(coordinator.diagnostics, isEmpty);
      coordinator.requestDiagnostics();
      controller.replaceDocument(documentId: 'next', source: '');
      provider.diagnostics.last.complete([item]);
      await tester.pump();
      expect(coordinator.diagnostics, isEmpty);
    },
  );

  testWidgets(
    'malformed and excessive response payloads fail without mutation',
    (tester) async {
      final (controller, provider, coordinator) = create();
      for (final items in [
        List.generate(101, (_) => completion()),
        [completion('中' * 6000)],
        [
          BirbEditorCompletion(
            label: 'bad',
            edit: const BirbEditorEdit(
              range: TextRange(start: 0, end: 99),
              text: 'bad',
            ),
          ),
        ],
        [
          BirbEditorCompletion(
            label: 'overlap',
            edit: const BirbEditorEdit(
              range: TextRange(start: 0, end: 3),
              text: 'x',
            ),
            additionalEdits: const [
              BirbEditorEdit(range: TextRange(start: 2, end: 4), text: 'y'),
            ],
          ),
        ],
        List.generate(100, (_) => completion('x' * 3000)),
      ]) {
        coordinator.requestCompletion();
        provider.completions.last.complete(items);
        await tester.pump();
        expect(
          coordinator.completionStatus,
          BirbEditorProviderStatus.invalidResponse,
        );
        expect(coordinator.completions, isEmpty);
        expect(controller.snapshot.source, 'hello');
      }
      coordinator.requestHover();
      provider.hovers.single.complete(BirbEditorHover(text: 'x' * 16385));
      await tester.pump();
      expect(coordinator.hoverStatus, BirbEditorProviderStatus.invalidResponse);
      coordinator.requestDiagnostics();
      provider.diagnostics.single.complete(const [
        BirbEditorDiagnostic(
          range: TextRange(start: -1, end: 1),
          severity: BirbEditorDiagnosticSeverity.error,
          message: 'bad',
        ),
      ]);
      await tester.pump();
      expect(
        coordinator.diagnosticStatus,
        BirbEditorProviderStatus.invalidResponse,
      );
    },
  );

  testWidgets(
    'provider failures and timeouts are recoverable; detach ignores late completion',
    (tester) async {
      final (_, provider, coordinator) = create();
      coordinator.requestCompletion();
      provider.completions.single.completeError(
        StateError('source must not escape'),
      );
      await tester.pump();
      expect(coordinator.completionStatus, BirbEditorProviderStatus.failed);
      coordinator.requestCompletion();
      await tester.pump(const Duration(seconds: 5));
      expect(coordinator.completionStatus, BirbEditorProviderStatus.timedOut);
      coordinator.requestCompletion();
      var notifications = 0;
      coordinator.addListener(() => notifications++);
      coordinator.dispose();
      provider.completions.last.complete([completion()]);
      await tester.pump();
      expect(notifications, 0);
      expect(coordinator.completions, isEmpty);
    },
  );
}
