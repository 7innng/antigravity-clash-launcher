#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
destination="$root/dist"
app="$destination/Antigravity-Clash.app"

if ! xcrun --find swiftc >/dev/null 2>&1; then
    printf '%s\n' 'Install the Xcode Command Line Tools: xcode-select --install' >&2
    exit 1
fi

mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$root/Resources/Info.plist" "$app/Contents/Info.plist"
cp "$root/Resources/Launcher.icns" "$app/Contents/Resources/Launcher.icns"
cp -R "$root/Resources/en.lproj" "$root/Resources/zh-Hans.lproj" "$app/Contents/Resources/"

MACOSX_DEPLOYMENT_TARGET=14.0 xcrun swiftc -O -framework AppKit \
    "$root/Sources/Launcher.swift" -o "$app/Contents/MacOS/AntigravityClashLauncher"

codesign --force --sign - "$app"
printf '\n%s\n' "$app"
