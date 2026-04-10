#!/bin/bash
set -euo pipefail

APP_NAME="TranslateLLM"
rm -rf .build build
swift build -c release
BUILD_DIR=$(swift build -c release --show-bin-path 2>&1 | tail -1)
APP_DIR="build/$APP_NAME.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/"

# Copy resource bundle for localization
BUNDLE_RESOURCE=$(find .build -type d -name "TranslateLLM_TranslateLLM.bundle" | head -1)
if [ -n "$BUNDLE_RESOURCE" ]; then
    cp -r "$BUNDLE_RESOURCE" "$APP_DIR/Contents/Resources/"
fi

cat > "$APP_DIR/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>TranslateLLM</string>
    <key>CFBundleIdentifier</key>
    <string>com.translate.llm</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>TranslateLLM</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>ko</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>ko</string>
        <string>en</string>
    </array>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || true

echo ""
echo "Build complete: $APP_DIR"
echo ""
echo "To run:     open build/$APP_NAME.app"
echo "To install: cp -r build/$APP_NAME.app /Applications/"
