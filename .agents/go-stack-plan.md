# 方案：把 Go 原生 TCP/IP 栈（sing-box 1.15 go stack）接进 Skyward 内核

状态：设计稿（待评审） · 日期：2026-11-10 · 范围：`core/Clash.Meta`（skyward-core）+ 可选 Apple 客户端

## 0. 一句话结论

Clash 的"万兆"不是玄学，杠杆有两个：**用 Go 原生 TCP/IP 栈替掉 gVisor**，以及**在 Apple 上用内核的批量 utun I/O（recvmsg_x/sendmsg_x）**。
我们已经白拿了一半红利（批量收默认开、fd 交接模型在用），缺的是"栈"本身；而换成 go stack 的真正难点不是 fd、不是批量 I/O，而是
**mihomo 的路由判定模型（`PrepareConnection`）与 sing-box 的流级裁决模型（`JudgeFlow`）语义不等价**，必须写一层适配。
Apple 端（NetworkExtension）应当**后置**：它需要一整套客户端工程（App Store 账号、NE 扩展、签名），与内核红利解耦。

## 1. 目标 / 非目标

### 目标
- G1 内核：Skyward 的 tun 数据面使用 sing-box 1.15 的 go stack，覆盖 Android + 桌面（macOS/Linux/Windows）。
- G2 保持 mihomo 的路由语义**逐条等价**：规则命中、fake-ip、DNS 劫持、进程/UID 分流、direct 出向、UDP NAT、ICMP。
- G3 可回滚：配置级 `tun.stack` 开关，legacy 栈随时可用，无需回滚发布。
- G4 可度量：有可复现的同机回环基线（对齐 Clash 的测法），每次内核升级自动对比。
- G5（独立项目）Apple 客户端：产出 `Skyward.xcframework` + NetworkExtension 隧道，走与 Clash 同构的 fd/桥接包路径。

### 非目标
- 不在第一阶段做 iOS/tvOS/macOS App Store 客户端（独立立项，见 §5-P5）。
- 不改规则集、DNS 组件、出向协议、路由匹配逻辑本身。
- 不引入 Clash 的私有 SDK / 品牌 / 二进制；只借鉴公开机制与公开源码（GPL-3.0，保留声明）。
- 不 fork `metacubex/sing-tun`（见 ADR-3）。
- 不做 utun 直读（Apple 专属，放 P6，默认关闭）。

## 2. 事实基线（已核实）

| 事实 | 出处 |
| --- | --- |
| Clash 内核基线是 mihomo v1.19.33，全部改动只有 26 个提交 | `git log 3f27ef39..main` in ProjectClash/Clash |
| 其中"换栈"是 1 个提交：**525 files, +57,782 / −121,720** | `git show --stat 8904fe29` |
| go stack 来自 `sagernet/sing-tun`（2026-09 起有 `stack_go*.go`），模块要求 **go 1.25.0** | sagernet/sing-tun@dev |
| Clash 的做法 = vendor `third_party/sing-tun-go`(129 文件) + fork `third_party/sing-tun`(162 文件) + mihomo 侧工厂钩子 | `listener/sing_tun/go_stack.go` |
| 工厂钩子：`GoStackOptions` / `SetGoStackFactory` / `startGoStack`，**tun 恒走 go stack**，配置写别的 stack 只警告 | `listener/sing_tun/go_stack.go`、`constant/tun.go` |
| Clash 的"直读隧道自己的 utun"：Swift 扫 fd 0..1023 + `getsockopt(fd,2,2)` 取名匹配 `utun` 前缀；内核用 `UtunControlName` 校验 | `Clash-Adapter` `PacketFlowBridge.swift`、`third_party/sing-tun/clash_utun_control_darwin.go` |
| 但客户端当前 `readsTheTunnelDirectly = false`，且该函数仅 `#if os(iOS)` → 线上实际走 PacketFlow 桥 | `Clash-Client/apple/ClashClient/Extension/ExtensionProvider.swift` |
| PacketFlow 桥：`socketpair(AF_UNIX, SOCK_DGRAM)`，4 字节 AF 帧头，1 MiB socket buffer，有界队列 1024 包/4 MiB，drain 批量 64（上限 256） | 同上 |
| **我们已有**：批量收 `EXP_RecvMsgX` 默认 **true**；`EXP_SendMsgX` 默认 false（附我们的"内核可能冻结"告警注释） | `skyward-core/config/config.go:553-554` |
| **我们已有**：fd 交接模型（VpnService fd → `LC.Tun.FileDescriptor` → `sing_tun.New`） | `core/tun/tun.go` |
| metacubex/sing-tun v0.4.29 **没有**：go stack、`MemoryTun`、`EXP_MultiPendingPackets`、`EXP_ExternalConfiguration`、`ip_rewrite` | `MetaCubeX/sing-tun@meta` 树 |
| metacubex/sing-tun v0.4.29 **有**：`internal/rawfile_darwin`、`internal/fdbased_darwin`、`NativeTun.BatchRead/BatchWrite` | 同上 |
| 我们的 Go 工具链 1.27.1 ≥ sagernet 要求的 1.25.0 | `.github/workflows/build.yaml` |
| 我们内核 sing 版本：metacubex/sing **v0.5.9**；Clash 侧并存 sagernet/sing **v0.9.5** → 两套 metadata 类型 | `skyward-core/go.mod` |

## 3. 关键判断（为什么这么做）

- **J1 杠杆在"栈"不在"包路径"。** 我们已默认开启批量收（RecvMsgX），Apple 的批量 I/O 我们也拿得到；缺的是把 gVisor 换成 Go 原生栈。
- **J2 真正的难点是路由语义转换。**
  metacubex `tun.Handler`：`PrepareConnection(network, source, destination, DirectRouteContext, timeout) → DirectRouteDestination` + `N.TCPConnectionHandler` + `PacketHandler` + `E.Handler`。
  sagernet `tun.Handler`：`JudgeFlow(network, source, destination, firstPacket) → FlowVerdict` + `NewDNSPacket` + `N.TCPConnectionHandlerEx` + `N.UDPConnectionHandlerEx`。
  两套模型不等价：一个是"连接前问路由"，一个是"流级先裁决再执行"。**转换写错 = 规则错配 / fake-ip 失效 / UDP 泄漏**，这是本方案的主要风险（见 §7-R2）。
- **J3 不要为了 go stack 去 fork metacubex/sing-tun。** 设备层 + 栈层都可以由 sagernet/sing-tun 提供，metacubex/sing-tun 只保留 legacy 路径（ADR-3）。
- **J4 依赖用 pin，不 vendor。** Clash vendor 是因为它只做 Apple（要裁掉 gvisor/mips 并删 12 万行）；我们要多平台，vendor 会让上游升级变成重放噩梦（ADR-4）。
- **J5 Apple 后置。** 内核红利与客户端工程正交，先拿红利，再决定要不要为 Apple 做客户端（G5）。
- **J6 默认不切。** go stack 先做**影子/可选**：默认仍 legacy，按配置/实验开关打开，差分测试通过后再谈默认（ADR-6）。

## 4. 架构决策（ADR）

| # | 决策 | 理由 | 被否决的替代 |
| --- | --- | --- | --- |
| ADR-1 | 内核先行，Apple 后置 | 我们没有 Apple 客户端；内核改造与客户端工程解耦 | "先做 iOS"：把两件事绑死在一个不可回退的大工程里 |
| ADR-2 | `tun.stack` 扩展枚举值 `go`，与 gvisor/mips/system/mixed 并存 | 语义清晰、可回滚、配置自解释 | 沿用 Clash 的"恒 go stack + 警告"：失去逃生舱 |
| ADR-3 | go 路径下**设备与栈都由 sagernet/sing-tun 提供**；metacubex/sing-tun 只服务 legacy 路径 | 避免维护一个 160 文件的上游 fork；边界只有一处 | fork metacubex/sing-tun（Clash 的做法）：升级成本与我们的多平台目标冲突 |
| ADR-4 | 直接依赖 `github.com/sagernet/sing-tun`，**pin 到具体 commit**（伪版本），不 vendor | 可复现、可升级、不背 vendor 补丁 | vendor：升级=重放；`dev` 分支直接依赖：不可复现 |
| ADR-5 | 与 sagernet/sing 并存两个 `sing` fork，转换只发生在两个 adapter 文件 | 上游现实：metacubex/sing v0.5.9 与 sagernet/sing v0.9.5 类型不通用 | 强行统一 sing 版本：会把 mihomo 全树拖进不兼容重构 |
| ADR-6 | go stack **默认关闭**，先以实验开关 + 差分测试推进 | 语义转换有风险；可回滚比性能优先 | 直接默认开：一次错误就影响全部用户 |
| ADR-7 | 性能基线用**同机回环**（收发两端同机、不出外网），与 Clash 测法一致 | 可复现、无需外部节点、可在 CI 上跑 | 用公网节点测：受网络与节点污染，无法归因 |

## 5. 实施分解

每阶段都有：范围 → 文件清单 → 验收标准 → CI gate → 回滚动作。
**所有构建与验证都在 GitHub Actions 上跑**（含 macOS runner），本地只改代码。

### P0 立项与基线（前置，1 个迭代内）

范围：
- 记录 legacy 栈的基线：吞吐（TCP 单流/多流、UDP）、CPU 占用、内存峰值、规则命中一致性。
- 把 Clash 的测法固化成我们的脚本（`tool/bench/tunnel_bench.sh`）：本机起 HTTP/iperf3 server → 经代理 → 本机 target，不出外网。
- 落 ADR 到本文件，确定 go stack 的 pin commit（选 sagernet/sing-tun 最近的、CI 全绿的 commit）。

文件：`tool/bench/tunnel_bench.sh`（新）、`.agents/go-stack-plan.md`（本文件）。
验收：基线数据入库（贴在 PR 描述或 `bench/` 结果文件），同一台机器上跑两遍差异 < 5%。
CI gate：脚本在 macOS runner 上可执行（不需要跑满，只校验参数与前置检查）。
回滚：无（不改产品行为）。

### P1 依赖与骨架（skyward-core）

范围：
- `skyward-core/go.mod`：新增 `github.com/sagernet/sing-tun`（pin commit）与 `github.com/sagernet/sing`（pin commit）。
- 新增 `listener/sing_tun/go_stack.go`：**工厂钩子**（`GoStackOptions` / `SetGoStackFactory` / `startGoStack`），结构对齐 Clash 但由我们自己写、注释与命名按我们的规范。
- 新增 `constant`：栈枚举加 `TunGo`；`config` 解析 `stack: go`；未知值沿用现有错误路径。
- 新增 `listener/sing_tun/go_stack_device.go`：go 路径的设备创建（sagernet `tun.New`）+ **metacubex `tun.Tun` 适配器**（`io.ReadWriter` + `Close`，把 sagernet 设备包成 mihomo 需要的形状）。

文件（skyward-core）：
```
go.mod / go.sum
constant/tun.go                 (+TunGo)
config/config.go                (解析/默认值)
listener/sing_tun/go_stack.go        (工厂钩子)
listener/sing_tun/go_stack_device.go (设备创建 + 适配器)
listener/sing_tun/server.go          (选栈分支)
```
验收：`go build ./...` 通过；`stack: go` 能进到 `startGoStack`（此阶段允许返回"未实现"错误，但必须是**明确**错误，不是 panic）。
CI gate：`kernel-check.yaml` 增加 `GOOS=linux/darwin/windows/android go vet` 矩阵 + `gofmt` 覆盖新目录。
回滚：删 `go.mod` 的两行 require + 删新文件（无外部依赖被引用）。

### P2 适配层（核心难点，最花时间）

要写的东西，逐条对应 §3-J2 的模型差异：

1. **流裁决适配** `listener/sing_tun/go_stack_handler.go`
   - 输入：sagernet 的 `JudgeFlow(network uint8, src, dst netip.AddrPort, firstPacket []byte) → FlowVerdict`。
   - 输出：mihomo 的决策（direct / 代理组 / 拒绝 / DNS 劫持 / fake-ip 回写）。
   - 关键：**必须复刻 legacy 路径的判定顺序**（规则集 → fake-ip → 进程/UID → 域名嗅探 → 出向选择），而不是另写一套。
   - `NewDNSPacket(payload, src, dst, writer)` → 交回 mihomo 的 DNS 组件（与 `listener/sing_tun/dns.go` 现有路径一致）。
   - `TCPConnectionHandlerEx` / `UDPConnectionHandlerEx` → 走 mihomo 现有的 `sing.ListenerHandler` 出向。
2. **metadata 转换** `listener/sing_tun/go_stack_meta.go`
   - metacubex/sing v0.5.9 的 `M.Socksaddr` ↔ sagernet/sing v0.9.5 的 `goM.Socksaddr`（含 domain / IPv4 / IPv6 三态）。
3. **UDP NAT 适配** `listener/sing_tun/go_stack_udp.go`
   - sagernet 的 `NATMapping` / `NATFiltering` / `UDPNATMax` ← mihomo 的既有实现语义（EndpointIndependentNat 等）。
4. **ICMP 语义对齐** `listener/sing_tun/go_stack_icmp.go`
   - go stack 自带 ICMP echo / "refused UDP 用 ICMP 回应"；需确认与 mihomo 现有行为不冲突（mihomo 侧有 `DisableICMPForwarding`）。
5. **内存压力回调** `listener/sing_tun/go_stack_memory.go`
   - sagernet 的 `MemoryPressure func() MemoryPressure` ← 我们已有的 `core/memory*.go` 内存监控。
6. **拥塞控制映射** `listener/sing_tun/go_stack_congestion.go`
   - `bbr` / `bbr3` / `cubic` → sagernet 的 `goLookupCongestionControl`；`bbr3` 在 go stack 里叫什么要实测确认。
7. **IP 重写 / loopback 地址**（可选，legacy 无此能力时不做）
   - metacubex 无 `ip_rewrite`；若要做 `tun.ip-rewrite` 类能力，需从 sagernet 移植 `ip_rewrite.go`（本阶段列为可选，不阻塞）。

验收（**本阶段的核心 gate**）：
- **差分测试**：同一份配置，legacy 与 go 两条路径产出**同样的连接与规则命中**（连接数、命中规则、出向、DNS 应答、fake-ip 映射、UDP 会话）——用现有 mihomo 测试基建 + 新增 golden 测试。
- 单元测试覆盖：转换函数（metadata / verdict / NAT）、framing（见 P3）。
CI gate：新增 job `go stack`：`-race`、`-count=1`、覆盖 linux/darwin/android/windows 的 `go vet`；新增 `gofmt` 范围。
回滚：`tun.stack` 不填 `go` 即回到 legacy（产品级回滚，不需要回滚发布）。

### P3 平台接通

| 平台 | 设备来源 | 帧格式 | 注意点 |
| --- | --- | --- | --- |
| Android | VpnService fd（`LC.Tun.FileDescriptor`） | **裸 IP**（无 4 字节 AF 头） | sagernet 设备在 android 下的 fd 路径是否按裸 IP 读，**必须实测**，不能假设 |
| macOS 桌面 | 内核自建 utun | **4 字节 AF 头** | sagernet darwin 设备自带 utun 帧处理；与我们的 `EXP_RecvMsgX` 兼容 |
| Linux 桌面 | 内核自建 tun | 裸 IP | auto-route / auto-redirect 语义要保住（`listener/sing_tun/redirect_linux.go`） |
| Windows 桌面 | wintun | 裸 IP | wintun 特殊路径，优先最后做 |

做法：go 路径下由 sagernet 设备创建（`gotun.New(Options{...})`），再用适配器包成 metacubex `tun.Tun` 交给 mihomo 其余部分（Close、路由监视、DNS）。
验收：四平台各自跑通"能上网 + 规则生效 + DNS 正常 + UDP/QUIC 正常 + 长时间不断流"。
CI gate：`GOOS` 矩阵 vet + 每个平台的最小集成测试（用 loopback 设备，不依赖真机）。
回滚：配置层关闭。

### P4 验证、灰度与性能

- **性能**：对齐 Clash 测法（同机回环、收发同机、不出外网），指标：TCP 单流/多流 Gbit/s、CPU%、内存峰值、UDP 吞吐。目标不是"对标 14 Gbit/s"，而是"相对 legacy 栈的提升 ≥ 2× 且 CPU 不劣化"。
- **内存**：go stack 有 arena/无 gVisor，预期更省；需与 iOS 报告的 14 MiB 同量级地验证我们的桌面数字。
- **灰度**：`tun.stack: go` 先在 dev/beta 的实验开关后开放；统计崩溃率、连接失败率、规则误命中。
- **默认切换的判据**（全部满足才把默认改成 go）：
  1. 四平台差分测试全绿；
  2. 回环性能 ≥ 2× legacy 且 CPU 不升；
  3. 灰度两周无 P0/P1；
  4. 上游 go stack 有 ≥ 1 个稳定 tag（当前只有 dev 分支）。
- **上游纪律**：每次内核升级重跑 P4 基线；基线劣化 > 10% 即阻断升级（写进 `kernel-check.yaml`）。

### P5 Apple 客户端（独立仓库，建议 `aqiyoung/skyward-apple`）

需要三件事，与 Clash 的三仓库一一对应：

1. **Apple SDK 构建**：在 skyward-core 新增 `bind/apple`（gomobile 绑定；sagernet/gomobile v0.1.13），出 `Skyward.xcframework`（5 slice：iOS 真机/模拟器、macOS、tvOS 真机/模拟器；静态库；链接 libresolv）。CI 用 GitHub 的 macOS runner（`macos-14/15`），不在本地构建。
2. **Swift 桥**：`PacketFlowBridge` 等价实现（socketpair + 4 字节 AF 帧 + 批量收发 + 有界队列 + 背压）。可直接复用 `Clash-Adapter`（GPL-3.0，Skyward 亦 GPL-3.0，保留版权与 NOTICE，注明来源与修改）。
3. **App + NetworkExtension 扩展**：Flutter 做 UI，原生 Swift 扩展托管桥与内核；App Group、entitlements、签名、App Store 审核（Packet Tunnel 需付费开发者账号）。
   - 内核侧改动很小：`core/tun/tun.go` 目前是 `//go:build android`，需要抽出跨平台的 tun 启动能力（桌面 core 进程已有类似通道，可复用）。
   - 平台差异（Clash 实测结论）：macOS 支持按进程名/路径/UID 分流；iOS/tvOS 不支持按 App/进程识别。

### P6 Apple 性能路径（可选，默认关闭）

- utun 直读：扩展里扫 fd 找 utun control socket → 交给内核；内核校验 `UtunControlName` → 批量读（32 KiB 块、绕开 Go runtime poller）。
- **前置条件**：Clash 客户端当前把 `readsTheTunnelDirectly` 关着，说明直读路径在其线上版本并未启用（稳定性/审核原因未知）。我们**先不做**，等 P5 稳定后再评估。
- 其余 Apple 性能红利（go stack + recvmsg_x）在 P5 落地时自然获得。

## 6. 验证策略（分层）

| 层 | 手段 | 覆盖 |
| --- | --- | --- |
| 静态 | `gofmt`、`go vet`（GOOS 矩阵）、`go build` | 编译面 |
| 单元 | 转换/适配/framing 的表驱动测试 + golden | P2 的每一处语义 |
| 集成 | 设备级回环：真实 tun 设备 + 本机对端 | TCP/UDP/QUIC/ICMP/DNS/fake-ip/规则 |
| 差分 | legacy vs go 同配置对照 | 路由语义等价（核心 gate） |
| 稳定 | `-race` + 长跑（≥30 min）+ 内存曲线 | 竞态、泄漏、抖动 |
| 性能 | 同机回环基线（P0/P4） | 吞吐/CPU/内存 |
| 真机 | Android 各厂商 ROM、macOS 14/15、Linux、Win10/11 | 真实网络与权限模型 |
| 灰度 | 实验开关 + 线上指标 | 真实用户 |

## 7. 风险登记册

| # | 风险 | 影响 | 缓解 | 回滚触发判据 |
| --- | --- | --- | --- | --- |
| R1 | go stack 上游 immature（2026-09 才出现，仅 dev 分支） | 上游破坏性变更 | pin commit；季度复核；自建 patch 只在 adapter 层 | 上游连续 2 次 bump 破坏我们的适配 → 冻结 pin |
| R2 | **路由语义转换出错**（J2） | 规则错配、fake-ip 失效、UDP 泄漏 | 差分测试为核心 gate；legacy 逃生舱；默认不开 | 任一差分用例不一致 → 阻断合并 |
| R3 | Android fd 帧格式假设错误 | Android 隧道全断 | P3 实测优先，禁止假设 | Android 真机不通 → 立即关闭开关 |
| R4 | metacubex 与 sagernet 两套 sing 类型 | 转换面变大、易漏 | 转换收敛到 2 个文件；禁止扩散 | 转换文件超过 400 行 → 重新设计边界 |
| R5 | 依赖 go 1.25+ / 双 sing fork | 构建复杂度上升 | CI 统一 Go 1.27.1；go.mod 明确 pin | 上游要求 Go 版本超出我们的 CI → 评估 |
| R6 | 性能不达预期（瓶颈不在栈） | 投入无回报 | P0 先测基线与 profile，再决定投入 | P2 后测得提升 < 1.5× → 暂停并复盘 |
| R7 | 许可与署名 | 合规 | 全部 GPL-3.0；保留 LICENSE/NOTICE；第三方清单入库 | 合规检查不过 → 不合并 |
| R8 | Apple 阶段的账号/审核不可控 | 计划延后 | P5 独立立项，与内核解耦 | 拿不到开发者账号 → P5 挂起，不影响 P1–P4 |
| R9 | 上游 mihomo 后续自带 go stack | 我们的适配变冗余 | 定期看 MetaCubeX/sing-tun 与 mihomo 的 PR | 上游提供等价能力 → 用我们的差分测试验证后切换 |

## 8. 上游跟踪纪律

- skyward-core = mihomo 上游 + 我们的 patch 层；每次上游升级**重放**我们的提交（见 `.agents/core-sync.md`）。
- 我们的 go stack 改动**全部落在 skyward-core 自己的文件**（`listener/sing_tun/go_stack*.go`、`constant`、`config`）+ 一条 `require`，
  **不改 metacubex/sing-tun、不改 mihomo 上游文件**（ADR-3）→ 重放成本 = 重放我们自己的 3~5 个提交。
- 依赖用 pin 的伪版本，不 vendor、不写 replace（除 sagernet/sing-tun 需要 `EXP_*` 而上游未提供时，才在**我们自己的模块内**用 shim 补，不改上游）。
- `.agents/core-sync.md` 增补一节：go stack pin 的升级流程（先升 pin → 跑差分 → 跑基线 → 才合入）。

## 9. 许可与合规

- Skyward 内核与客户端：GPL-3.0（`LICENSE`）。
- `sagernet/sing-tun`、`sagernet/sing`：GPL-3.0 → 可复用，需保留版权声明与许可证文本。
- `metacubex/sing-tun`、`metacubex/sing`：GPL-3.0（现有依赖）。
- 若采纳 Clash-Adapter 的 Swift 桥：GPL-3.0 → 保留声明、注明来源与修改，第三方清单入库。
- 命名：不使用 "mihomo" 作为产品名（我们已是 Skyward）；内核 Go module path 保持 `github.com/metacubex/mihomo`（既有约定，不要动）。

## 10. 产出物清单（文件级）

**skyward-core**（新增/改动）
```
go.mod, go.sum                                   (+2 pin 依赖)
constant/tun.go                                  (+TunGo)
config/config.go                                 (stack: go 解析)
listener/sing_tun/go_stack.go                    (工厂钩子)
listener/sing_tun/go_stack_device.go             (设备创建 + tun.Tun 适配)
listener/sing_tun/go_stack_handler.go            (流裁决适配)      ← 最难
listener/sing_tun/go_stack_meta.go               (metadata 转换)
listener/sing_tun/go_stack_udp.go                (UDP NAT 适配)
listener/sing_tun/go_stack_icmp.go               (ICMP 对齐)
listener/sing_tun/go_stack_memory.go             (内存压力回调)
listener/sing_tun/go_stack_congestion.go         (拥塞控制映射)
listener/sing_tun/server.go                      (选栈分支)
listener/sing_tun/*_test.go                      (对应单测)
```

**Skyward 仓库（app 侧）**
```
tool/bench/tunnel_bench.sh                      (基线脚本, P0)
.github/workflows/kernel-check.yaml             (+GOOS 矩阵, +go stack job)
.github/workflows/build.yaml                    (+go stack gate)
.agents/core-sync.md                            (go stack pin 升级流程)
.agents/go-stack-plan.md                        (本文件)
```

**独立仓库 `aqiyoung/skyward-apple`（P5）**
```
apple/App/                    (Flutter UI)
apple/Extension/              (NEPacketTunnelProvider + PacketFlowBridge)
scripts/build-xcframework.sh  (gomobile → Skyward.xcframework)
```

## 11. 需要拍板的决策点

1. **顺序**：接受"内核先行、Apple 后置"？（P1–P4 不依赖任何 Apple 资产）
2. **默认策略**：go stack 先默认关闭（ADR-6），还是 beta 灰度后即默认开？
3. **依赖形态**：接受"pin sagernet/sing-tun + 两个 sing fork 共存"（ADR-4/5）？替代方案是 fork metacubex/sing-tun（Clash 做法，维护成本更高）。
4. **Apple 是否立项**：P5 需要付费开发者账号与持续维护；若不立项，则 P6（utun 直读）直接取消。
5. **投入上限**：若 P2 完成后实测提升 < 1.5×，是否中止本方案（避免为"看起来先进"持续投入）？

## 12. 与本方案无关的遗留项

- beta/main 上 5 个因 `b5bb9c2`（分隔线默认值翻转）而失效的测试，需要逐个判定"改测试"还是"改代码"。
- 一次性 workflow `.github/workflows/format-fix.yaml` 验证后需删除。
