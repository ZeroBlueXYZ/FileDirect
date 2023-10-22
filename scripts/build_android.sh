#!/bin/bash
set -e

VERSION="$1"
if ! [ -n "$VERSION" ]; then
    echo "Version cannot be empty"
    exit 1
fi

DEBUG_INFO_DIR=./debug_info/$VERSION/android

mkdir -p $DEBUG_INFO_DIR
flutter build appbundle --obfuscate --split-debug-info=$DEBUG_INFO_DIR
