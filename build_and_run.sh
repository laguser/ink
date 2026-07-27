#!/bin/bash
set -eou pipefail

DIST_DIR="$(dirname "$0")/dist"
APP_SRC="$(dirname "$0")/.build/release"
APP_DIR="$DIST_DIR/Ink.app"

echo "Building..."
swift build -c release

echo "Creating .app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$APP_SRC/Ink" "$APP_DIR/Contents/MacOS/Ink"
chmod +x "$APP_DIR/Contents/MacOS/Ink"

if [ -d "$APP_SRC/Ink_Ink.bundle" ]; then
  cp -R "$APP_SRC/Ink_Ink.bundle/"* "$APP_DIR/Contents/Resources/"
fi

# Generate Info.plist
/usr/libexec/PlistBuddy -c "Add CFBundleExecutable string Ink" \
  -c "Add CFBundleIdentifier string com.ink.app" \
  -c "Add CFBundleName string Ink" \
  -c "Add CFBundleVersion string 1.1.0" \
  -c "Add CFBundleShortVersionString string 1.1.0" \
  -c "Add CFBundlePackageType string APPL" \
  -c "Add LSMinimumSystemVersion string 14.0" \
  -c "Add NSHighResolutionCapable bool true" \
  -c "Add CFBundleIconFile string Ink" \
  "$APP_DIR/Contents/Info.plist" 2>/dev/null || true

echo "Creating DMG..."
DMG_TMP="/tmp/ink-tmp.dmg"
DMG_FINAL="$DIST_DIR/Ink.dmg"
rm -f "$DMG_TMP" "$DMG_FINAL"

hdiutil create -srcfolder "$DIST_DIR" -volname "Ink" -fs HFS+ -format UDRW -ov "$DMG_TMP"
MOUNT=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TMP" | grep "/Volumes/Ink" | sed 's/.*\/Volumes/\/Volumes/' | sed 's/ *$//' | head -1)

rm -rf "$MOUNT/.DS_Store"
ln -sf /Applications "$MOUNT/Applications"

mkdir -p "$MOUNT/.background"
if [ -f "$(dirname "$0")/github/dmg_bg.png" ]; then
  cp "$(dirname "$0")/github/dmg_bg.png" "$MOUNT/.background/background.png"
fi

cp "$APP_DIR/Contents/Resources/Ink.icns" "$MOUNT/.VolumeIcon.icns" 2>/dev/null || true
SetFile -a C "$MOUNT" 2>/dev/null || true

hdiutil detach "$MOUNT" -quiet
hdiutil convert "$DMG_TMP" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL"
rm -f "$DMG_TMP"

echo "Done: $(ls -lh "$DMG_FINAL" | awk '{print $5}')"
