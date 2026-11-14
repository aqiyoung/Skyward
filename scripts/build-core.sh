#!/bin/bash
# 只做一件事：交叉编译 Rust 内核并把 .so 放进 app/src/main/jniLibs/arm64-v8a。
# Gradle（cargoBuild task）与 build.sh（快速通道）都调这一份，避免两处 toolchain 配置漂移。
set -euo pipefail

ROOT=${SKYWARD_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
CORE=$ROOT/core
OUT=$ROOT/app/src/main/jniLibs/arm64-v8a

SDK=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-/tmp/rust_android_env/sdk}}
NDK_VER_DEFAULT=28.2.13676358
API_LEVEL=${ANDROID_API_LEVEL:-26}

NDK=${ANDROID_NDK_HOME:-}
if [ -z "$NDK" ]; then
  if [ -d "$SDK/ndk/$NDK_VER_DEFAULT" ]; then
    NDK="$SDK/ndk/$NDK_VER_DEFAULT"
  else
    NDK=$(ls -d "$SDK"/ndk/*/ 2>/dev/null | sort -V | tail -1 | sed 's:/$::' || true)
  fi
fi
[ -n "$NDK" ] && [ -d "$NDK" ] || { echo "MISSING: NDK ($NDK)"; exit 1; }

LLVM=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin
CLANG=${ANDROID_CLANG:-$LLVM/aarch64-linux-android${API_LEVEL}-clang}
LLVM_AR=$LLVM/llvm-ar
[ -x "$CLANG" ] || { echo "MISSING: $CLANG"; exit 1; }

# toolchain：默认 +1.99.0（android std 装在这），RUST_TC 可覆盖；置空则用当前默认
if [ "${RUST_TC+x}" = x ]; then
  if [ -n "$RUST_TC" ]; then TC_ARGS=("+$RUST_TC"); else TC_ARGS=(); fi
else
  TC_ARGS=("+1.99.0")
fi

export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$CLANG"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_AR="$LLVM_AR"
export CC_aarch64_linux_android="$CLANG"
export AR_aarch64_linux_android="$LLVM_AR"

cd "$CORE"
cargo "${TC_ARGS[@]}" build --release --target aarch64-linux-android

SO=$CORE/target/aarch64-linux-android/release/libskyward_core.so
[ -f "$SO" ] || { echo "FAIL: no .so"; exit 1; }

mkdir -p "$OUT"
cp -f "$SO" "$OUT/libskyward_core.so"

SYMS=$("$LLVM/llvm-nm" -D --defined-only "$SO" | grep -c "Java_com_threely_skyward_RustCore_" || true)
echo "so: $(stat -c%s "$SO") bytes | JNI symbols: $SYMS | -> $OUT"
[ "$SYMS" -ge 12 ] || { echo "FAIL: JNI 导出符号异常偏少"; exit 1; }
