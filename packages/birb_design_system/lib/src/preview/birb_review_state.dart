import 'package:flutter/foundation.dart';

import '../../birb_design_system.dart';

/// How a fixture's diff content arrives in the simulated host.
enum BirbReviewLoadState { loading, ready, failed }

/// Whether a simulated submission succeeds or fails.
enum BirbReviewOutcome { succeeds, fails }

/// Which draft a submission belongs to.
///
/// A typed key means the identity is constructed once and matched by value:
/// nothing formats it into a string and nothing parses it back out, so host
/// identifiers containing the separator cannot be misread.
@immutable
sealed class BirbReviewDraftKey {
  const BirbReviewDraftKey();
}

/// A reply to an existing thread.
final class BirbReviewReplyKey extends BirbReviewDraftKey {
  const BirbReviewReplyKey(this.threadId);

  final String threadId;

  @override
  bool operator ==(Object other) =>
      other is BirbReviewReplyKey && other.threadId == threadId;

  @override
  int get hashCode => Object.hash('reply', threadId);

  @override
  String toString() => 'reply($threadId)';
}

/// A new discussion at one anchor, including the revision it was written
/// against.
final class BirbReviewAnchorKey extends BirbReviewDraftKey {
  const BirbReviewAnchorKey(this.anchor);

  final BirbDiffAnchor anchor;

  @override
  bool operator ==(Object other) =>
      other is BirbReviewAnchorKey && other.anchor == anchor;

  @override
  int get hashCode => Object.hash('anchor', anchor);

  @override
  String toString() => 'anchor(${anchor.lineId}@${anchor.revisionId})';
}

/// One pending simulated submission.
///
/// The identity is the draft key, which already carries the revision an anchor
/// draft was written against, so a late completion can be matched to exactly
/// one draft and rejected when the revision has moved on.
@immutable
final class BirbReviewSubmission {
  const BirbReviewSubmission({
    required this.draftKey,
    required this.revisionId,
    required this.text,
  });

  final BirbReviewDraftKey draftKey;
  final String revisionId;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is BirbReviewSubmission &&
      other.draftKey == draftKey &&
      other.revisionId == revisionId &&
      other.text == text;

  @override
  int get hashCode => Object.hash(draftKey, revisionId, text);
}

/// The simulated review host's state, kept separate from its rendering.
///
/// This lives beside the preview, not in the runtime components: no widget in
/// `lib/src/review/` knows about it.
@immutable
final class BirbReviewDemoState {
  const BirbReviewDemoState({
    required this.files,
    required this.snapshots,
    required this.threads,
    required this.selectedFileId,
    this.status = BirbReviewStatus.pending,
    this.loadState = BirbReviewLoadState.ready,
    this.selectedAnchor,
    this.pending = const <BirbReviewDraftKey, BirbReviewSubmission>{},
    this.submissionErrors = const <BirbReviewDraftKey, String>{},
    this.updatingThreadIds = const <String>{},
    this.threadErrors = const <String, String>{},
    this.staleResultMessage,
    this.nextOutcome = BirbReviewOutcome.succeeds,
  });

  final List<BirbReviewFile> files;
  final Map<String, BirbDiffSnapshot> snapshots;
  final List<BirbReviewThread> threads;
  final String selectedFileId;
  final BirbReviewStatus status;
  final BirbReviewLoadState loadState;
  final BirbDiffAnchor? selectedAnchor;

  /// Submissions in flight, keyed by draft. Each draft completes on its own.
  final Map<BirbReviewDraftKey, BirbReviewSubmission> pending;

  /// The visible failure for each draft, keyed the same way as [pending].
  ///
  /// Errors are per draft so starting a second request never erases one the
  /// viewer has not read yet.
  final Map<BirbReviewDraftKey, String> submissionErrors;

  /// Threads whose resolved state the host is currently applying.
  final Set<String> updatingThreadIds;

  /// The visible failure for each thread, keyed by thread identity.
  final Map<String, String> threadErrors;

  /// A visible message when a late completion no longer matches the content.
  final String? staleResultMessage;
  final BirbReviewOutcome nextOutcome;

  BirbDiffSnapshot get selectedSnapshot => snapshots[selectedFileId]!;

  /// Throws when a fixture file has no snapshot, or the selection is unknown.
  ///
  /// Adding a file without its snapshot would otherwise fail with a null-check
  /// error inside a build or a timer callback.
  void debugAssertConsistent() {
    for (final file in files) {
      if (!snapshots.containsKey(file.id)) {
        throw StateError('fixture file ${file.id} has no snapshot');
      }
    }
    if (!snapshots.containsKey(selectedFileId)) {
      throw StateError('selected file $selectedFileId has no snapshot');
    }
  }

  /// The threads shown beside the selected file.
  ///
  /// Every general discussion is included, as is any thread anchored to this
  /// file — including one anchored to a superseded revision, which stays
  /// visible and outdated rather than silently reattaching.
  List<BirbReviewThread> get visibleThreads {
    final snapshot = selectedSnapshot;
    return <BirbReviewThread>[
      for (final thread in threads)
        if (thread.anchor == null || thread.anchor!.fileId == snapshot.file.id)
          thread,
    ];
  }

  /// The draft key for a reply on [threadId].
  static BirbReviewDraftKey replyDraftKey(String threadId) =>
      BirbReviewReplyKey(threadId);

  /// The draft key for a new discussion at [anchor].
  static BirbReviewDraftKey anchorDraftKey(BirbDiffAnchor anchor) =>
      BirbReviewAnchorKey(anchor);

  BirbReviewDemoState copyWith({
    Map<String, BirbDiffSnapshot>? snapshots,
    List<BirbReviewThread>? threads,
    String? selectedFileId,
    BirbReviewStatus? status,
    BirbReviewLoadState? loadState,
    BirbDiffAnchor? selectedAnchor,
    bool clearSelectedAnchor = false,
    Map<BirbReviewDraftKey, BirbReviewSubmission>? pending,
    Map<BirbReviewDraftKey, String>? submissionErrors,
    Set<String>? updatingThreadIds,
    Map<String, String>? threadErrors,
    String? staleResultMessage,
    bool clearStaleResult = false,
    BirbReviewOutcome? nextOutcome,
  }) {
    return BirbReviewDemoState(
      files: files,
      snapshots: snapshots ?? this.snapshots,
      threads: threads ?? this.threads,
      selectedFileId: selectedFileId ?? this.selectedFileId,
      status: status ?? this.status,
      loadState: loadState ?? this.loadState,
      selectedAnchor: clearSelectedAnchor
          ? null
          : selectedAnchor ?? this.selectedAnchor,
      pending: pending ?? this.pending,
      submissionErrors: submissionErrors ?? this.submissionErrors,
      updatingThreadIds: updatingThreadIds ?? this.updatingThreadIds,
      threadErrors: threadErrors ?? this.threadErrors,
      staleResultMessage: clearStaleResult
          ? null
          : staleResultMessage ?? this.staleResultMessage,
      nextOutcome: nextOutcome ?? this.nextOutcome,
    );
  }

  /// Appends [comment] to the thread identified by [threadId].
  BirbReviewDemoState withComment(String threadId, BirbReviewComment comment) {
    return copyWith(
      threads: <BirbReviewThread>[
        for (final thread in threads)
          if (thread.id == threadId)
            BirbReviewThread(
              id: thread.id,
              anchor: thread.anchor,
              resolved: thread.resolved,
              outdated: thread.outdated,
              comments: <BirbReviewComment>[...thread.comments, comment],
            )
          else
            thread,
      ],
    );
  }

  /// Adds a new thread anchored at [anchor] carrying [comment].
  BirbReviewDemoState withNewThread(
    String threadId,
    BirbDiffAnchor anchor,
    BirbReviewComment comment,
  ) {
    return copyWith(
      threads: <BirbReviewThread>[
        ...threads,
        BirbReviewThread(
          id: threadId,
          anchor: anchor,
          comments: <BirbReviewComment>[comment],
        ),
      ],
    );
  }

  /// Replaces the selected file's snapshot with a new revision.
  ///
  /// Anchors selected against the previous revision are dropped, and threads
  /// anchored to it become outdated instead of silently reattaching.
  BirbReviewDemoState withNewRevision(String revisionId) {
    final current = selectedSnapshot;
    return copyWith(
      snapshots: <String, BirbDiffSnapshot>{
        ...snapshots,
        selectedFileId: BirbDiffSnapshot(
          file: current.file,
          revisionId: revisionId,
          hunks: current.hunks,
        ),
      },
      threads: <BirbReviewThread>[
        for (final thread in threads)
          if (thread.anchor != null &&
              thread.anchor!.fileId == selectedFileId &&
              thread.anchor!.revisionId != revisionId)
            BirbReviewThread(
              id: thread.id,
              anchor: thread.anchor,
              resolved: thread.resolved,
              outdated: true,
              comments: thread.comments,
            )
          else
            thread,
      ],
      clearSelectedAnchor: true,
    );
  }

  /// Draft keys whose anchors named content this state no longer shows.
  ///
  /// A host uses this to release the controllers it created for them.
  Iterable<BirbReviewDraftKey> staleAnchorDraftKeys(
    Iterable<BirbReviewDraftKey> draftKeys,
  ) sync* {
    for (final key in draftKeys) {
      if (key is! BirbReviewAnchorKey) continue;
      final snapshot = snapshots[key.anchor.fileId];
      if (snapshot == null || !snapshot.contains(key.anchor)) yield key;
    }
  }

  /// Applies a resolved state to the thread identified by [threadId].
  BirbReviewDemoState withResolved(String threadId, {required bool resolved}) {
    return copyWith(
      threads: <BirbReviewThread>[
        for (final thread in threads)
          if (thread.id == threadId)
            BirbReviewThread(
              id: thread.id,
              anchor: thread.anchor,
              resolved: resolved,
              outdated: thread.outdated,
              comments: thread.comments,
            )
          else
            thread,
      ],
    );
  }
}
