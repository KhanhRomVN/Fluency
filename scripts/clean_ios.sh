#!/usr/bin/env bash

if [ "$(basename "$PWD")" = 'scripts' ]; then cd ..; fi

rm -rf ios/Pods
rm -rf ios/Podfile.lock
