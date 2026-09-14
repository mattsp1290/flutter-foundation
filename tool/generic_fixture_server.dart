import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _maxBodyBytes = 2 * 1024 * 1024;

Future<void> main(List<String> arguments) async {
  final readyFile = _option(arguments, '--ready-file');
  if (readyFile == null) {
    stderr.writeln('usage: generic_fixture_server.dart --ready-file <path>');
    exitCode = 64;
    return;
  }
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final temporary = File('$readyFile.tmp');
  await temporary.writeAsString('${server.address.address}:${server.port}');
  await temporary.rename(readyFile);
  final turns = <String, int>{};
  await for (final request in server) {
    unawaited(_handle(request, turns));
  }
}

String? _option(List<String> arguments, String name) {
  final index = arguments.indexOf(name);
  return index >= 0 && index + 1 < arguments.length
      ? arguments[index + 1]
      : null;
}

Future<void> _handle(HttpRequest request, Map<String, int> turns) async {
  final origin = request.headers.value('origin');
  final validOrigin =
      origin != null &&
      (origin.startsWith('http://127.0.0.1:') ||
          origin.startsWith('http://localhost:'));
  if (validOrigin) {
    request.response.headers
      ..set(HttpHeaders.accessControlAllowOriginHeader, origin)
      ..set(HttpHeaders.varyHeader, 'origin')
      ..set(HttpHeaders.accessControlAllowMethodsHeader, 'POST, OPTIONS')
      ..set(
        HttpHeaders.accessControlAllowHeadersHeader,
        'content-type, accept',
      );
  }
  if (request.method == 'OPTIONS' && request.uri.path == '/generic/run') {
    request.response.statusCode = validOrigin
        ? HttpStatus.noContent
        : HttpStatus.forbidden;
    await request.response.close();
    return;
  }
  if (request.method != 'POST' || request.uri.path != '/generic/run') {
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
    return;
  }
  try {
    final bytes = <int>[];
    await for (final chunk in request) {
      bytes.addAll(chunk);
      if (bytes.length > _maxBodyBytes) throw const HttpException('too large');
    }
    final body = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final threadId = body['threadId'];
    final runId = body['runId'];
    final messages = body['messages'];
    if (threadId is! String || runId is! String || messages is! List) {
      throw const FormatException('invalid generic input');
    }
    final turn = (turns[threadId] ?? 0) + 1;
    if (threadId != 'browser-thread' || !_validHistory(turn, messages)) {
      request.response.statusCode = HttpStatus.unprocessableEntity;
      request.response.write('invalid caller history');
      await request.response.close();
      return;
    }
    turns[threadId] = turn;
    request.response.headers.contentType = ContentType('text', 'event-stream');
    request.response.write(_frames(threadId, runId, turn));
  } on HttpException {
    request.response.statusCode = HttpStatus.requestEntityTooLarge;
  } on Object {
    request.response.statusCode = HttpStatus.badRequest;
  }
  await request.response.close();
}

bool _validHistory(int turn, List<dynamic> actual) {
  if (actual.isEmpty ||
      actual.first is! Map ||
      (actual.first as Map)['id'] != 'user-1' ||
      (actual.first as Map)['role'] != 'user' ||
      (actual.first as Map)['content'] is! String) {
    return false;
  }
  if (turn == 1) return actual.length == 1;
  final expectedTail = <Object?>[
    {
      'id': 'assistant-1',
      'role': 'assistant',
      'content': 'Response 1',
      'toolCalls': [
        {
          'id': 'tool-1',
          'type': 'function',
          'function': {'name': 'lookup', 'arguments': '{"turn":1}'},
        },
      ],
    },
    {
      'id': 'tool-result-1',
      'role': 'tool',
      'content': 'result 1',
      'toolCallId': 'tool-1',
    },
    {'id': 'user-2', 'role': 'user', 'content': 'second turn'},
  ];
  return actual.length == 4 &&
      jsonEncode(actual.skip(1).toList()) == jsonEncode(expectedTail);
}

String _frames(String threadId, String runId, int turn) {
  final assistant = 'assistant-$turn';
  final tool = 'tool-$turn';
  final result = 'tool-result-$turn';
  final events = [
    {
      'type': 'RUN_STARTED',
      'timestamp': 1700000000000,
      'threadId': threadId,
      'runId': runId,
    },
    if (turn == 1)
      {
        'type': 'MESSAGES_SNAPSHOT',
        'timestamp': 1700000000000,
        'messages': [
          {'id': 'user-1', 'role': 'user', 'content': 'first turn'},
        ],
      },
    {
      'type': 'TEXT_MESSAGE_START',
      'timestamp': 1700000000000,
      'messageId': assistant,
      'role': 'assistant',
    },
    {
      'type': 'TEXT_MESSAGE_CONTENT',
      'timestamp': 1700000000000,
      'messageId': assistant,
      'delta': 'Response $turn',
    },
    {
      'type': 'TOOL_CALL_START',
      'timestamp': 1700000000000,
      'toolCallId': tool,
      'toolCallName': 'lookup',
    },
    {
      'type': 'TOOL_CALL_ARGS',
      'timestamp': 1700000000000,
      'toolCallId': tool,
      'delta': '{"turn":$turn}',
    },
    {'type': 'TOOL_CALL_END', 'timestamp': 1700000000000, 'toolCallId': tool},
    {
      'type': 'TEXT_MESSAGE_END',
      'timestamp': 1700000000000,
      'messageId': assistant,
    },
    {
      'type': 'TOOL_CALL_RESULT',
      'timestamp': 1700000000000,
      'messageId': result,
      'toolCallId': tool,
      'content': 'result $turn',
      'role': 'tool',
    },
    {
      'type': 'RUN_FINISHED',
      'timestamp': 1700000000000,
      'threadId': threadId,
      'runId': runId,
      'outcome': {'type': 'success'},
    },
  ];
  return events.map((event) => 'data: ${jsonEncode(event)}\n\n').join();
}
