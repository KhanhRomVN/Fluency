#!/usr/bin/env bash

if [ "$(basename "$PWD")" = 'scripts' ]; then cd ..; fi

flutter pub run build_runner build --delete-conflicting-outputs
dart format -l 120 lib test
