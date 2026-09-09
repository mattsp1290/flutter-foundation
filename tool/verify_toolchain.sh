#!/bin/sh
set -eu

machine_output=$(flutter --version --machine)

read_field() {
  field_name=$1
  printf '%s\n' "$machine_output" | sed -n \
    "s/^[[:space:]]*\"$field_name\":[[:space:]]*\"\([^\"]*\)\",*$/\1/p"
}

verify_field() {
  field_name=$1
  expected_value=$2
  actual_value=$(read_field "$field_name")
  if [ "$actual_value" != "$expected_value" ]; then
    printf '%s\n' \
      "$field_name: expected $expected_value, got ${actual_value:-<missing>}" >&2
    return 1
  fi
}

failed=false
verify_field frameworkVersion 3.47.1 || failed=true
verify_field frameworkRevision \
  6655482ec06e547f90abf8ae7590466f4415978d || failed=true
verify_field engineRevision \
  5d531788691ec3404cac0cee66ead4007b177363 || failed=true
verify_field dartSdkVersion 3.13.1 || failed=true

if [ "$failed" = true ]; then
  printf '%s\n' 'Pinned Flutter toolchain verification failed.' >&2
  exit 1
fi

printf '%s\n' \
  'Verified Flutter 3.47.1, framework 6655482ec06e547f90abf8ae7590466f4415978d, and Dart 3.13.1.'
