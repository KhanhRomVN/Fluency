#!/usr/bin/env bash

if [ "$(basename "$PWD")" = 'scripts' ]; then cd ..; fi

flutter test --coverage
lcov --remove coverage/lcov.info \
  'lib/**/*.g.dart' \
  'lib/**/*.freezed.dart' \
  'lib/generated_plugin_registrant.dart' \
  -o coverage/new_lcov.info
genhtml coverage/new_lcov.info -o coverage/html
