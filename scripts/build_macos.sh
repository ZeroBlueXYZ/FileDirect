#!/bin/bash
set -e

VERSION="$1"
if ! [ -n "$VERSION" ]; then
    echo "Version cannot be empty"
    exit 1
fi

DEBUG_INFO_DIR=./debug_info/$VERSION/macos

mkdir -p $DEBUG_INFO_DIR
flutter build macos --obfuscate --split-debug-info=$DEBUG_INFO_DIR
