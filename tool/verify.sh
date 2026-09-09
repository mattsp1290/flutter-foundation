#!/bin/sh
set -eu

repository_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repository_root"

flutter_root=$(flutter --version --machine | sed -n \
  's/^[[:space:]]*"flutterRoot":[[:space:]]*"\([^"]*\)",*$/\1/p')
if [ -z "$flutter_root" ]; then
  printf '%s\n' 'Unable to locate the Flutter SDK root.' >&2
  exit 1
fi
flutter_dart="$flutter_root/bin/cache/dart-sdk/bin/dart"

run_step() {
  step_name=$1
  shift
  printf '%s\n' "==> $step_name"
  "$@"
}

run_package_tests() {
  package_path=$1
  (
    cd "$package_path"
    flutter test
  )
}

run_step 'Resolve locked workspace dependencies' flutter pub get --enforce-lockfile
run_step 'Verify pinned Flutter toolchain' ./tool/verify_toolchain.sh
run_step 'Check Dart formatting' \
  "$flutter_dart" format --output=none --set-exit-if-changed .
run_step 'Audit design-system source' \
  "$flutter_dart" run tool/check_design_system.dart
run_step 'Analyze workspace' flutter analyze
run_step 'Test birb_design_system scaffold' \
  run_package_tests packages/birb_design_system
run_step 'Test birb_appearance scaffold' \
  run_package_tests packages/birb_appearance
run_step 'Test catalog scaffold' run_package_tests examples/catalog
run_step 'Build catalog web runner' sh -c \
  'cd examples/catalog && flutter build web'
