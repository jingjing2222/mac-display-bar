#!/usr/bin/env bash
set -euo pipefail

APP="${APP:-$PWD/dist/homebrew/build/Release/macDisplayBar.app}"
ENTITLEMENTS="${ENTITLEMENTS:-$PWD/macos/com.jingjing2222.macdisplaybar-macOS/com.jingjing2222.macdisplaybar.entitlements}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application: HyeongJeong Kim (2YVR9BL7B6)}"
VERSION="${VERSION:?VERSION is required}"
ZIP="$PWD/dist/homebrew/macDisplayBar-$VERSION.zip"

require_env() {
  local name="$1"

  if [ -z "${!name:-}" ]; then
    echo "::error::$name is required"
    exit 1
  fi
}

decode_base64() {
  if ! printf '%s' "$1" | base64 --decode 2>/dev/null; then
    printf '%s' "$1" | base64 -D
  fi
}

require_env DEVELOPER_ID_CERTIFICATE_BASE64
require_env DEVELOPER_ID_CERTIFICATE_PASSWORD
require_env DEVELOPER_ID_PROVISIONING_PROFILE_BASE64
require_env APPLE_ID
require_env APPLE_TEAM_ID
require_env APPLE_APP_SPECIFIC_PASSWORD

if [ ! -d "$APP" ]; then
  echo "::error::App not found: $APP"
  exit 1
fi

mkdir -p "$PWD/dist/homebrew"

KEYCHAIN_PASSWORD="$(openssl rand -hex 24)"
KEYCHAIN_PATH="$RUNNER_TEMP/mac-display-bar-signing.keychain-db"
CERT_PATH="$RUNNER_TEMP/developer-id.p12"
PROFILE_PATH="$RUNNER_TEMP/mac-display-bar.provisionprofile"

decode_base64 "$DEVELOPER_ID_CERTIFICATE_BASE64" > "$CERT_PATH"
decode_base64 "$DEVELOPER_ID_PROVISIONING_PROFILE_BASE64" > "$PROFILE_PATH"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security import "$CERT_PATH" \
  -k "$KEYCHAIN_PATH" \
  -P "$DEVELOPER_ID_CERTIFICATE_PASSWORD" \
  -T /usr/bin/codesign \
  -T /usr/bin/security
security list-keychains -d user -s "$KEYCHAIN_PATH"
security set-key-partition-list \
  -S apple-tool:,apple:,codesign: \
  -s \
  -k "$KEYCHAIN_PASSWORD" \
  "$KEYCHAIN_PATH"

cp "$PROFILE_PATH" "$APP/Contents/embedded.provisionprofile"

if [ -d "$APP/Contents/Frameworks" ]; then
  find "$APP/Contents/Frameworks" \
    -type f \( -perm -111 -o -name '*.dylib' -o -name '*.so' \) \
    -print0 |
    while IFS= read -r -d '' file; do
      codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$file"
    done

  find "$APP/Contents/Frameworks" \
    -type d \
    -name '*.framework' \
    -maxdepth 3 \
    -print0 |
    while IFS= read -r -d '' framework; do
      codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$framework"
    done
fi

if [ -d "$APP/Contents/Resources" ]; then
  find "$APP/Contents/Resources" \
    -type d \( -name '*.bundle' -o -name '*.appex' \) \
    -print0 |
    while IFS= read -r -d '' bundle; do
      codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$bundle"
    done
fi

codesign \
  --force \
  --options runtime \
  --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$SIGNING_IDENTITY" \
  "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

xcrun notarytool submit "$ZIP" \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD" \
  --wait

xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
spctl --assess --type execute --verbose=4 "$APP"

rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

SHA256="$(shasum -a 256 "$ZIP" | awk '{print $1}')"

echo "zip_path=$ZIP" >> "$GITHUB_OUTPUT"
echo "sha256=$SHA256" >> "$GITHUB_OUTPUT"
