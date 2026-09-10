import 'package:flutter/foundation.dart';

/// How a changed file differs from its previous revision.
enum BirbReviewFileChange { added, modified, deleted, renamed }

/// Whether a changed file has displayable text content.
///
/// [binary] and [unavailable] files render a distinct message instead of an
/// empty text diff.
enum BirbReviewContentAvailability { text, binary, unavailable }

/// The role a displayed source line plays in a unified diff.
enum BirbDiffLineKind { context, addition, deletion }

/// Which revision side of a diff a line position belongs to.
///
/// [before] is the old side and [after] is the new side. A deletion anchors to
/// [before]; a context or added line anchors to [after].
enum BirbDiffSide { before, after }

/// A review's presentation state.
///
/// This is display state only. It implies nothing about mergeability or about
/// the viewer's authorization.
enum BirbReviewStatus { pending, approved, changesRequested, commented }

/// One changed file in a review.
///
/// [path] and [previousPath] are display strings. They are never treated as
/// filesystem access instructions or parsed as URLs.
@immutable
final class BirbReviewFile {
  BirbReviewFile({
    required this.id,
    required this.path,
    required this.change,
    this.previousPath,
    this.additions = 0,
    this.deletions = 0,
    this.content = BirbReviewContentAvailability.text,
  }) {
    _requireIdentity(id, 'BirbReviewFile.id');
    _requireDisplayText(path, 'BirbReviewFile.path');
    if (previousPath != null) {
      _requireDisplayText(previousPath!, 'BirbReviewFile.previousPath');
    }
    if (change == BirbReviewFileChange.renamed && previousPath == null) {
      throw ArgumentError.value(
        previousPath,
        'previousPath',
        'a renamed file requires its previous display path',
      );
    }
    if (additions < 0) {
      throw ArgumentError.value(additions, 'additions', 'must not be negative');
    }
    if (deletions < 0) {
      throw ArgumentError.value(deletions, 'deletions', 'must not be negative');
    }
  }

  final String id;
  final String path;
  final String? previousPath;
  final BirbReviewFileChange change;
  final int additions;
  final int deletions;
  final BirbReviewContentAvailability content;

  @override
  bool operator ==(Object other) =>
      other is BirbReviewFile &&
      other.id == id &&
      other.path == path &&
      other.previousPath == previousPath &&
      other.change == change &&
      other.additions == additions &&
      other.deletions == deletions &&
      other.content == content;

  @override
  int get hashCode => Object.hash(
    id,
    path,
    previousPath,
    change,
    additions,
    deletions,
    content,
  );

  @override
  String toString() => 'BirbReviewFile($id, $path, ${change.name})';
}

/// One displayed source line of a unified diff.
///
/// [text] excludes the line terminator. Hosts supply numbering; no widget
/// reconstructs patch positions.
@immutable
final class BirbDiffLine {
  BirbDiffLine({
    required this.id,
    required this.kind,
    required this.text,
    this.oldNumber,
    this.newNumber,
    this.hasNoFinalNewline = false,
  }) {
    _requireIdentity(id, 'BirbDiffLine.id');
    if (text.contains('\n') || text.contains('\r')) {
      throw ArgumentError.value(
        text,
        'text',
        'must not contain a line terminator',
      );
    }
    switch (kind) {
      case BirbDiffLineKind.context:
        _requirePosition(oldNumber, 'oldNumber', required: true);
        _requirePosition(newNumber, 'newNumber', required: true);
      case BirbDiffLineKind.addition:
        _requireAbsent(oldNumber, 'oldNumber', 'an added line has no old side');
        _requirePosition(newNumber, 'newNumber', required: true);
      case BirbDiffLineKind.deletion:
        _requirePosition(oldNumber, 'oldNumber', required: true);
        _requireAbsent(
          newNumber,
          'newNumber',
          'a deleted line has no new side',
        );
    }
  }

  final String id;
  final BirbDiffLineKind kind;
  final String text;
  final int? oldNumber;
  final int? newNumber;
  final bool hasNoFinalNewline;

  /// The revision side a line action anchors to.
  BirbDiffSide get side => kind == BirbDiffLineKind.deletion
      ? BirbDiffSide.before
      : BirbDiffSide.after;

  /// The line number on [side].
  int get anchoredNumber =>
      kind == BirbDiffLineKind.deletion ? oldNumber! : newNumber!;

  @override
  bool operator ==(Object other) =>
      other is BirbDiffLine &&
      other.id == id &&
      other.kind == kind &&
      other.text == text &&
      other.oldNumber == oldNumber &&
      other.newNumber == newNumber &&
      other.hasNoFinalNewline == hasNoFinalNewline;

  @override
  int get hashCode =>
      Object.hash(id, kind, text, oldNumber, newNumber, hasNoFinalNewline);

  @override
  String toString() => 'BirbDiffLine($id, ${kind.name}, $oldNumber/$newNumber)';
}

/// One contiguous group of displayed diff lines.
///
/// An empty [lines] list is a legal empty state.
@immutable
final class BirbDiffHunk {
  BirbDiffHunk({
    required this.id,
    required List<BirbDiffLine> lines,
    this.heading,
  }) : lines = List<BirbDiffLine>.unmodifiable(lines) {
    _requireIdentity(id, 'BirbDiffHunk.id');
    if (heading != null) {
      _requireDisplayText(heading!, 'BirbDiffHunk.heading');
    }
  }

  final String id;
  final String? heading;
  final List<BirbDiffLine> lines;

  @override
  bool operator ==(Object other) =>
      other is BirbDiffHunk &&
      other.id == id &&
      other.heading == heading &&
      listEquals(other.lines, lines);

  @override
  int get hashCode => Object.hash(id, heading, Object.hashAll(lines));

  @override
  String toString() => 'BirbDiffHunk($id, ${lines.length} lines)';
}

/// One validated file revision that a diff view can display.
///
/// Identity validation happens once here rather than on every lazy row build.
/// Replacing [revisionId] invalidates any anchor selected against the previous
/// revision.
@immutable
final class BirbDiffSnapshot {
  BirbDiffSnapshot({
    required this.file,
    required this.revisionId,
    required List<BirbDiffHunk> hunks,
  }) : hunks = List<BirbDiffHunk>.unmodifiable(hunks),
       _lineIds = _validatedLineIds(file, revisionId, hunks);

  /// Validates identities once and returns the line index used for anchoring.
  static Set<String> _validatedLineIds(
    BirbReviewFile file,
    String revisionId,
    List<BirbDiffHunk> hunks,
  ) {
    _requireIdentity(revisionId, 'BirbDiffSnapshot.revisionId');
    final hunkIds = <String>{};
    final lineIds = <String>{};
    for (final hunk in hunks) {
      if (!hunkIds.add(hunk.id)) {
        throw ArgumentError.value(
          hunk.id,
          'hunks',
          'duplicate hunk id in one displayed file',
        );
      }
      for (final line in hunk.lines) {
        if (!lineIds.add(line.id)) {
          throw ArgumentError.value(
            line.id,
            'hunks',
            'duplicate line id in one displayed file',
          );
        }
      }
    }
    if (file.content != BirbReviewContentAvailability.text &&
        hunks.isNotEmpty) {
      throw ArgumentError.value(
        file.content.name,
        'hunks',
        'only text content may supply diff hunks',
      );
    }
    return Set<String>.unmodifiable(lineIds);
  }

  final BirbReviewFile file;
  final String revisionId;
  final List<BirbDiffHunk> hunks;

  /// Validated line identities, used for constant-time anchor membership.
  final Set<String> _lineIds;

  /// Every displayed line in document order.
  Iterable<BirbDiffLine> get lines => hunks.expand((hunk) => hunk.lines);

  /// Whether this snapshot has no displayable line.
  bool get isEmpty => hunks.every((hunk) => hunk.lines.isEmpty);

  /// Builds the anchor a line action emits for [line].
  ///
  /// Throws [ArgumentError] when [line] does not belong to this snapshot.
  BirbDiffAnchor anchorFor(BirbDiffLine line) {
    if (!_lineIds.contains(line.id)) {
      throw ArgumentError.value(
        line.id,
        'line',
        'does not belong to this snapshot',
      );
    }
    return BirbDiffAnchor(
      fileId: file.id,
      revisionId: revisionId,
      lineId: line.id,
      side: line.side,
      lineNumber: line.anchoredNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BirbDiffSnapshot &&
      other.file == file &&
      other.revisionId == revisionId &&
      listEquals(other.hunks, hunks);

  @override
  int get hashCode => Object.hash(file, revisionId, Object.hashAll(hunks));

  @override
  String toString() => 'BirbDiffSnapshot(${file.id}@$revisionId)';
}

/// A stable location a discussion attaches to.
///
/// Hosts map this to a provider-specific API position. The widgets never
/// reconstruct one.
@immutable
final class BirbDiffAnchor {
  BirbDiffAnchor({
    required this.fileId,
    required this.revisionId,
    required this.lineId,
    required this.side,
    required this.lineNumber,
  }) {
    _requireIdentity(fileId, 'BirbDiffAnchor.fileId');
    _requireIdentity(revisionId, 'BirbDiffAnchor.revisionId');
    _requireIdentity(lineId, 'BirbDiffAnchor.lineId');
    _requirePosition(lineNumber, 'lineNumber', required: true);
  }

  final String fileId;
  final String revisionId;
  final String lineId;
  final BirbDiffSide side;
  final int lineNumber;

  @override
  bool operator ==(Object other) =>
      other is BirbDiffAnchor &&
      other.fileId == fileId &&
      other.revisionId == revisionId &&
      other.lineId == lineId &&
      other.side == side &&
      other.lineNumber == lineNumber;

  @override
  int get hashCode => Object.hash(fileId, revisionId, lineId, side, lineNumber);

  @override
  String toString() =>
      'BirbDiffAnchor($fileId@$revisionId, $lineId, ${side.name} $lineNumber)';
}

/// One plain-text review comment.
///
/// [timestamp] is host-formatted display text so the package needs no
/// localization framework. [body] is never parsed as Markdown, HTML, or a URL.
@immutable
final class BirbReviewComment {
  BirbReviewComment({
    required this.id,
    required this.author,
    required this.timestamp,
    required this.body,
  }) {
    _requireIdentity(id, 'BirbReviewComment.id');
    _requireDisplayText(author, 'BirbReviewComment.author');
    _requireDisplayText(timestamp, 'BirbReviewComment.timestamp');
    if (body.trim().isEmpty) {
      throw ArgumentError.value(body, 'body', 'must not be blank');
    }
  }

  final String id;
  final String author;
  final String timestamp;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is BirbReviewComment &&
      other.id == id &&
      other.author == author &&
      other.timestamp == timestamp &&
      other.body == body;

  @override
  int get hashCode => Object.hash(id, author, timestamp, body);

  @override
  String toString() => 'BirbReviewComment($id, $author)';
}

/// One review conversation.
///
/// A null [anchor] is a general discussion. An [outdated] thread stays readable
/// and keeps its recorded location, but never silently attaches to the current
/// diff.
@immutable
final class BirbReviewThread {
  BirbReviewThread({
    required this.id,
    required List<BirbReviewComment> comments,
    this.anchor,
    this.resolved = false,
    this.outdated = false,
  }) : comments = List<BirbReviewComment>.unmodifiable(comments) {
    _requireIdentity(id, 'BirbReviewThread.id');
    final commentIds = <String>{};
    for (final comment in this.comments) {
      if (!commentIds.add(comment.id)) {
        throw ArgumentError.value(
          comment.id,
          'comments',
          'duplicate comment id in one thread',
        );
      }
    }
  }

  final String id;
  final BirbDiffAnchor? anchor;
  final List<BirbReviewComment> comments;
  final bool resolved;
  final bool outdated;

  @override
  bool operator ==(Object other) =>
      other is BirbReviewThread &&
      other.id == id &&
      other.anchor == anchor &&
      other.resolved == resolved &&
      other.outdated == outdated &&
      listEquals(other.comments, comments);

  @override
  int get hashCode =>
      Object.hash(id, anchor, resolved, outdated, Object.hashAll(comments));

  @override
  String toString() =>
      'BirbReviewThread($id, ${comments.length} comments, '
      'resolved: $resolved, outdated: $outdated)';
}

void _requireIdentity(String value, String name) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be empty');
  }
}

/// Bidi overrides and isolates, which can make one path render as another.
const Set<int> _forbiddenDisplayRunes = <int>{
  0x200E, 0x200F, // LRM, RLM
  0x202A, 0x202B, 0x202C, 0x202D, 0x202E, // embeddings and overrides
  0x2066, 0x2067, 0x2068, 0x2069, // isolates
};

void _requireDisplayText(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  for (final rune in value.runes) {
    if (rune == 0x0A || rune == 0x0D) {
      throw ArgumentError.value(value, name, 'must be a single display line');
    }
    if (_forbiddenDisplayRunes.contains(rune)) {
      throw ArgumentError.value(
        value,
        name,
        'must not contain a bidirectional override, which could make one '
        'path render as another',
      );
    }
  }
}

void _requirePosition(int? value, String name, {required bool required}) {
  if (value == null) {
    if (required) {
      throw ArgumentError.notNull(name);
    }
    return;
  }
  if (value < 1) {
    throw ArgumentError.value(value, name, 'must be a positive line number');
  }
}

void _requireAbsent(int? value, String name, String reason) {
  if (value != null) {
    throw ArgumentError.value(value, name, reason);
  }
}
