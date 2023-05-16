#!/bin/sh

set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
project_dir="$(dirname "$script_dir")"

cd "$project_dir"

executable_product="xcresult-to-json"
signing_identity="Developer ID Application: CUNNINGO S.L.U. (TQL2DL7S9V)"
notarytool_keychain_profile="AC_PASSWORD"

# Build universal binary
swift build -c release --arch arm64 --arch x86_64 --product "$executable_product"
# Ask swift build for the output directory
built_executable_dir=$(swift build -c release --arch arm64 --arch x86_64 --product "$executable_product" --show-bin-path)
built_executable="$built_executable_dir/$executable_product"
echo "$built_executable"

codesign --timestamp --options=runtime -s "$signing_identity" "$built_executable"
product_zip="$executable_product.zip"
ditto -c -k "$built_executable" "$product_zip"
xcrun notarytool submit "$product_zip" --keychain-profile $notarytool_keychain_profile --wait
