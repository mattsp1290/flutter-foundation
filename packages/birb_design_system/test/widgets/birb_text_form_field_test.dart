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
        expect(editorSemantics.label, 'Display name, required');
        semanticsHandle.dispose();
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
