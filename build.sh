#!/bin/bash
set -euo pipefail

# Build script for 今天没白活 macOS app.
# Uses swiftc directly (SPM manifest broken on CLT-only installs).

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

APP_NAME_DISPLAY="今天没白活"
APP_NAME_INTERNAL="JintianMeiBaihuo"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME_DISPLAY.app"
SRC_DIR="$PROJECT_DIR/Sources/JintianMeiBaihuo"
BIN_OUT="$BUILD_DIR/$APP_NAME_INTERNAL"

echo "→ 清理旧构建产物"
rm -rf "$APP_BUNDLE" "$BIN_OUT"
mkdir -p "$BUILD_DIR"

echo "→ swiftc 编译 (release)"

SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)

SOURCES=(
    "$SRC_DIR/Todo.swift"
    "$SRC_DIR/TodoStore.swift"
    "$SRC_DIR/PixelTheme.swift"
    "$SRC_DIR/PixelCheckbox.swift"
    "$SRC_DIR/TodoRow.swift"
    "$SRC_DIR/ContentView.swift"
    "$SRC_DIR/App.swift"
)

xcrun swiftc \
    -O \
    -target arm64-apple-macos13.0 \
    -sdk "$SDK_PATH" \
    -framework AppKit \
    -framework SwiftUI \
    -framework Foundation \
    -framework Combine \
    -o "$BIN_OUT" \
    "${SOURCES[@]}"

echo "→ 组装 .app bundle"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_OUT" "$APP_BUNDLE/Contents/MacOS/$APP_NAME_INTERNAL"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME_INTERNAL"

cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"

echo ""
echo "✓ 构建完成: $APP_BUNDLE"
echo "  启动: open \"$APP_BUNDLE\""
