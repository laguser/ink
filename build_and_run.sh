#!/bin/bash
set -e

APP_BUNDLE="/tmp/Ink.app"

echo "Building..."
swift build

echo "Packaging app bundle..."
pkill -f "Ink" 2>/dev/null || true
sleep 1

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp .build/arm64-apple-macosx/debug/Ink "$APP_BUNDLE/Contents/MacOS/Ink"
cp Sources/Ink/Resources/Ink.icns "$APP_BUNDLE/Contents/Resources/Ink.icns"
cp -r .build/arm64-apple-macosx/debug/Ink_Ink.bundle "$APP_BUNDLE/Contents/Resources/Ink_Ink.bundle"

cat > "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>Ink</string>
    <key>CFBundleIdentifier</key><string>com.ink.app</string>
    <key>CFBundleName</key><string>Ink</string>
    <key>CFBundleDisplayName</key><string>Ink</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1.0.0</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>CFBundleIconFile</key><string>Ink</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
</dict>
</plist>
PLIST

echo "Launching..."
open "$APP_BUNDLE"
echo "Done."
