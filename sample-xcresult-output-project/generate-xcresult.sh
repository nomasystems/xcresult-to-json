#!/usr/bin/env bash

set -euo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
test_resources_dir="$script_dir/../Tests/XCResultToJsonTests/Resources/xcresult"

xcodebuild \
    clean \
    build \
    -project Sample.xcodeproj \
    -scheme Sample  \
    -destination "platform=macOS" \
    -resultBundlePath "$test_resources_dir/build.xcresult"

xcodebuild \
    clean \
    test \
    -project Sample.xcodeproj \
    -scheme Sample  \
    -destination "platform=macOS" \
    -resultBundlePath "$test_resources_dir/test.xcresult"
