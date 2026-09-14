import 'dart:collection';

enum ConnectionPhase {
  idle,
  connecting,
  connected,
  reconnecting,
  disconnected,
  failed,
  disposed,
}

enum RunPhase {
  idle,
  submitting,
  running,
  interrupting,
  completed,
  failed,
  paused,
  interrupted,
  outcomeUnknown,
}

enum ViewMessageRole { user, assistant }

enum ToolActivityPhase {
  receivingArguments,
  awaitingResult,
  resultObserved,
  running,
  completed,
  failed,
  interrupted,
  unresolved,
}

enum ViewFailureKind {
  capacityExceeded,
  protocolViolation,
  incompatibleContract,
  unauthorized,
  forbidden,
  unavailable,
  conflict,
  transient,
  hostCallbackFailed,
  incomplete,
  outcomeUnavailable,
}

final class ViewFailure {
  const ViewFailure(this.kind, {this.retryable = false});

  final ViewFailureKind kind;
  final bool retryable;

  String get safeMessage => switch (kind) {
    ViewFailureKind.capacityExceeded => 'Response exceeds display limits',
    ViewFailureKind.protocolViolation => 'The response was not valid',
    ViewFailureKind.incompatibleContract =>
      'The server response is not supported',
    ViewFailureKind.unauthorized => 'Authentication is required',
    ViewFailureKind.forbidden => 'Access is forbidden',
    ViewFailureKind.unavailable => 'The session is unavailable',
    ViewFailureKind.conflict => 'The session is busy',
    ViewFailureKind.transient => 'The connection was interrupted',
    ViewFailureKind.hostCallbackFailed => 'The host callback failed',
    ViewFailureKind.incomplete => 'The response ended before completion',
    ViewFailureKind.outcomeUnavailable =>
      'The run outcome is no longer available',
  };
}

final class ViewLimits {
  ViewLimits({
    this.maxMessages = 100,
    this.maxTools = 200,
    this.maxDisplayBytes = 256 * 1024,
    this.maxMessageBytes = 64 * 1024,
    this.maxSseDataCodeUnits = 1048576,
    this.maxSseLineCodeUnits = 1048583,
    this.maxSubmissionBytes = 64 * 1024,
    this.maxEncodedInputBytes = 2 * 1024 * 1024,
    this.maxSourceReferences = 100,
    this.maxSourceIdBytes = 512,
    this.maxSourcePassageBytes = 64 * 1024,
    this.maxSourceLabelBytes = 1024,
    this.maxSourceRevisionLabelBytes = 1024,
  }) {
    if (maxMessages <= 0 ||
        maxTools <= 0 ||
        maxDisplayBytes <= 0 ||
        maxMessageBytes <= 0 ||
        maxSseDataCodeUnits <= 0 ||
        maxSseLineCodeUnits <= 0 ||
        maxSubmissionBytes <= 0 ||
        maxEncodedInputBytes <= 0 ||
        maxSourceReferences <= 0 ||
        maxSourceIdBytes <= 0 ||
        maxSourcePassageBytes <= 0 ||
        maxSourceLabelBytes <= 0 ||
        maxSourceRevisionLabelBytes <= 0) {
      throw ArgumentError('All view limits must be positive');
    }
  }

  final int maxMessages;
  final int maxTools;
  final int maxDisplayBytes;
  final int maxMessageBytes;
  final int maxSseDataCodeUnits;
  final int maxSseLineCodeUnits;
  final int maxSubmissionBytes;
  final int maxEncodedInputBytes;
  final int maxSourceReferences;
  final int maxSourceIdBytes;
  final int maxSourcePassageBytes;
  final int maxSourceLabelBytes;
  final int maxSourceRevisionLabelBytes;
}

enum SourceReferenceAvailability { current, stale, unavailable }

/// A bounded, display-only source reference. Its [id] is opaque and must be
/// reauthorized by the host each time a user asks to open it.
final class SourceReferenceView {
  SourceReferenceView({
    required this.id,
    required this.parentMessageId,
    required this.label,
    required this.passage,
    required this.startLine,
    int? endLine,
    this.highlightStartLine,
    this.highlightEndLine,
    this.revisionLabel,
    this.availability = SourceReferenceAvailability.current,
  }) : endLine = endLine ?? startLine + passage.split('\n').length - 1 {
    if (id.isEmpty ||
        parentMessageId.isEmpty ||
        label.isEmpty ||
        label.contains('\n') ||
        passage.isEmpty ||
        startLine <= 0 ||
        this.endLine < startLine ||
        this.endLine != startLine + passage.split('\n').length - 1 ||
        (highlightStartLine == null) != (highlightEndLine == null) ||
        (highlightStartLine != null &&
            (highlightStartLine! < startLine ||
                highlightEndLine! > this.endLine ||
                highlightStartLine! > highlightEndLine!))) {
      throw ArgumentError('Invalid source reference display range');
    }
  }

  final String id;
  final String parentMessageId;
  final String label;
  final String passage;
  final int startLine;
  final int endLine;
  final int? highlightStartLine;
  final int? highlightEndLine;
  final String? revisionLabel;
  final SourceReferenceAvailability availability;
}

final class MessageView {
  const MessageView({
    required this.id,
    required this.role,
    required this.text,
    this.isStreaming = false,
    this.liveUnavailable = false,
  });

  final String id;
  final ViewMessageRole role;
  final String text;
  final bool isStreaming;
  final bool liveUnavailable;

  MessageView copyWith({
    String? text,
    bool? isStreaming,
    bool? liveUnavailable,
  }) => MessageView(
    id: id,
    role: role,
    text: text ?? this.text,
    isStreaming: isStreaming ?? this.isStreaming,
    liveUnavailable: liveUnavailable ?? this.liveUnavailable,
  );
}

final class ToolActivityView {
  const ToolActivityView({
    required this.id,
    required this.name,
    required this.phase,
    this.parentMessageId,
  });

  final String id;
  final String name;
  final ToolActivityPhase phase;
  final String? parentMessageId;

  ToolActivityView copyWith({
    String? name,
    ToolActivityPhase? phase,
    String? parentMessageId,
  }) => ToolActivityView(
    id: id,
    name: name ?? this.name,
    phase: phase ?? this.phase,
    parentMessageId: parentMessageId ?? this.parentMessageId,
  );
}

final class AgentViewState {
  AgentViewState({
    List<MessageView> messages = const [],
    List<ToolActivityView> tools = const [],
    List<SourceReferenceView> sourceReferences = const [],
    this.connectionPhase = ConnectionPhase.idle,
    this.runPhase = RunPhase.idle,
    this.failure,
    this.omittedOlderMessages = false,
    this.isStale = false,
    this.status,
  }) : messages = UnmodifiableListView(messages),
       tools = UnmodifiableListView(tools),
       sourceReferences = UnmodifiableListView(sourceReferences) {
    final messageIds = messages.map((message) => message.id).toSet();
    if (sourceReferences.map((reference) => reference.id).toSet().length !=
            sourceReferences.length ||
        sourceReferences.any(
          (reference) => !messageIds.contains(reference.parentMessageId),
        )) {
      throw ArgumentError(
        'Source references must have unique IDs and message parents',
      );
    }
  }

  final UnmodifiableListView<MessageView> messages;
  final UnmodifiableListView<ToolActivityView> tools;
  final UnmodifiableListView<SourceReferenceView> sourceReferences;
  final ConnectionPhase connectionPhase;
  final RunPhase runPhase;
  final ViewFailure? failure;
  final bool omittedOlderMessages;
  final bool isStale;
  final String? status;

  AgentViewState copyWith({
    List<MessageView>? messages,
    List<ToolActivityView>? tools,
    List<SourceReferenceView>? sourceReferences,
    ConnectionPhase? connectionPhase,
    RunPhase? runPhase,
    Object? failure = _unset,
    bool? omittedOlderMessages,
    bool? isStale,
    Object? status = _unset,
  }) => AgentViewState(
    messages: messages ?? this.messages,
    tools: tools ?? this.tools,
    sourceReferences: sourceReferences ?? this.sourceReferences,
    connectionPhase: connectionPhase ?? this.connectionPhase,
    runPhase: runPhase ?? this.runPhase,
    failure: identical(failure, _unset)
        ? this.failure
        : failure as ViewFailure?,
    omittedOlderMessages: omittedOlderMessages ?? this.omittedOlderMessages,
    isStale: isStale ?? this.isStale,
    status: identical(status, _unset) ? this.status : status as String?,
  );

  Map<String, Object?> toSafeJson() => {
    'messages': [
      for (final message in messages)
        {
          'id': message.id,
          'role': message.role.name,
          'text': message.text,
          'isStreaming': message.isStreaming,
          'liveUnavailable': message.liveUnavailable,
        },
    ],
    'tools': [
      for (final tool in tools)
        {
          'id': tool.id,
          'name': tool.name,
          'phase': tool.phase.name,
          if (tool.parentMessageId != null)
            'parentMessageId': tool.parentMessageId,
        },
    ],
    'sourceReferences': [
      for (final reference in sourceReferences)
        {
          'id': reference.id,
          'parentMessageId': reference.parentMessageId,
          'label': reference.label,
          'passage': reference.passage,
          'startLine': reference.startLine,
          'endLine': reference.endLine,
          if (reference.highlightStartLine != null)
            'highlightStartLine': reference.highlightStartLine,
          if (reference.highlightEndLine != null)
            'highlightEndLine': reference.highlightEndLine,
          if (reference.revisionLabel != null)
            'revisionLabel': reference.revisionLabel,
          'availability': reference.availability.name,
        },
    ],
    'connectionPhase': connectionPhase.name,
    'runPhase': runPhase.name,
    if (failure != null) 'failure': failure!.kind.name,
    'omittedOlderMessages': omittedOlderMessages,
    'isStale': isStale,
    if (status != null) 'status': status,
  };
}

const Object _unset = Object();
