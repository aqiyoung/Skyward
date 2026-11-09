# launch_at_startup

Registers Skyward as a login item, so 「设置 → 通用 → 开机启动」 has something to
switch (`lib/common/launch.dart`). Vendored from
[launch_at_startup](https://github.com/leanflutter/launch_at_startup) 0.5.1 by
LiJianying (MIT, see `LICENSE`), through the `chen08209/launch_at_startup` fork
at `e930ce65c5804343103447e01d39fccabedc8681`.

Only `lib/` and `LICENSE` came across; `example/`, the CI workflows and the
package's own README are left behind. The code is otherwise unchanged.

**Why it is vendored.** Upstream 0.5.1 constrains `win32_registry` to `^2.0.0`
while Skyward depends on `^3.0.3` directly, so the two cannot co-resolve. The
chen08209 fork migrated the Windows implementation to the 3.x API
(`Registry.openPath` → `CURRENT_USER.open`, `createValue` → `setValue`,
`getStringValue` → `getString`). Skyward no longer fetches that fork at build
time: this repository is the source now.

**When to un-vendor.** When upstream publishes a release that accepts
`win32_registry` 3.x, this directory can go and `pubspec.yaml` can point at the
published package again — diff the two first, as the Windows file carries the
fork's changes.
