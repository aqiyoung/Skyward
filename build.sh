#!/bin/bash
# Skyward Rust 安卓端出包脚本：手工组装 APK，不依赖 Gradle / Kotlin / AGP。
# 本机与 CI 通用：工程路径、SDK/NDK、toolchain、版本号全部可用环境变量覆盖。
# 不带任何环境变量时，行为与本机 PoC-1 完全一致。
set -euo pipefail

# 工程根：默认取脚本所在目录（本机 /workspace/skyward-rust，CI 即 checkout 根）
ROOT=${SKYWARD_ROOT:-$(cd "$(dirname "$0")" && pwd)}
CORE=$ROOT/core
AND=$ROOT/android
BUILD=${SKYWARD_BUILD:-$ROOT/build}
DIST=${SKYWARD_DIST:-$ROOT/dist}

# Android SDK：本机默认 /tmp/rust_android_env/sdk；CI 由 setup-android 注入 ANDROID_HOME
SDK=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-/tmp/rust_android_env/sdk}}
NDK_VER_DEFAULT=28.2.13676358
BT_VER_DEFAULT=35.0.0
PLATFORM_VER_DEFAULT=android-35
API_LEVEL=${ANDROID_API_LEVEL:-26}
TARGET_SDK=${ANDROID_TARGET_SDK:-35}

# NDK 路径：显式指定 > 指定版本目录 > SDK 下版本最新的目录
NDK=${ANDROID_NDK_HOME:-}
if [ -z "$NDK" ]; then
  _v=${NDK_VERSION:-$NDK_VER_DEFAULT}
  if [ -d "$SDK/ndk/$_v" ]; then
    NDK="$SDK/ndk/$_v"
  else
    NDK=$(ls -d "$SDK"/ndk/*/ 2>/dev/null | sort -V | tail -1 | sed 's:/$::' || true)
  fi
fi
# build-tools 路径：同样三级回退
BT=${ANDROID_BUILD_TOOLS:-}
if [ -z "$BT" ]; then
  _v=${BT_VERSION:-$BT_VER_DEFAULT}
  if [ -d "$SDK/build-tools/$_v" ]; then
    BT="$SDK/build-tools/$_v"
  else
    BT=$(ls -d "$SDK"/build-tools/*/ 2>/dev/null | sort -V | tail -1 | sed 's:/$::' || true)
  fi
fi
PLATFORM=${ANDROID_PLATFORM:-$PLATFORM_VER_DEFAULT}
ANDROID_JAR=$SDK/platforms/$PLATFORM/android.jar
LLVM=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin
CLANG=${ANDROID_CLANG:-$LLVM/aarch64-linux-android${API_LEVEL}-clang}
LLVM_AR=$LLVM/llvm-ar
NDK_NM=$LLVM/llvm-nm

# 版本与产物名可由 CI 注入（默认仍是 PoC-1）
VERSION_CODE=${VERSION_CODE:-1}
VERSION_NAME=${VERSION_NAME:-0.1.0-poc1}
OUT_APK=${OUT_APK:-$DIST/Skyward-RustCore-PoC1-arm64-v8a.apk}
LOG=$BUILD/build.log
mkdir -p "$BUILD" "$DIST"
: > "$LOG"
say(){ echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

# RUST_TC 语义：
#   未设置         -> 本机默认 +1.99.0（android 的 libstd 装在这个 toolchain）
#   设为空字符串   -> 用当前默认 toolchain（CI 已 rustup target add aarch64-linux-android）
#   设为具体版本   -> cargo +<version>
if [ "${RUST_TC+x}" = x ]; then
  if [ -n "$RUST_TC" ]; then TC_ARGS=("+$RUST_TC"); else TC_ARGS=(); fi
else
  TC_ARGS=("+1.99.0")
fi

say "== 0. 前置检查 =="
for f in "$ANDROID_JAR" "$CLANG" "$LLVM_AR" "$BT/aapt2" "$BT/d8" "$BT/zipalign" "$BT/apksigner"; do
  [ -e "$f" ] || { say "MISSING: $f"; exit 1; }
done
[ -n "$NDK" ] && [ -d "$NDK" ] || { say "MISSING: NDK ($NDK)"; exit 1; }
[ -n "$BT" ] && [ -d "$BT" ] || { say "MISSING: build-tools ($BT)"; exit 1; }
say "toolchain OK | SDK=$SDK | NDK=$(basename "$NDK") | BT=$(basename "$BT")"
if [ ${#TC_ARGS[@]} -gt 0 ]; then
  rustup run "${TC_ARGS[0]#+}" rustc --version | tee -a "$LOG"
else
  rustc --version | tee -a "$LOG"
fi

say "== 1. 宿主侧基准（同一份 engine，量 CPU/内存）=="
cd "$CORE"
cargo run --release --example bench > "$BUILD/host_bench.txt" 2>>"$LOG" || {
  say "WARN: host bench failed"; cat "$BUILD/host_bench.txt" >>"$LOG"; }
tail -3 "$BUILD/host_bench.txt" | tee -a "$LOG"

say "== 2. 交叉编译 Rust cdylib (aarch64-linux-android) =="
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$CLANG"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_AR="$LLVM_AR"
export CC_aarch64_linux_android="$CLANG"
export AR_aarch64_linux_android="$LLVM_AR"
cargo "${TC_ARGS[@]}" build --release --target aarch64-linux-android >>"$LOG" 2>&1
SO=$CORE/target/aarch64-linux-android/release/libskyward_core.so
[ -f "$SO" ] || { say "FAIL: no .so"; exit 1; }
say "so: $(stat -c%s "$SO") bytes ($(du -h "$SO" | cut -f1))"

say "== 2b. 校验 JNI 导出符号 =="
if [ -x "$NDK_NM" ]; then
  SYMS=$("$NDK_NM" -D --defined-only "$SO" | grep -c "Java_com_threely_skyward_poc_RustCore_" || true)
  # PoC-1 为 12 个；PoC-2 起新增会话真值 / 索引对照 / 规则集重置接口，当前 23 个。
  say "exported JNI symbols: $SYMS (PoC-2 expected 23)"
  if [ "$SYMS" -lt 12 ]; then
    say "FAIL: JNI 导出符号异常偏少"; exit 1
  fi
  "$NDK_NM" -D --defined-only "$SO" | grep "Java_com_threely" | tee -a "$LOG"
else
  say "llvm-nm not found, skip symbol check"
fi

say "== 3. aapt2 编译 Manifest / 生成基础 APK =="
# aapt2 link 的 --version-code/--version-name 不会覆盖 manifest 里已硬编码的值，
# 所以先生成一份把版本号替换掉的临时 manifest，再交给 link。
python3 - "$AND/AndroidManifest.xml" "$BUILD/AndroidManifest.xml" "$VERSION_CODE" "$VERSION_NAME" <<'PY'
import sys, re, html
src, dst, code, name = sys.argv[1:5]
s = open(src, encoding="utf-8").read()
s = re.sub(r'android:versionCode="\d+"', f'android:versionCode="{int(code)}"', s)
s = re.sub(r'android:versionName="[^"]*"',
           f'android:versionName="{html.escape(name, quote=True)}"', s)
open(dst, "w", encoding="utf-8").write(s)
print(f"injected versionCode={code} versionName={name}")
PY
# 编译全部 res（mipmap 图标 / adaptive icon xml / values），逐个 .flat 交给 link。
# 旧版只 compile 不 link，导致 resources.arsc 为空、Manifest 引用不到图标。
rm -rf "$BUILD/compiled"; mkdir -p "$BUILD/compiled"
"$BT/aapt2" compile --dir "$AND/res" -o "$BUILD/compiled" >>"$LOG" 2>&1
FLATS=$(find "$BUILD/compiled" -name '*.flat' | sort)
[ -n "$FLATS" ] || { say "FAIL: 没有编译出任何资源"; exit 1; }
say "compiled resources: $(echo "$FLATS" | wc -l) flat files"
"$BT/aapt2" link -o "$BUILD/base.apk" \
  -I "$ANDROID_JAR" \
  --manifest "$BUILD/AndroidManifest.xml" \
  --min-sdk-version "$API_LEVEL" --target-sdk-version "$TARGET_SDK" \
  --version-code "$VERSION_CODE" --version-name "$VERSION_NAME" \
  --auto-add-overlay \
  $FLATS >>"$LOG" 2>&1
say "base.apk: $(stat -c%s "$BUILD/base.apk") bytes"
"$BT/aapt2" dump badging "$BUILD/base.apk" 2>/dev/null | grep "^package:" | tee -a "$LOG"

say "== 4. javac -> class -> d8 -> dex =="
rm -rf "$BUILD/classes" "$BUILD/dex"; mkdir -p "$BUILD/classes" "$BUILD/dex"
javac -nowarn -source 11 -target 11 -encoding UTF-8 \
  -classpath "$ANDROID_JAR" -d "$BUILD/classes" \
  $(find "$AND/java" -name '*.java') >>"$LOG" 2>&1
CLASSES=$(find "$BUILD/classes" -name '*.class')
"$BT/d8" --lib "$ANDROID_JAR" --min-api "$API_LEVEL" \
  --output "$BUILD/dex" $CLASSES >>"$LOG" 2>&1
DEX=$BUILD/dex/classes.dex
[ -f "$DEX" ] || { say "FAIL: no dex"; exit 1; }
say "classes.dex: $(stat -c%s "$DEX") bytes"

say "== 5. 合并 APK（base + dex + arm64 so）=="
python3 - "$BUILD/base.apk" "$DEX" "$SO" "$BUILD/unsigned.apk" <<'PY'
import sys, zipfile
base, dex, so, out = sys.argv[1:5]
with zipfile.ZipFile(base) as zin, zipfile.ZipFile(out, 'w') as zout:
    for it in zin.infolist():
        zout.writestr(it, zin.read(it.filename))
    zout.write(dex, 'classes.dex', compress_type=zipfile.ZIP_DEFLATED)
    # native lib 不压缩，配 zipalign -p 4 供系统直接 mmap
    zout.write(so, 'lib/arm64-v8a/libskyward_core.so',
               compress_type=zipfile.ZIP_STORED)
print('merged entries:', len(zipfile.ZipFile(out).infolist()))
PY
say "unsigned.apk: $(stat -c%s "$BUILD/unsigned.apk") bytes"

say "== 6. zipalign =="
"$BT/zipalign" -f -p 4 "$BUILD/unsigned.apk" "$BUILD/aligned.apk" >>"$LOG" 2>&1

say "== 7. 签名（固定 debug keystore，保证多次构建可覆盖安装）=="
# 随工程提交的固定 debug keystore；本机/ CI / 任意次构建签名一致。
KS=$ROOT/scripts/debug.keystore
if [ ! -f "$KS" ]; then
  say "WARN: 未找到 $KS，回退到临时生成（每次签名不同，覆盖安装需先卸载）"
  KS=$BUILD/debug.keystore
fi
if [ ! -f "$KS" ]; then
  keytool -genkeypair -v -keystore "$KS" \
    -storepass android -alias androiddebugkey -keypass android \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US" >>"$LOG" 2>&1
fi
"$BT/apksigner" sign \
  --ks "$KS" --ks-pass pass:android --key-pass pass:android \
  --min-sdk-version "$API_LEVEL" \
  --out "$OUT_APK" "$BUILD/aligned.apk" >>"$LOG" 2>&1
"$BT/apksigner" verify --verbose "$OUT_APK" >>"$LOG" 2>&1

say "== 8. 产物体积与构成 =="
ls -l "$OUT_APK" | tee -a "$LOG"
python3 - "$OUT_APK" > "$BUILD/apk_breakdown.txt" <<'PY'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
items = z.infolist()
tot = sum(i.compress_size for i in items)
raw = sum(i.file_size for i in items)
print(f"APK total: {tot} bytes ({tot/1048576:.2f} MB), raw {raw/1048576:.2f} MB, {len(items)} entries")
print("\n| entry | compressed | raw |")
print("|---|---:|---:|")
for i in sorted(items, key=lambda x: -x.compress_size):
    print(f"| {i.filename} | {i.compress_size} | {i.file_size} |")
PY
cat "$BUILD/apk_breakdown.txt" | tee -a "$LOG"

say "DONE: $OUT_APK"
