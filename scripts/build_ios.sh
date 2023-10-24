#!/bin/bash
set -e

BUILD_NAME="$1"
BUILD_NUMBER="$2"
if ! { [ -n "$BUILD_NAME" ] && [ -n "$BUILD_NUMBER" ]; }; then
    echo "Both build name and build number must be specified"
    exit 1
fi

DEBUG_INFO_DIR=./debug_info/$BUILD_NAME+$BUILD_NUMBER/ios

mkdir -p $DEBUG_INFO_DIR
flutter build ipa \
    --obfuscate \
    --split-debug-info=$DEBUG_INFO_DIR \
    --build-name=$BUILD_NAME \
    --build-number=$BUILD_NUMBER
