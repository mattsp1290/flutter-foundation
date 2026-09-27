import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';

class CodeChatPage extends StatefulWidget {
  const CodeChatPage({super.key});
  @override
  State<CodeChatPage> createState() => _CodeChatPageState();
}

class _CodeChatPageState extends State<CodeChatPage> {
  final _code = BirbCodeController(
    text: 'package solution\n\n// Try a different editor theme.\nfunc Add(a, b int) int {\n\treturn a + b\n}\n',
  );
  final _draft = TextEditingController();
  BirbCodeTheme _theme = BirbCodeTheme.foundation;
  bool _readOnly = false;
  String _message = 'Shared chat stays readable in light and dark mode.';
  @override
  void dispose() {
    _code.dispose();
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
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
            onSelected: (value) => setState(() => _readOnly = value),
          ),
          TextButton(
            onPressed: () => _code.clear(),
            child: const Text('Empty source'),
          ),
        ],
      ),
      SizedBox(
        height: 320,
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
