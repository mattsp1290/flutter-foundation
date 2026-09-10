import 'package:flutter/foundation.dart';

import '../../birb_design_system.dart';

/// How a fixture's diff content arrives in the simulated host.
enum BirbReviewLoadState { loading, ready, failed }

/// Whether a simulated submission succeeds or fails.
enum BirbReviewOutcome { succeeds, fails }

/// One pending simulated submission.
///
/// The identity is the draft key plus the revision the draft was written
/// against, so a late completion can be matched to exactly one draft and
/// rejected when the revision has moved on.
@immutable
final class BirbReviewSubmission {
  const BirbReviewSubmission({
    required this.draftKey,
    required this.revisionId,
    required this.text,
  });

  final String draftKey;
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
    this.pending,
    this.submissionError,
    this.failedDraftKey,
    this.threadUpdateId,
    this.threadError,
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
  final BirbReviewSubmission? pending;
  final String? submissionError;

  /// Which draft the visible [submissionError] belongs to.
  final String? failedDraftKey;
  final String? threadUpdateId;
  final String? threadError;

  /// A visible message when a late completion no longer matches the content.
  final String? staleResultMessage;
  final BirbReviewOutcome nextOutcome;

  BirbDiffSnapshot get selectedSnapshot => snapshots[selectedFileId]!;

  /// The threads that belong to the selected file's current revision, plus
  /// every general discussion.
  List<BirbReviewThread> get visibleThreads {
    final snapshot = selectedSnapshot;
    return <BirbReviewThread>[
      for (final thread in threads)
        if (thread.anchor == null || thread.anchor!.fileId == snapshot.file.id)
          thread,
    ];
  }

  /// The draft key for a reply on [threadId].
  static String replyDraftKey(String threadId) => 'thread:$threadId';

  /// The draft key for a new discussion at [anchor].
  static String anchorDraftKey(BirbDiffAnchor anchor) =>
      'anchor:${anchor.fileId}:${anchor.revisionId}:${anchor.lineId}';

  BirbReviewDemoState copyWith({
    Map<String, BirbDiffSnapshot>? snapshots,
    List<BirbReviewThread>? threads,
    String? selectedFileId,
    BirbReviewStatus? status,
    BirbReviewLoadState? loadState,
    BirbDiffAnchor? selectedAnchor,
    bool clearSelectedAnchor = false,
    BirbReviewSubmission? pending,
    bool clearPending = false,
    String? submissionError,
    String? failedDraftKey,
    bool clearSubmissionError = false,
    String? threadUpdateId,
    bool clearThreadUpdate = false,
    String? threadError,
    bool clearThreadError = false,
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
      pending: clearPending ? null : pending ?? this.pending,
      submissionError: clearSubmissionError
          ? null
          : submissionError ?? this.submissionError,
      failedDraftKey: clearSubmissionError
          ? null
          : failedDraftKey ?? this.failedDraftKey,
      threadUpdateId: clearThreadUpdate
          ? null
          : threadUpdateId ?? this.threadUpdateId,
      threadError: clearThreadError ? null : threadError ?? this.threadError,
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
