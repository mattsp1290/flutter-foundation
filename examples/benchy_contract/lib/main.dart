import 'package:ag_ui_view_state/ag_ui_view_state.dart';
import 'package:birb_ag_ui_widgets/birb_ag_ui_widgets.dart';
import 'package:flutter/material.dart';

void main() => runApp(const BenchyContractApp());

final class BenchyContractApp extends StatefulWidget {
  const BenchyContractApp({super.key});
  @override
  State<BenchyContractApp> createState() => _BenchyContractAppState();
}

final class _BenchyContractAppState extends State<BenchyContractApp> {
  final text = TextEditingController();
  final focus = FocusNode();
  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: BirbAgentConversation(
        state: AgentViewState(
          messages: const [
            MessageView(
              id: 'assistant',
              role: ViewMessageRole.assistant,
              text: 'Synthetic host-authority fixture',
            ),
          ],
        ),
        controller: text,
        focusNode: focus,
        onSend: (_) async {},
        persistentHostAction: OutlinedButton(
          onPressed: () {},
          child: const Text('Simulated hardware abort'),
        ),
      ),
    ),
  );
  @override
  void dispose() {
    text.dispose();
    focus.dispose();
    super.dispose();
  }
}
