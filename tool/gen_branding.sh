#!/usr/bin/env bash
# Regenerates launcher icons (prod + Android dev flavor with a DEV badge) and the native splash (T9.2.01).
# flutter_launcher_icons runs as a global tool (it pins cli_util <0.5, which conflicts with melos in the
# workspace); flutter_native_splash is a dev dependency of the app (it needs the Flutter SDK).
#   Needs: rsvg-convert (brew install librsvg) to re-render assets/branding/*.svg → *.png.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
fvm dart pub global activate flutter_launcher_icons 0.14.4 >/dev/null

if command -v rsvg-convert >/dev/null; then
  for f in app/assets/branding/*.svg; do rsvg-convert "$f" -o "${f%.svg}.png"; done
  # The store icon must not have an alpha channel.
  python3 -c "from PIL import Image; [Image.open(p).convert('RGB').save(p) for p in ['app/assets/branding/icon.png','app/assets/branding/icon_tinted.png']]" 2>/dev/null ||
    echo "⚠️  PIL missing: make sure icon.png has no alpha channel"
fi

(cd app && fvm dart pub global run flutter_launcher_icons -f flutter_launcher_icons.yaml)

# Android dev flavor: generate into a scratch project, then copy into app/android/app/src/dev/res.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/android/app/src/main/res" "$TMP/assets/branding"
cp app/assets/branding/{icon_legacy_dev,adaptive_background,adaptive_foreground_dev,adaptive_monochrome}.png "$TMP/assets/branding/"
printf 'name: dev_icons\nenvironment:\n  sdk: ^3.0.0\n' > "$TMP/pubspec.yaml"
printf '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n  <application android:icon="@mipmap/ic_launcher"/>\n</manifest>\n' \
  > "$TMP/android/app/src/main/AndroidManifest.xml"
cat > "$TMP/flutter_launcher_icons.yaml" <<'YAML'
flutter_launcher_icons:
  android: true
  ios: false
  min_sdk_android: 24
  image_path: "assets/branding/icon_legacy_dev.png"
  adaptive_icon_background: "assets/branding/adaptive_background.png"
  adaptive_icon_foreground: "assets/branding/adaptive_foreground_dev.png"
  adaptive_icon_monochrome: "assets/branding/adaptive_monochrome.png"
YAML
(cd "$TMP" && fvm dart pub global run flutter_launcher_icons -f flutter_launcher_icons.yaml)
rm -rf "$ROOT/app/android/app/src/dev/res"
mkdir -p "$ROOT/app/android/app/src/dev/res"
cp -R "$TMP/android/app/src/main/res/." "$ROOT/app/android/app/src/dev/res/"

(cd app && fvm dart run flutter_native_splash:create --path=flutter_native_splash.yaml)
# Both generators touch files we keep hand-maintained: flutter_launcher_icons 0.14.4 corrupts
# ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS in the Xcode project and
# flutter_native_splash reformats Info.plist (only to add UIStatusBarHidden=false). Restore both.
git checkout -- app/ios/Runner.xcodeproj/project.pbxproj app/ios/Runner/Info.plist
echo "✅ Icons and splash regenerated."
