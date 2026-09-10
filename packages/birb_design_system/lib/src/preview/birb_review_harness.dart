import 'dart:async';

import 'package:flutter/material.dart';

import '../../birb_design_system.dart';
import 'birb_review_fixtures.dart';
import 'birb_review_state.dart';

/// Stable lookup keys for the review preview.
abstract final class BirbReviewHarnessKeys {
  static const ValueKey<String> root = ValueKey<String>('birb-review-harness');
  static const ValueKey<String> simulationNotice = ValueKey<String>(
    'birb-review-harness-simulated',
  );
  static const ValueKey<String> fileList = ValueKey<String>(
    'birb-review-harness-files',
  );
  static const ValueKey<String> diff = ValueKey<String>(
    'birb-review-harness-diff',
  );
  static const ValueKey<String> loadingNotice = ValueKey<String>(
    'birb-review-harness-loading',
  );
  static const ValueKey<String> loadErrorNotice = ValueKey<String>(
    'birb-review-harness-load-error',
  );
  static const ValueKey<String> retryLoad = ValueKey<String>(
    'birb-review-harness-retry-load',
  );
  static const ValueKey<String> failNextToggle = ValueKey<String>(
    'birb-review-harness-fail-next',
  );
  static const ValueKey<String> staleNotice = ValueKey<String>(
    'birb-review-harness-stale',
  );
  static const ValueKey<String> newDiscussionComposer = ValueKey<String>(
    'birb-review-harness-new-discussion',
  );
  static const ValueKey<String> pushRevision = ValueKey<String>(
    'birb-review-harness-push-revision',
  );

  /// The badge for [status] in the status legend.
  static ValueKey<String> status(BirbReviewStatus status) =>
      ValueKey<String>('birb-review-harness-status-${status.name}');

  /// The rendered thread identified by [threadId].
  static ValueKey<String> thread(String threadId) =>
      ValueKey<String>('birb-review-harness-thread-$threadId');

  /// The reply composer for the thread identified by [threadId].
  static ValueKey<String> replyComposer(String threadId) =>
      ValueKey<String>('birb-review-harness-reply-$threadId');
}

/// A runnable, simulated pull-request review built only from public APIs.
///
/// The harness is a local host with deterministic fixtures: it never contacts a
/// service, never sends a real review, and says so on screen. Loading, failure,
/// retry, and submission outcomes are controllable so the components' host
/// contracts can be inspected by hand and asserted in tests.
///
/// Drafts are keyed by thread — and by new-discussion anchor including the
/// revision — so a late completion updates only the draft it belongs to.
class BirbReviewHarness extends StatefulWidget {
  const BirbReviewHarness({super.key, this.completionDelay = Duration.zero});

  /// How long a simulated submission or load takes.
  final Duration completionDelay;

  @override
  State<BirbReviewHarness> createState() => _BirbReviewHarnessState();
}

class _BirbReviewHarnessState extends State<BirbReviewHarness> {
  final Map<String, TextEditingController> _drafts =
      <String, TextEditingController>{};
  final List<Timer> _timers = <Timer>[];

  late BirbReviewDemoState _state;
  int _threadSequence = 0;
  int _revisionSequence = 1;

  @override
  void initState() {
    super.initState();
    _state = birbReviewFixtureState();
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    for (final controller in _drafts.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _draftFor(String key) =>
      _drafts.putIfAbsent(key, TextEditingController.new);

  /// Runs [completion] after the configured delay, guarded against unmount.
  void _schedule(void Function() completion) {
    late final Timer timer;
    timer = Timer(widget.completionDelay, () {
      _timers.remove(timer);
      if (mounted) completion();
    });
    _timers.add(timer);
  }

  void _selectFile(String fileId) {
    setState(() {
      _state = _state.copyWith(
        selectedFileId: fileId,
        clearSelectedAnchor: true,
        clearStaleResult: true,
      );
    });
  }

  void _selectAnchor(BirbDiffAnchor anchor) {
    setState(() {
      _state = _state.copyWith(selectedAnchor: anchor, clearStaleResult: true);
    });
  }

  /// Simulates a force-push: the file keeps its identity, the revision moves.
  void _pushRevision() {
    _revisionSequence += 1;
    setState(() {
      _state = _state
          .withNewRevision('fixture-revision-$_revisionSequence')
          .copyWith(clearStaleResult: true);
    });
  }

  void _reloadContent() {
    setState(() {
      _state = _state.copyWith(loadState: BirbReviewLoadState.loading);
    });
    // Loading honours the same outcome toggle as every other request, so the
    // host-owned failure and retry path is reachable rather than dead code.
    final outcome = _state.nextOutcome;
    _schedule(() {
      setState(() {
        _state = _state.copyWith(
          loadState: outcome == BirbReviewOutcome.fails
              ? BirbReviewLoadState.failed
              : BirbReviewLoadState.ready,
        );
      });
    });
  }

  void _submit(String draftKey, String text, {BirbDiffAnchor? anchor}) {
    final revisionId = _state.selectedSnapshot.revisionId;
    setState(() {
      _state = _state.copyWith(
        // Each draft has its own in-flight entry, so a second reply never
        // discards a first that is still running.
        pending: <String, BirbReviewSubmission>{
          ..._state.pending,
          draftKey: BirbReviewSubmission(
            draftKey: draftKey,
            revisionId: revisionId,
            text: text,
          ),
        },
        clearSubmissionError: true,
        clearStaleResult: true,
      );
    });

    final outcome = _state.nextOutcome;
    _schedule(() {
      final submission = _state.pending[draftKey];
      if (submission == null) return;
      final remaining = <String, BirbReviewSubmission>{..._state.pending}
        ..remove(draftKey);

      if (outcome == BirbReviewOutcome.fails) {
        setState(() {
          _state = _state.copyWith(
            pending: remaining,
            submissionError:
                'The simulated host rejected this reply. Your draft is kept.',
            failedDraftKey: draftKey,
          );
        });
        return;
      }
      if (submission.revisionId != _state.selectedSnapshot.revisionId) {
        setState(() {
          _state = _state.copyWith(
            pending: remaining,
            staleResultMessage:
                'A reply completed for an earlier revision and was not '
                'attached to the current content.',
          );
        });
        return;
      }

      final comment = BirbReviewComment(
        id: 'comment-$draftKey-${_threadSequence++}',
        author: 'You',
        timestamp: 'just now',
        body: submission.text,
      );
      setState(() {
        final threadId = draftKey.startsWith('thread:')
            ? draftKey.substring('thread:'.length)
            : 'thread-new-${_threadSequence++}';
        _state =
            (anchor == null
                    ? _state.withComment(threadId, comment)
                    : _state.withNewThread(threadId, anchor, comment))
                .copyWith(pending: remaining, clearSubmissionError: true);
      });
      // Only the successful draft is cleared, and only by the host.
      _drafts[draftKey]?.clear();
    });
  }

  void _requestResolution(String threadId, {required bool resolved}) {
    setState(() {
      _state = _state.copyWith(
        updatingThreadIds: <String>{..._state.updatingThreadIds, threadId},
        clearThreadError: true,
      );
    });
    final outcome = _state.nextOutcome;
    _schedule(() {
      final remaining = <String>{..._state.updatingThreadIds}..remove(threadId);
      setState(() {
        _state = outcome == BirbReviewOutcome.fails
            ? _state.copyWith(
                updatingThreadIds: remaining,
                threadError: 'The simulated host could not change this thread.',
                failedThreadId: threadId,
              )
            : _state
                  .withResolved(threadId, resolved: resolved)
                  .copyWith(
                    updatingThreadIds: remaining,
                    clearThreadError: true,
                  );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: BirbReviewHarnessKeys.root,
      appBar: AppBar(title: const Text('Code review preview')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final diff = SizedBox(
            height: (constraints.maxHeight * 0.55).clamp(240.0, 640.0),
            child: _diffRegion(theme),
          );
          final navigation = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _notice(theme),
              const SizedBox(height: BirbSpacing.space3),
              _controls(theme),
              const SizedBox(height: BirbSpacing.space3),
              BirbChangedFileList(
                key: BirbReviewHarnessKeys.fileList,
                files: _state.files,
                selectedFileId: _state.selectedFileId,
                onFileSelected: _selectFile,
              ),
            ],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(BirbSpacing.space4),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(width: 320, child: navigation),
                      const SizedBox(width: BirbSpacing.space4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[diff, _discussions(theme)],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      navigation,
                      const SizedBox(height: BirbSpacing.space4),
                      diff,
                      _discussions(theme),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _notice(ThemeData theme) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Expanded(
        child: Text(
          'Simulated review — nothing is sent anywhere.',
          key: BirbReviewHarnessKeys.simulationNotice,
          style: theme.textTheme.titleSmall,
        ),
      ),
    ],
  );

  Widget _controls(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Wrap(
        spacing: BirbSpacing.space2,
        runSpacing: BirbSpacing.space2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (final status in BirbReviewStatus.values)
            BirbReviewStatusBadge(
              key: BirbReviewHarnessKeys.status(status),
              status: status,
            ),
        ],
      ),
      const SizedBox(height: BirbSpacing.space2),
      Wrap(
        spacing: BirbSpacing.space2,
        runSpacing: BirbSpacing.space2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          BirbFilterChip(
            key: BirbReviewHarnessKeys.failNextToggle,
            label: const Text('Fail the next request'),
            selected: _state.nextOutcome == BirbReviewOutcome.fails,
            onSelected: (value) => setState(() {
              _state = _state.copyWith(
                nextOutcome: value
                    ? BirbReviewOutcome.fails
                    : BirbReviewOutcome.succeeds,
              );
            }),
          ),
          OutlinedButton.icon(
            key: BirbReviewHarnessKeys.retryLoad,
            onPressed: _reloadContent,
            icon: const Icon(Icons.refresh),
            label: const Text('Reload file content'),
          ),
          OutlinedButton.icon(
            key: BirbReviewHarnessKeys.pushRevision,
            onPressed: _pushRevision,
            icon: const Icon(Icons.upload_outlined),
            label: const Text('Push a new revision'),
          ),
        ],
      ),
    ],
  );

  Widget _diffRegion(ThemeData theme) {
    switch (_state.loadState) {
      case BirbReviewLoadState.loading:
        return Semantics(
          key: BirbReviewHarnessKeys.loadingNotice,
          container: true,
          liveRegion: true,
          label: 'Loading file content',
          child: const Center(child: CircularProgressIndicator()),
        );
      case BirbReviewLoadState.failed:
        return Column(
          key: BirbReviewHarnessKeys.loadErrorNotice,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'The simulated host could not load this file.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: BirbSpacing.space2),
            OutlinedButton(
              onPressed: _reloadContent,
              child: const Text('Try again'),
            ),
          ],
        );
      case BirbReviewLoadState.ready:
        return BirbDiffView(
          key: BirbReviewHarnessKeys.diff,
          snapshot: _state.selectedSnapshot,
          selectedAnchor: _state.selectedAnchor,
          onCommentRequested: _selectAnchor,
        );
    }
  }

  Widget _discussions(ThemeData theme) {
    final anchor = _state.selectedAnchor;
    final stale = _state.staleResultMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: BirbSpacing.space4),
        Text('Discussions', style: theme.textTheme.titleLarge),
        if (stale != null) ...<Widget>[
          const SizedBox(height: BirbSpacing.space2),
          Semantics(
            key: BirbReviewHarnessKeys.staleNotice,
            container: true,
            liveRegion: true,
            label: stale,
            child: ExcludeSemantics(
              child: Text(stale, style: theme.textTheme.bodySmall),
            ),
          ),
        ],
        if (anchor != null) ...<Widget>[
          const SizedBox(height: BirbSpacing.space3),
          Text(
            'New discussion on '
            '${anchor.side == BirbDiffSide.before ? 'old' : 'new'} '
            'line ${anchor.lineNumber}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: BirbSpacing.space2),
          _composer(
            key: BirbReviewHarnessKeys.newDiscussionComposer,
            draftKey: BirbReviewDemoState.anchorDraftKey(anchor),
            anchor: anchor,
          ),
        ],
        for (final thread in _state.visibleThreads) ...<Widget>[
          const SizedBox(height: BirbSpacing.space4),
          BirbReviewThreadView(
            key: BirbReviewHarnessKeys.thread(thread.id),
            thread: thread,
            isUpdating: _state.updatingThreadIds.contains(thread.id),
            errorText: _state.failedThreadId == thread.id
                ? _state.threadError
                : null,
            onResolutionRequested: _requestResolution,
          ),
          const SizedBox(height: BirbSpacing.space2),
          _composer(
            key: BirbReviewHarnessKeys.replyComposer(thread.id),
            draftKey: BirbReviewDemoState.replyDraftKey(thread.id),
          ),
        ],
      ],
    );
  }

  Widget _composer({
    required Key key,
    required String draftKey,
    BirbDiffAnchor? anchor,
  }) {
    final isSubmitting = _state.pending.containsKey(draftKey);
    return BirbReviewComposer(
      key: key,
      controller: _draftFor(draftKey),
      isSubmitting: isSubmitting,
      errorText: isSubmitting ? null : _errorFor(draftKey),
      onSubmit: (text) => _submit(draftKey, text, anchor: anchor),
    );
  }

  String? _errorFor(String draftKey) =>
      _state.failedDraftKey == draftKey ? _state.submissionError : null;
}
