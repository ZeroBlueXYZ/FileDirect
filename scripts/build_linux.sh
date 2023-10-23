#!/bin/bash
set -e

VERSION="$1"
if ! [ -n "$VERSION" ]; then
    echo "Version cannot be empty"
    exit 1
fi

DEBUG_INFO_DIR=./debug_info/$VERSION/linux
BUNDLE_DIR=./build/linux/x64/release/bundle/

mkdir -p $DEBUG_INFO_DIR
flutter build linux --obfuscate --split-debug-info=$DEBUG_INFO_DIR
pushd $BUNDLE_DIR
zip -r "../anysend-$VERSION.zip" *
popd
