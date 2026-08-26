#!/bin/bash
# Chart Monitor APK Build-Skript
set -e
cd "$(dirname "$0")"

# Version aus pubspec.yaml lesen (Single Source of Truth)
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)
BUILD=$(grep '^version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f2)

echo "=== Chart Monitor v${VERSION}+${BUILD} – APK Build ==="

if ! command -v flutter &>/dev/null; then
    echo "FEHLER: flutter nicht gefunden."
    exit 1
fi

if [ ! -f "android/key.properties" ]; then
    echo "FEHLER: android/key.properties nicht gefunden."
    echo "  Ohne diese Datei wird die APK mit dem Debug-Zertifikat signiert"
    echo "  und kann nicht als Update installiert werden."
    exit 1
fi

echo "→ Abhängigkeiten holen..."
flutter pub get

echo "→ Lokalisierungsdateien generieren..."
flutter gen-l10n

echo "→ Analyse..."
flutter analyze --no-pub

echo "→ Release APK bauen..."
flutter build apk --release

APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
APK_DST="chart-monitor-${VERSION}.apk"

if [ -f "$APK_SRC" ]; then
    cp "$APK_SRC" "$APK_DST"
    cp "$APK_SRC" "chart-monitor-android.apk"
    echo ""
    echo "✓ APK erstellt: $APK_DST"
    echo "✓ Release-Asset:  chart-monitor-android.apk"
    echo "  Version: ${VERSION} (Build ${BUILD})"
    ls -lh "$APK_DST" "chart-monitor-android.apk"
else
    echo "FEHLER: APK nicht gefunden unter $APK_SRC"
    exit 1
fi
