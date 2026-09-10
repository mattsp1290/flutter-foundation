import 'dart:ui' show SemanticsAction, SemanticsValidationResult, Tristate;

import 'package:birb_design_system/birb_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final mode in <({String name, ThemeData theme})>[
    (name: 'light', theme: BirbTheme.light),
    (name: 'dark', theme: BirbTheme.dark),
  ]) {
    group('${mode.name} ledger field', () {
      testWidgets('keeps the caption separate and focuses from its cell', (
        tester,
      ) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        await _pumpField(tester, mode.theme, focusNode: focusNode);

        expect(find.text('Display name (required)'), findsOneWidget);
        final editable = tester.widget<TextField>(find.byType(TextField));
        expect(editable.decoration?.labelText, isNull);
        expect(editable.decoration?.border, InputBorder.none);

        await tester.tap(find.text('Display name (required)'));
        await tester.pump();
        expect(focusNode.hasFocus, isTrue);

        final semantic = mode.theme.extension<BirbSemanticColors>()!;
        expect(
          _frameDecoration(tester).border!.top,
          BorderSide(color: semantic.focus, width: BirbBorders.strong),
        );
      });

      testWidgets('uses error caption, boundary, message, and live semantics', (
        tester,
      ) async {
        final semanticsHandle = tester.ensureSemantics();
        try {
          await _pumpField(
            tester,
            mode.theme,
            errorText: 'Correction required',
          );

          final semantic = mode.theme.extension<BirbSemanticColors>()!;
          final label = tester.widget<Text>(
            find.text('Display name (required)'),
          );
          expect(label.style?.color, semantic.errorIndicator);
          expect(
            _frameDecoration(tester).border!.top,
            BorderSide(color: semantic.errorIndicator, width: BirbBorders.thin),
          );
          expect(find.text('Correction required'), findsOneWidget);
          expect(
            find.bySemanticsLabel('Error: Correction required'),
            findsOneWidget,
          );
          final editorSemantics = tester
              .getSemantics(find.byType(MergeSemantics))
              .getSemanticsData();
          expect(editorSemantics.flagsCollection.isTextField, isTrue);
          expect(editorSemantics.flagsCollection.isRequired, Tristate.isTrue);
          expect(editorSemantics.label, 'Display name, required');
          expect(editorSemantics.value, 'Birb');
          expect(
            editorSemantics.validationResult,
            SemanticsValidationResult.invalid,
          );
          expect(editorSemantics.hasAction(SemanticsAction.focus), isTrue);
        } finally {
          semanticsHandle.dispose();
        }
      });

      testWidgets('announces and styles the disabled state', (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        await _pumpField(tester, mode.theme, enabled: false);

        final semantic = mode.theme.extension<BirbSemanticColors>()!;
        final label = tester.widget<Text>(find.text('Display name — Disabled'));
        expect(label.style?.color, semantic.disabled);
        expect(
          tester.widget<TextField>(find.byType(TextField)).enabled,
          isFalse,
        );
        expect(
          _frameDecoration(tester).border!.top,
          BorderSide(color: semantic.disabled, width: BirbBorders.thin),
        );
        final editorSemantics = tester
            .getSemantics(find.byType(MergeSemantics))
            .getSemanticsData();
        expect(editorSemantics.flagsCollection.isEnabled, Tristate.isFalse);
        expect(editorSemantics.flagsCollection.isTextField, isTrue);
        expect(editorSemantics.flagsCollection.isRequired, Tristate.isTrue);
        expect(editorSemantics.label, 'Display name, required');
        semanticsHandle.dispose();
      });

      testWidgets('marks optional fields as not required', (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        try {
          await _pumpOptionalField(tester, mode.theme);
          final editorSemantics = tester
              .getSemantics(find.byType(MergeSemantics))
              .getSemanticsData();
          expect(editorSemantics.flagsCollection.isRequired, Tristate.isFalse);
          expect(editorSemantics.label, 'Display name');
        } finally {
          semanticsHandle.dispose();
        }
      });

      testWidgets('stacks at narrow widths and stays split at wide widths', (
        tester,
      ) async {
        await _pumpField(tester, mode.theme, width: 320);
        expect(_layoutBetweenCaptionAndEditor(tester), isA<Column>());

        await _pumpField(tester, mode.theme, width: 640);
        expect(_layoutBetweenCaptionAndEditor(tester), isA<Row>());

        await _pumpField(
          tester,
          mode.theme,
          width: 640,
          textScaler: const TextScaler.linear(2),
        );
        expect(_layoutBetweenCaptionAndEditor(tester), isA<Column>());
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('participates in validate, save, and autovalidation', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    String? saved;
    await _pumpForm(
      tester,
      formKey: formKey,
      onSaved: (value) => saved = value,
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Name is required'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Birb');
    await tester.pump();
    expect(find.text('Name is required'), findsNothing);
    expect(formKey.currentState!.validate(), isTrue);
    formKey.currentState!.save();
    expect(saved, 'Birb');
  });

  testWidgets('gives explicit errors precedence over validator errors', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await _pumpForm(
      tester,
      formKey: formKey,
      errorText: 'Server rejected this name',
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Server rejected this name'), findsOneWidget);
    expect(find.text('Name is required'), findsNothing);
  });

  testWidgets('synchronizes programmatic controller changes with FormState', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: 'Initial');
    addTearDown(controller.dispose);
    String? saved;
    await _pumpForm(
      tester,
      formKey: formKey,
      controller: controller,
      onSaved: (value) => saved = value,
    );

    controller.text = 'Programmatic';
    await tester.pump();
    formKey.currentState!.save();
    expect(saved, 'Programmatic');

    controller.clear();
    await tester.pump();
    expect(find.text('Name is required'), findsOneWidget);
    expect(formKey.currentState!.validate(), isFalse);
  });

  testWidgets('keeps controller and FormField reset values synchronized', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: 'Initial');
    addTearDown(controller.dispose);
    String? saved;
    await _pumpForm(
      tester,
      formKey: formKey,
      controller: controller,
      onSaved: (value) => saved = value,
    );

    await tester.enterText(find.byType(TextField), 'Edited');
    await tester.pump();
    await _pumpForm(
      tester,
      formKey: formKey,
      controller: controller,
      onSaved: (value) => saved = value,
    );

    formKey.currentState!.reset();
    await tester.pump();
    expect(controller.text, 'Initial');
    expect(formKey.currentState!.validate(), isTrue);
    formKey.currentState!.save();
    expect(saved, 'Initial');
  });

  testWidgets('forwards change and submit callbacks from the editor', (
    tester,
  ) async {
    String? changed;
    String? submitted;
    await _pumpCallbackField(
      tester,
      onChanged: (value) => changed = value,
      onSubmitted: (value) => submitted = value,
    );

    await tester.enterText(find.byType(TextField), 'Edited');
    expect(changed, 'Edited');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submitted, 'Edited');
  });

  testWidgets('disposes owned controller and focus node', (tester) async {
    await _pumpField(tester, BirbTheme.light);
    final editor = tester.widget<TextField>(find.byType(TextField));
    final ownedController = editor.controller!;
    final ownedFocusNode = editor.focusNode!;

    await tester.pumpWidget(const SizedBox());

    expect(
      () => ownedController.addListener(() {}),
      throwsA(isA<FlutterError>()),
    );
    expect(
      () => ownedFocusNode.addListener(() {}),
      throwsA(isA<FlutterError>()),
    );
  });

  testWidgets('borrows controller and focus node across replacement', (
    tester,
  ) async {
    final firstController = TextEditingController(text: 'First');
    final secondController = TextEditingController(text: 'Second');
    final firstFocusNode = FocusNode();
    final secondFocusNode = FocusNode();
    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);
    addTearDown(firstFocusNode.dispose);
    addTearDown(secondFocusNode.dispose);

    await _pumpBorrowedField(
      tester,
      controller: firstController,
      focusNode: firstFocusNode,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller,
      same(firstController),
    );

    await _pumpBorrowedField(
      tester,
      controller: secondController,
      focusNode: secondFocusNode,
    );
    await tester.pump();
    final editor = tester.widget<TextField>(find.byType(TextField));
    expect(editor.controller, same(secondController));
    expect(editor.focusNode, same(secondFocusNode));

    await tester.pumpWidget(const SizedBox());
    expect(() => firstController.text = 'Still owned', returnsNormally);
    expect(() => secondController.text = 'Still owned', returnsNormally);
    expect(() => firstFocusNode.addListener(() {}), returnsNormally);
    expect(() => secondFocusNode.addListener(() {}), returnsNormally);
  });

  testWidgets('detaches replaced controller and focus listeners', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final firstController = TextEditingController(text: 'First');
    final secondController = TextEditingController(text: 'Second');
    final firstFocusNode = FocusNode();
    final secondFocusNode = FocusNode();
    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);
    addTearDown(firstFocusNode.dispose);
    addTearDown(secondFocusNode.dispose);
    String? saved;

    await _pumpBorrowedForm(
      tester,
      formKey: formKey,
      controller: firstController,
      focusNode: firstFocusNode,
      onSaved: (value) => saved = value,
    );
    await _pumpBorrowedForm(
      tester,
      formKey: formKey,
      controller: secondController,
      focusNode: secondFocusNode,
      onSaved: (value) => saved = value,
    );
    await tester.pump();

    firstController.text = 'Stale';
    await tester.pump();
    formKey.currentState!.save();
    expect(saved, 'Second');

    secondController.text = 'Active';
    await tester.pump();
    formKey.currentState!.save();
    expect(saved, 'Active');

    secondFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(secondFocusNode.hasFocus, isTrue);
    expect(
      _frameDecoration(tester).border!.top,
      BorderSide(
        color: BirbSemanticColors.light.focus,
        width: BirbBorders.strong,
      ),
    );

    secondFocusNode.unfocus();
    firstFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(firstFocusNode.hasFocus, isFalse);
    expect(secondFocusNode.hasFocus, isFalse);
    expect(
      _frameDecoration(tester).border!.top,
      BorderSide(
        color: BirbTheme.light.colorScheme.outline,
        width: BirbBorders.thin,
      ),
    );
  });

  group('multiline and read-only editor', () {
    testWidgets('defaults stay single-line and writable', (tester) async {
      await _pumpOptionalField(tester, BirbTheme.light);
      final editor = tester.widget<TextField>(find.byType(TextField));
      expect(editor.maxLines, 1);
      expect(editor.minLines, isNull);
      expect(editor.readOnly, isFalse);
    });

    testWidgets('forwards minLines, maxLines, and readOnly to the editor', (
      tester,
    ) async {
      await _pumpMultilineField(tester);
      final editor = tester.widget<TextField>(find.byType(TextField));
      expect(editor.minLines, 3);
      expect(editor.maxLines, 8);
      expect(editor.readOnly, isFalse);
    });

    testWidgets('a multiline draft wraps and grows to maxLines then scrolls', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pumpMultilineField(tester, controller: controller);
      final emptyHeight = tester.getSize(find.byType(TextField)).height;

      controller.text = List<String>.generate(4, (i) => 'line \$i').join('\n');
      await tester.pumpAndSettle();
      final fourLineHeight = tester.getSize(find.byType(TextField)).height;
      expect(fourLineHeight, greaterThan(emptyHeight));

      controller.text = List<String>.generate(30, (i) => 'line \$i').join('\n');
      await tester.pumpAndSettle();
      final cappedHeight = tester.getSize(find.byType(TextField)).height;
      expect(cappedHeight, greaterThan(fourLineHeight));
      expect(tester.takeException(), isNull);

      controller.text = List<String>.generate(60, (i) => 'line \$i').join('\n');
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(TextField)).height, cappedHeight);
    });

    testWidgets('read-only keeps focus and text while blocking input', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Kept draft');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await _pumpMultilineField(
        tester,
        controller: controller,
        focusNode: focusNode,
        readOnly: true,
      );

      expect(find.text('Kept draft'), findsOneWidget);
      focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);

      await tester.enterText(find.byType(TextField), 'Typed over');
      await tester.pumpAndSettle();
      expect(controller.text, 'Kept draft');
    });

    testWidgets('read-only is semantically distinct from disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpMultilineField(tester, readOnly: true);
      final readOnlyData = tester
          .getSemantics(find.byType(TextField))
          .getSemanticsData();
      expect(readOnlyData.flagsCollection.isEnabled, isNot(Tristate.isFalse));

      await _pumpMultilineField(tester, enabled: false);
      final disabledData = tester
          .getSemantics(find.byType(TextField))
          .getSemanticsData();
      expect(disabledData.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('multiline validation still uses the live correction row', (
      tester,
    ) async {
      await _pumpMultilineField(tester, errorText: 'Reply is too long');
      expect(find.text('Reply is too long'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Error: Reply is too long')),
        isNotNull,
      );
    });

    testWidgets('a borrowed controller survives replacement and is not '
        'disposed', (tester) async {
      final first = TextEditingController(text: 'First draft');
      final second = TextEditingController(text: 'Second draft');
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      await _pumpMultilineField(tester, controller: first);
      expect(find.text('First draft'), findsOneWidget);
      await _pumpMultilineField(tester, controller: second);
      await tester.pumpAndSettle();
      expect(find.text('Second draft'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(first.text, 'First draft');
      expect(second.text, 'Second draft');
    });
  });
}

Future<void> _pumpMultilineField(
  WidgetTester tester, {
  TextEditingController? controller,
  FocusNode? focusNode,
  bool readOnly = false,
  bool enabled = true,
  String? errorText,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: BirbTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 640,
          child: BirbTextFormField(
            label: 'Reply',
            controller: controller,
            focusNode: focusNode,
            readOnly: readOnly,
            enabled: enabled,
            errorText: errorText,
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 8,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpField(
  WidgetTester tester,
  ThemeData theme, {
  FocusNode? focusNode,
  bool enabled = true,
  String? errorText,
  double width = 640,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: BirbTextFormField(
                label: 'Display name',
                initialValue: 'Birb',
                focusNode: focusNode,
                enabled: enabled,
                required: true,
                errorText: errorText,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpOptionalField(WidgetTester tester, ThemeData theme) =>
    tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: BirbTextFormField(label: 'Display name', initialValue: 'Birb'),
        ),
      ),
    );

BoxDecoration _frameDecoration(WidgetTester tester) {
  for (final widget in tester.widgetList<DecoratedBox>(
    find.descendant(
      of: find.byType(BirbTextFormField),
      matching: find.byType(DecoratedBox),
    ),
  )) {
    final decoration = widget.decoration;
    if (decoration is BoxDecoration && decoration.border != null) {
      return decoration;
    }
  }
  throw StateError('Ledger frame not found');
}

Widget _layoutBetweenCaptionAndEditor(WidgetTester tester) {
  final caption = find.textContaining('Display name');
  final editor = find.byType(TextField);
  Widget? sharedLayout;
  caption.evaluate().single.visitAncestorElements((element) {
    if (element.widget is! Column && element.widget is! Row) return true;
    final candidate = find.byWidget(element.widget);
    if (find.descendant(of: candidate, matching: editor).evaluate().isEmpty) {
      return true;
    }
    sharedLayout = element.widget;
    return false;
  });
  if (sharedLayout != null) return sharedLayout!;
  throw StateError('Shared caption/editor layout not found');
}

Future<void> _pumpForm(
  WidgetTester tester, {
  required GlobalKey<FormState> formKey,
  TextEditingController? controller,
  FormFieldSetter<String>? onSaved,
  String? errorText,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: BirbTheme.light,
      home: Scaffold(
        body: Form(
          key: formKey,
          child: BirbTextFormField(
            label: 'Display name',
            controller: controller,
            errorText: errorText,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Name is required' : null,
            onSaved: onSaved,
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpBorrowedField(
  WidgetTester tester, {
  required TextEditingController controller,
  required FocusNode focusNode,
}) => tester.pumpWidget(
  MaterialApp(
    theme: BirbTheme.light,
    home: Scaffold(
      body: BirbTextFormField(
        key: const ValueKey('borrowed-field'),
        label: 'Display name',
        controller: controller,
        focusNode: focusNode,
      ),
    ),
  ),
);

Future<void> _pumpCallbackField(
  WidgetTester tester, {
  required ValueChanged<String> onChanged,
  required ValueChanged<String> onSubmitted,
}) => tester.pumpWidget(
  MaterialApp(
    theme: BirbTheme.light,
    home: Scaffold(
      body: BirbTextFormField(
        label: 'Display name',
        textInputAction: TextInputAction.done,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
      ),
    ),
  ),
);

Future<void> _pumpBorrowedForm(
  WidgetTester tester, {
  required GlobalKey<FormState> formKey,
  required TextEditingController controller,
  required FocusNode focusNode,
  required FormFieldSetter<String> onSaved,
}) => tester.pumpWidget(
  MaterialApp(
    theme: BirbTheme.light,
    home: Scaffold(
      body: Form(
        key: formKey,
        child: BirbTextFormField(
          key: const ValueKey('replacement-field'),
          label: 'Display name',
          controller: controller,
          focusNode: focusNode,
          onSaved: onSaved,
        ),
      ),
    ),
  ),
);
