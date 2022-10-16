#!/bin/bash

flutter build appbundle

if ! grep -q 'const bool isFree = true;' ./lib/main.dart; then
    echo "Error initial configuration is not set for free app!"
    exit 1
fi

mv ./build/app/outputs/bundle/release/app-release.aab ./build/app/outputs/bundle/release/app-free.aab

sed 's/const bool isFree = true;/const bool isFree = false;/' ./lib/main.dart >> tmp.dart
mv tmp.dart ./lib/main.dart

if ! grep -q 'const bool isFree = false;' ./lib/main.dart; then
    echo "Error initial configuration is not set for PRO app!"
    exit 1
fi

flutter build appbundle

mv ./build/app/outputs/bundle/release/app-release.aab ./build/app/outputs/bundle/release/app-pro.aab

sed 's/const bool isFree = false;/const bool isFree = true;/' ./lib/main.dart>> tmp.dart
mv tmp.dart ./lib/main.dart