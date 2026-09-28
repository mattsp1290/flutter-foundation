import 'package:flutter/material.dart';

import 'language_provider.dart';
import 'provider_coordinator.dart';
import 'source_coordinates.dart';

class EditorDiagnosticsPanel extends StatelessWidget {
  const EditorDiagnosticsPanel({
    super.key,
    required this.providers,
    required this.navigate,
    required this.close,
  });
  final EditorProviderCoordinator providers;
  final ValueChanged<BirbEditorDiagnostic> navigate;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    final diagnostics = providers.diagnostics;
    final coordinates = BirbSourceCoordinates(
      providers.controller.snapshot.source,
    );
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Text('Diagnostics')),
            IconButton(
              tooltip: 'Refresh diagnostics',
              onPressed: providers.requestDiagnostics,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Close diagnostics',
              onPressed: close,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        Expanded(
          child: diagnostics.isEmpty
              ? const Center(child: Text('No current diagnostics'))
              : ListView.builder(
                  itemCount: diagnostics.length,
                  itemBuilder: (context, index) {
                    final item = diagnostics[index];
                    final position = coordinates.positionAt(item.range.start);
                    final (severity, icon) = switch (item.severity) {
                      BirbEditorDiagnosticSeverity.error => (
                        'Error',
                        Icons.error_outline,
                      ),
                      BirbEditorDiagnosticSeverity.warning => (
                        'Warning',
                        Icons.warning_amber,
                      ),
                      BirbEditorDiagnosticSeverity.information => (
                        'Information',
                        Icons.info_outline,
                      ),
                      BirbEditorDiagnosticSeverity.hint => (
                        'Hint',
                        Icons.lightbulb_outline,
                      ),
                    };
                    return ListTile(
                      minTileHeight: 48,
                      leading: Icon(icon),
                      title: Text(
                        '$severity on line ${position.line + 1}: ${item.message}',
                      ),
                      subtitle: item.code == null ? null : Text(item.code!),
                      onTap: () {
                        if (providers.diagnostics.any(
                          (current) => identical(current, item),
                        )) {
                          navigate(item);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class EditorProviderStatus extends StatelessWidget {
  const EditorProviderStatus({
    super.key,
    required this.providers,
    required this.showDiagnostics,
  });
  final EditorProviderCoordinator providers;
  final VoidCallback showDiagnostics;

  @override
  Widget build(BuildContext context) {
    final statuses = [
      providers.completionStatus,
      providers.hoverStatus,
      providers.diagnosticStatus,
    ];
    final failed = statuses.any(
      (status) => [
        BirbEditorProviderStatus.failed,
        BirbEditorProviderStatus.timedOut,
        BirbEditorProviderStatus.invalidResponse,
      ].contains(status),
    );
    final label = statuses.contains(BirbEditorProviderStatus.unavailable)
        ? 'Language tools unavailable'
        : failed
        ? 'Language tools could not complete the request'
        : statuses.contains(BirbEditorProviderStatus.loading)
        ? 'Language tools loading'
        : 'Language tools ready';
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Semantics(liveRegion: true, child: Text(label)),
        if (failed)
          TextButton(
            onPressed: () {
              if (statuses[0] == BirbEditorProviderStatus.failed ||
                  statuses[0] == BirbEditorProviderStatus.timedOut ||
                  statuses[0] == BirbEditorProviderStatus.invalidResponse) {
                providers.requestCompletion();
              }
              if (statuses[1] == BirbEditorProviderStatus.failed ||
                  statuses[1] == BirbEditorProviderStatus.timedOut ||
                  statuses[1] == BirbEditorProviderStatus.invalidResponse) {
                providers.requestHover();
              }
              if (statuses[2] == BirbEditorProviderStatus.failed ||
                  statuses[2] == BirbEditorProviderStatus.timedOut ||
                  statuses[2] == BirbEditorProviderStatus.invalidResponse) {
                providers.requestDiagnostics();
              }
            },
            child: const Text('Retry language tools'),
          ),
        TextButton(
          onPressed: showDiagnostics,
          child: Text('${providers.diagnostics.length} diagnostics'),
        ),
      ],
    );
  }
}
