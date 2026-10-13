#!/usr/bin/env bash
# Build and Package script for ParallelsLite on macOS
set -e

echo "=== Building ParallelsLite for macOS ==="

# 1. Compile Swift package in release mode
swift build -c release

# 2. Locate built executable
BIN_PATH="$(swift build -c release --show-bin-path)/ParallelsLite"
APP_BUNDLE="ParallelsLite.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Creating ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

# 3. Copy executable
cp "${BIN_PATH}" "${MACOS_DIR}/ParallelsLite"

# 4. Generate Info.plist
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ParallelsLite</string>
    <key>CFBundleIdentifier</key>
    <string>com.mandiri.parallels.lite</string>
    <key>CFBundleName</key>
    <string>ParallelsLite</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# 5. Sign with Virtualization entitlements
if [ -f "VirtualizationApp.entitlements" ]; then
    echo "Signing app with Virtualization entitlements..."
    codesign --force --deep --sign - --entitlements VirtualizationApp.entitlements "${APP_BUNDLE}"
fi

echo "=== Build complete! Run the app with: open ${APP_BUNDLE} ==="
