import 'package:flutter/material.dart';

import 'appearance_controller.dart';
import 'appearance_mode.dart';

/// Builds localized text for a storage error.
typedef AppearanceErrorTextBuilder = String Function(
  BuildContext context,
  Object error,
);

/// Builds localized text for the retry action.
typedef AppearanceRetryTextBuilder = String Function(BuildContext context);

/// Three accessible appearance choices backed by a caller-owned controller.
///
/// The selector listens to [controller] but never initializes or disposes it.
/// It stacks its choices at narrow widths and large text scales.
final class AppearanceSelector extends StatelessWidget {
  const AppearanceSelector({
    required this.controller,
    super.key,
    this.systemLabel = 'System',
    this.lightLabel = 'Light',
    this.darkLabel = 'Dark',
    this.errorTextBuilder,
    this.retryTextBuilder,
  });

  final AppearanceController controller;
  final String systemLabel;
  final String lightLabel;
  final String darkLabel;
  final AppearanceErrorTextBuilder? errorTextBuilder;
  final AppearanceRetryTextBuilder? retryTextBuilder;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _choices(context),
        if (controller.isInitializing)
          const _AppearanceProgress(
            key: ValueKey<String>('appearance-initializing'),
            label: 'Loading appearance',
          ),
        if (controller.isSavePending)
          _AppearanceProgress(
            key: const ValueKey<String>('appearance-saving'),
            label: 'Saving ${_labelFor(controller.selectedMode)}',
          ),
        if (controller.saveError case final error?)
          _error(
            context,
            error: error,
            fallback: 'Could not save appearance.',
            canRetry: true,
          )
        else if (controller.readError case final error?)
          _error(
            context,
            error: error,
            fallback: 'Could not load appearance.',
            canRetry: false,
          ),
      ],
    ),
  );

  Widget _choices(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final labelStyle = Theme.of(context).textTheme.bodyLarge;
      final fontSize = labelStyle?.fontSize ?? 16;
      final largeText =
          MediaQuery.textScalerOf(context).scale(fontSize) > fontSize * 1.5;
      final stack = constraints.maxWidth < 480 || largeText;
      final choices = AppearanceMode.values
          .map(
            (mode) => RadioListTile<AppearanceMode>(
              key: ValueKey<AppearanceMode>(mode),
              value: mode,
              title: Text(_labelFor(mode)),
              selected: controller.selectedMode == mode,
              enabled:
                  !(controller.isSavePending &&
                      controller.selectedMode == mode),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          )
          .toList(growable: false);
      return RadioGroup<AppearanceMode>(
        groupValue: controller.selectedMode,
        onChanged: (mode) {
          if (mode != null) controller.setMode(mode);
        },
        child: stack
            ? Column(children: choices)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: choices
                    .map((choice) => Expanded(child: choice))
                    .toList(growable: false),
              ),
      );
    },
  );

  Widget _error(
    BuildContext context, {
    required Object error,
    required String fallback,
    required bool canRetry,
  }) => Semantics(
    key: ValueKey<String>(
      canRetry ? 'appearance-save-error' : 'appearance-read-error',
    ),
    liveRegion: true,
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: <Widget>[
        Text(errorTextBuilder?.call(context, error) ?? fallback),
        if (canRetry)
          TextButton(
            onPressed: controller.retry,
            child: Text(retryTextBuilder?.call(context) ?? 'Retry'),
          ),
      ],
    ),
  );

  String _labelFor(AppearanceMode mode) => switch (mode) {
    AppearanceMode.system => systemLabel,
    AppearanceMode.light => lightLabel,
    AppearanceMode.dark => darkLabel,
  };
}

final class _AppearanceProgress extends StatelessWidget {
  const _AppearanceProgress({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: label,
    child: ExcludeSemantics(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: <Widget>[
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          Text(label),
        ],
      ),
    ),
  );
}
