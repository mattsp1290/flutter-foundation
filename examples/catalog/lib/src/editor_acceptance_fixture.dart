/// Compile-time opt-in for synthetic release acceptance observations.
const editorAcceptanceEnabled = bool.fromEnvironment('BIRB_EDITOR_ACCEPTANCE');

String editorAcceptanceSource(String normalSource) {
  if (!editorAcceptanceEnabled ||
      Uri.base.queryParameters['editor-fixture'] != 'large') {
    return normalSource;
  }
  final prefix = List.generate(
    1999,
    (index) => '// row ${index.toString().padLeft(4, '0')} ${'x' * 16}\n',
  ).join();
  // Exactly 64 KiB of ASCII source and 2,000 logical lines, without a final LF.
  return '$prefix// ${'x' * (65536 - prefix.length - 3)}';
}
