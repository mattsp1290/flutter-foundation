import 'dart:convert';

import 'package:birb_code_editor/birb_code_editor.dart';
import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';

import 'editor_provider_fixture.dart';

class CodeChatPage extends StatefulWidget {
  const CodeChatPage({super.key});
  @override
  State<CodeChatPage> createState() => _CodeChatPageState();
}

class _CodeChatPageState extends State<CodeChatPage> {
  static const _initialSource =
      'package main\r\n\r\n// Exact mixed separators.\rfunc main() {\n\tprintln("hello", 42)\r\n}\n';
  final _editor = BirbEditorController(
    documentId: 'catalog-main',
    source: _initialSource,
  );
  final _secondEditor = BirbEditorController(
    documentId: 'catalog-independent',
    source: 'package example\n\nfunc Double(n int) int {\n\treturn n * 2\n}\n',
  );
  final _code = BirbCodeController(
    text: 'package solution\n\n// Try a different editor theme.\nfunc Add(a, b int) int {\n\treturn a + b\n}\n',
  );
  final _draft = TextEditingController();
  BirbCodeTheme _theme = BirbCodeTheme.foundation;
  bool _readOnly = false;
  CatalogProviderMode _providerMode = CatalogProviderMode.local;
  BirbEditorProvider? _provider = const CatalogEditorProvider(
    CatalogProviderMode.local,
  );
  String _recovery = _initialSource;
  String _message = 'Shared chat stays readable in light and dark mode.';
  @override
  void initState() {
    super.initState();
    _editor.addTextListener(_recover);
  }

  void _recover(BirbEditorSnapshot snapshot) =>
      setState(() => _recovery = snapshot.source);

  @override
  void dispose() {
    _editor.removeTextListener(_recover);
    _editor.dispose();
    _secondEditor.dispose();
    _code.dispose();
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('catalog-code-page'),
    padding: const EdgeInsets.all(16),
    children: [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          BirbCodeThemeSelector(
            value: _theme,
            onChanged: (value) => setState(() => _theme = value),
          ),
          FilterChip(
            label: const Text('Read only'),
            selected: _readOnly,
            onSelected: (value) {
              _editor.setReadOnly(value);
              setState(() => _readOnly = value);
            },
          ),
          DropdownButton<CatalogProviderMode>(
            value: _providerMode,
            items: const [
              DropdownMenuItem(
                value: CatalogProviderMode.local,
                child: Text('Local provider'),
              ),
              DropdownMenuItem(
                value: CatalogProviderMode.delayed,
                child: Text('Delayed provider'),
              ),
              DropdownMenuItem(
                value: CatalogProviderMode.failing,
                child: Text('Failing provider'),
              ),
              DropdownMenuItem(
                value: CatalogProviderMode.unavailable,
                child: Text('No provider'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _providerMode = value;
                _provider = value == CatalogProviderMode.unavailable
                    ? null
                    : CatalogEditorProvider(value);
              });
            },
          ),
          TextButton(
            onPressed: () =>
                _editor.replaceDocument(documentId: 'catalog-main', source: ''),
            child: const Text('Empty source'),
          ),
          TextButton(
            onPressed: () => _editor.replaceDocument(
              documentId: 'catalog-main',
              source: _recovery,
            ),
            child: const Text('Reload recovered source'),
          ),
        ],
      ),
      Semantics(
        label: const bool.fromEnvironment('BIRB_EDITOR_ACCEPTANCE')
            ? 'Editor observation ${jsonEncode({'units': _recovery.codeUnits, 'length': _recovery.length, 'generation': _editor.snapshot.generation})}'
            : null,
        excludeSemantics: const bool.fromEnvironment('BIRB_EDITOR_ACCEPTANCE'),
        child: Text('Recovery: ${_recovery.length} UTF-16 units'),
      ),
      SizedBox(
        height: 520,
        child: BirbSourceEditor(
          key: const ValueKey('catalog-production-editor'),
          controller: _editor,
          provider: _provider,
          codeTheme: _theme,
          label: 'Go source code',
        ),
      ),
      const SizedBox(height: 24),
      const Text('Independent editor'),
      SizedBox(
        height: 400,
        child: BirbSourceEditor(
          controller: _secondEditor,
          codeTheme: _theme,
          label: 'Independent Go source',
        ),
      ),
      const SizedBox(height: 24),
      const Text('Legacy editor — existing API'),
      SizedBox(
        height: 200,
        child: BirbCodeEditor(
          controller: _code,
          theme: _theme,
          readOnly: _readOnly,
          label: 'Go source code',
        ),
      ),
      BirbChatMessage(author: 'Coach', text: _message),
      BirbChatComposer(
        controller: _draft,
        onSubmit: (value) => setState(() => _message = value),
      ),
    ],
  );
}
