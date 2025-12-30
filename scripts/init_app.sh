#!/usr/bin/env bash

if [ "$(basename "$PWD")" = 'scripts' ]; then cd ..; fi

flutter clean
sh scripts/clean_ios.sh
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
sh scripts/format.sh
