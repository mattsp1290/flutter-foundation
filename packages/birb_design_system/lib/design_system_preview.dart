/// Stable preview fixtures for design-system catalogs and tests.
///
/// Render [BirbThemeHarness] or [BirbReviewHarness] below a [MaterialApp]
/// configured with a Birb [ThemeData]. Fixture inventory names and lookup keys
/// are stable test and catalog APIs.
///
/// [BirbReviewHarness] is a simulated review host: it has no service
/// dependency, sends nothing, and says so on screen.
library;

import 'package:flutter/material.dart';

export 'src/preview/birb_review_fixtures.dart';
export 'src/preview/birb_review_harness.dart';
export 'src/preview/birb_review_state.dart';
export 'src/preview/birb_theme_harness.dart';
