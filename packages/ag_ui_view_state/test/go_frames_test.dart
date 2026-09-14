import 'dart:io';

import 'package:ag_ui/ag_ui.dart';
import 'package:ag_ui_view_state/ag_ui_view_state.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  test('decodes generic protocol fixture across every byte boundary', () async {
    final bytes = await File('../../testdata/ag_ui/generic.sse').readAsBytes();
    final client = http.Client();
    final parser = SseClient(
      httpClient: client,
      maxDataCodeUnits: 1048576,
      maxLineCodeUnits: 1048583,
    );
    final events = await EventStreamAdapter(maxDataCodeUnits: 1048576)
        .fromSseStream(
          parser.parseStream(
            Stream.fromIterable([
              for (final byte in bytes) [byte],
            ]),
          ),
          skipInvalidEvents: false,
        )
        .toList();
    final reducer = EventViewReducer();
    var state = AgentViewState();
    for (final event in events) {
      state = reducer.reduce(state, event);
    }
    await parser.close();
    client.close();

    expect(state.messages.last.text, 'baseline plus plus');
    expect(state.tools.map((tool) => tool.id), ['tool-1', 'tool-2']);
    expect(state.runPhase, RunPhase.completed);
  });

  test('privacy protocol fixture contains no provider state canary', () async {
    final fixture = await File('../../testdata/ag_ui/privacy.sse')
        .readAsString();
    expect(fixture, isNot(contains('PRIVATE_PROVIDER_STATE_CANARY_7f31')));
  });
}
