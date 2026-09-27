# Birb code editor qualification

This package contains the qualified W1 engine scaffold, not a usable editor release.
No public product API is exported. The existing `birb_design_system` editor is
unchanged.

Run `flutter test` from this directory. The exact-source and initial view probes
pass against the immutable owned fork pin in `pubspec.yaml`. The unpatched
release failed mixed-separator fidelity; that requirement remains in the suite.

The temporary `BirbEditorQualification` widget is exported solely for catalog
qualification and will be replaced by the production contract in W2/W3.
It has no stable API or delivery claim.

See [engine evidence](../../docs/editor-engine-qualification.md) for the failure,
dependency provenance and remaining qualification work.
