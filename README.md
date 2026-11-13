# Skyward Rust Core · PoC-1

一版可装机的最小骨架，用来回答三个问题：

1. 安卓客户端能不能尽量用 Rust 写 → 能，但 `VpnService` 必须留几十行 Java 壳。
2. 换成 Rust 后体积能压到多少 → 量架构开销，见构建产物。
3. 性能会不会变差 → App 内直接跑规则引擎 / 数据面基准，装机即看。

## 架构分层

| 层 | 用什么 | 职责 |
|---|---|---|
| 平台壳（不可省） | Java | `VpnService` 子类、Manifest、Activity 生命周期 |
| UI | Android 原生 View | 纯代码构建，无 XML 布局、无 Compose、无 Flutter、无 WebView |
| JNI 边界 | C ABI | 只传 `int/long/double`，零对象分配、零字符串跨语言拷贝 |
| **内核 / 全部逻辑** | **Rust** | 配置、规则引擎、连接状态表、数据面统计、内存读数、基准 |

`core/` 是纯 `std`、零第三方依赖的 crate：`cdylib` 出 `libskyward_core.so`（arm64），
`rlib` 供宿主侧跑同一份逻辑的基准（无真机也能量 CPU/内存量级）。

## 目录

```
core/
  Cargo.toml          release: opt-level=s / lto / codegen-units=1 / panic=abort / strip
  src/engine.rs       规则引擎、连接表、数据面模拟、RSS 读数
  src/lib.rs          JNI 导出（12 个函数，全部原始类型）
  examples/bench.rs   宿主侧基准
android/
  AndroidManifest.xml 纯原生，含 VpnService 声明
  java/.../RustCore.java          native 声明
  java/.../MainActivity.java      基准面板
  java/.../SkywardVpnService.java 那几十行无法省掉的壳
build.sh               手工组装 APK（不经 Gradle）
dist/                  产物
```

## 为什么是手工组装 APK

`aapt2 link` → `javac` → `d8` → 合并 dex/so → `zipalign -p 4` → `apksigner`。
不引入 AGP/Kotlin/Compose/Flutter，APK 里除了系统框架就是 Rust so + 一个 dex，
这样量出来的体积才是「架构本身的下限」，不会被构建工具的运行时污染。

## 构建

```bash
# 环境：Android SDK platform-35 / build-tools 35 / NDK r28c / JDK 17+ /
#       rustup target aarch64-linux-android
./build.sh
# 产物：dist/Skyward-RustCore-PoC1-arm64-v8a.apk
```

注意：本机 android 的 `libstd` 装在 `1.99.0` toolchain，默认 `stable`(1.93)
的 sysroot 里没有，脚本用 `cargo +1.99.0` 显式指定。换机器时按实际 toolchain 调整
`build.sh` 里的 `RUST_TC`。

## PoC 边界（诚实说明）

- **不含真实代理协议栈**：不含 Clash.Meta / clash-rs 的 VLESS Reality、Hysteria2、
  TUIC、WireGuard 等实现，也没有 tun2socks。数据面基准是**内存模拟**。
- **不含 geo 数据**（现行版 15.55MB）、不含订阅解析、不含配置持久化。
- **不接管真实流量**：`SkywardVpnService` 有 `establishTun()` 但 UI 不触发，
  避免装机后误触断网。真实 tun fd 交给 Rust 是 PoC-2。
- 因此这一版**不能用来连接代理**，只用于量：架构体积下限、冷启动、规则匹配
  与数据面吞吐、常驻内存。真实转发性能必须等内核补齐后再测。

## 与现行 Flutter 版的对照基线（实测 60.30 MB）

| 组成 | 现行版 | 本 PoC |
|---|---:|---|
| Go 内核 `libclash.so` | 23.62 MB | 无（Rust so 替代，但未含协议栈） |
| Flutter 引擎 + Dart AOT | 11.72 MB | 无（原生 View，系统提供） |
| geo 数据 | 15.55 MB | 无 |
| MLKit 扫码 | 2.84 MB | 无 |

## CI 工作流（目前只开发安卓端）

`.github/workflows/android-rust.yml` 是**本工程唯一的工作流**，只出一个 arm64
安卓 APK：装 JDK 17 / Rust `aarch64-linux-android` / SDK platform-35 + build-tools
35 + NDK r28c → `./build.sh` → 验签+验架构 → 上传 artifact。刻意**不推 Telegram、
不打 Release tag、不构建 desktop 或其它平台**。

runner（ubuntu-latest）自带 Android SDK，CI 直接用预装的 `sdkmanager`，**不依赖
`android-actions/setup-android`**（该 action 内部跑 `sdkmanager tools`，而 Google 已
下线旧 `tools` 包，会报 "Failed to find package 'tools'" 退出 1）。

`build.sh` 的所有路径、toolchain、版本号都可以用环境变量覆盖，因此本机与干净的
CI runner 用同一份脚本：

| 变量 | 作用 | 本机默认 | CI 设置 |
|---|---|---|---|
| `SKYWARD_ROOT` | 工程根 | 脚本所在目录 | checkout 根 |
| `ANDROID_SDK_ROOT` / `ANDROID_HOME` | SDK 位置 | `/tmp/rust_android_env/sdk` | 由 setup-android 注入 |
| `NDK_VERSION` / `BT_VERSION` | NDK / build-tools 版本 | `28.2.13676358` / `35.0.0` | 同左 |
| `RUST_TC` | 显式 toolchain | `+1.99.0` | `''`（用默认 stable，已装 android target） |
| `VERSION_CODE` / `VERSION_NAME` | aapt2 版本 | `1` / `0.1.0-poc1` | `${{ github.run_number }}` 等 |

固定签名：`scripts/debug.keystore`（debug key，密码 `android`）随工程提交，保证
本机 / CI / 任意次构建签名一致、APK 可直接覆盖安装。正式发版前须换成 release key
且**不要**提交进仓库。

## 旧版 Flutter 工作流：保留但暂停

`aqiyoung/Skyward` 上原有 12 条工作流（多平台构建、preview、发版、core 检查等）
已用 GitHub Actions 的 `disable` 接口整体暂停：**yaml 文件全部原样保留、内容一个
字节未改**。等新版稳定、你说启用时，一条命令精确恢复：

```bash
# 恢复（只 enable 暂停前 active 的那 11 条，不误开本来就停的 pages.yaml）
python3 scripts/resume-legacy-workflows.py
# 再次暂停（幂等）
python3 scripts/pause-legacy-workflows.py
```

暂停前的状态快照在 `scripts/legacy-workflows-state.json`，恢复以此为准。凭据读
`GITHUB_TOKEN` / `GH_TOKEN`，回退 `/tmp/.valid_tok`；仓库可用 `REPO` 覆盖。
