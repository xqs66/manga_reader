#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PUBSPEC="$BASE_DIR/pubspec.yaml"
BUILD_DIR="$BASE_DIR/build_output"
BASE_VERSION="1.0.0"
BUILD_TIME=$(date +%Y%m%d%H)
VERSION="$BASE_VERSION+$BUILD_TIME"
HOST_OS=$(uname -s)

echo "=== 漫画阅读器打包脚本 ==="
echo "版本: $VERSION"
echo "当前系统: $HOST_OS"
echo ""

# ── Update version ──
sed -i "s/^version: .*/version: $VERSION/" "$PUBSPEC"
restore_version() {
  echo "还原版本号..."
  sed -i "s/^version: .*/version: $BASE_VERSION/" "$PUBSPEC"
}
trap restore_version EXIT

# ── Build output dir ──
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ── Helper ──
win_path() {
  echo "$1" | sed 's|^/\(\w\)/|\1:/|' | sed 's|/|\\|g'
}

# ── Android ──
echo "[1/4] 打包 Android (分 ABI)..."
cd "$BASE_DIR"
if flutter build apk --release --split-per-abi; then
  for f in build/app/outputs/flutter-apk/app-*-release.apk; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .apk)
    cp "$f" "$BUILD_DIR/${name}_${BUILD_TIME}.apk"
    echo "  → ${name}_${BUILD_TIME}.apk"
  done
else
  echo "  Android 打包失败，跳过"
fi

# ── Windows ──
echo "[2/4] 打包 Windows..."
cd "$BASE_DIR"
if flutter build windows --release; then
  cp build/windows/x64/runner/Release/manga_reader.exe "$BUILD_DIR/manga_reader-windows-x64_${BUILD_TIME}.exe"
  echo "  → manga_reader-windows-x64_${BUILD_TIME}.exe"
else
  echo "  Windows 打包失败，跳过"
fi
cd "$BASE_DIR"

# ── Linux (only on Linux host) ──
echo "[3/4] 打包 Linux..."
cd "$BASE_DIR"
if [ "$HOST_OS" = "Linux" ]; then
  if flutter build linux --release; then
    cd build/linux/x64/release/bundle
    tar -cf "$BUILD_DIR/manga_reader-linux-x64_${BUILD_TIME}.tar" *
    echo "  → manga_reader-linux-x64_${BUILD_TIME}.tar"
    cd "$BASE_DIR"
  else
    echo "  Linux 打包失败，跳过"
    cd "$BASE_DIR"
  fi
else
  echo "  跳过（仅 Linux 支持）"
fi

# ── macOS (only on macOS host) ──
echo "[4/4] 打包 macOS..."
cd "$BASE_DIR"
if [ "$HOST_OS" = "Darwin" ]; then
  if flutter build macos --release; then
    cd build/macos/Build/Products/Release
    tar -cf "$BUILD_DIR/manga_reader-macos_${BUILD_TIME}.tar" manga_reader.app
    echo "  → manga_reader-macos_${BUILD_TIME}.tar"
    cd "$BASE_DIR"
  else
    echo "  macOS 打包失败，跳过"
    cd "$BASE_DIR"
  fi
else
  echo "  跳过（仅 macOS 支持）"
fi

echo ""
echo "=== 打包完成 ==="
ls -lh "$BUILD_DIR" 2>/dev/null || echo "(无产物)"
echo ""
read -p "按回车退出..."
