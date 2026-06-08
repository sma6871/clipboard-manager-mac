#!/bin/bash
set -e

# Change directory to script's directory
cd "$(dirname "$0")"

echo "🧹 Cleaning previous builds..."
rm -rf ClipboardManager ClipboardManager.app ClipboardManager.dmg dist .module-cache

echo "🚀 Compiling Swift executable..."
swiftc -sdk $(xcrun --show-sdk-path) -target arm64-apple-macosx11.0 -module-cache-path .module-cache main.swift -o ClipboardManager

echo "📦 Packaging App Bundle..."
mkdir -p ClipboardManager.app/Contents/MacOS
cp ClipboardManager ClipboardManager.app/Contents/MacOS/
cp Info.plist ClipboardManager.app/Contents/

echo "🎨 Generating App Icon (.icns)..."
mkdir -p AppIcon.iconset
sips -s format png -z 16 16   icon.png --out AppIcon.iconset/icon_16x16.png > /dev/null
sips -s format png -z 32 32   icon.png --out AppIcon.iconset/icon_16x16@2x.png > /dev/null
sips -s format png -z 32 32   icon.png --out AppIcon.iconset/icon_32x32.png > /dev/null
sips -s format png -z 64 64   icon.png --out AppIcon.iconset/icon_32x32@2x.png > /dev/null
sips -s format png -z 128 128 icon.png --out AppIcon.iconset/icon_128x128.png > /dev/null
sips -s format png -z 256 256 icon.png --out AppIcon.iconset/icon_128x128@2x.png > /dev/null
sips -s format png -z 256 256 icon.png --out AppIcon.iconset/icon_256x256.png > /dev/null
sips -s format png -z 512 512 icon.png --out AppIcon.iconset/icon_256x256@2x.png > /dev/null
sips -s format png -z 512 512 icon.png --out AppIcon.iconset/icon_512x512.png > /dev/null
sips -s format png -z 1024 1024 icon.png --out AppIcon.iconset/icon_512x512@2x.png > /dev/null
iconutil -c icns AppIcon.iconset
mkdir -p ClipboardManager.app/Contents/Resources
cp AppIcon.icns ClipboardManager.app/Contents/Resources/
rm -rf AppIcon.iconset AppIcon.icns

echo "✍️  Ad-hoc signing the App Bundle..."
codesign --force --deep --sign - ClipboardManager.app

echo "💾 Preparing DMG layout with Applications shortcut..."
mkdir -p dist
cp -R ClipboardManager.app dist/
ln -s /Applications dist/Applications

echo "💾 Creating DMG installer..."
hdiutil create -volname "ClipboardManager" -srcfolder dist -ov -format UDZO ClipboardManager.dmg

echo "🧹 Cleaning up temporary layout..."
rm -rf dist

echo "✅ Build completed successfully!"
echo "📍 App Bundle: $(pwd)/ClipboardManager.app"
echo "📍 DMG Installer: $(pwd)/ClipboardManager.dmg"
