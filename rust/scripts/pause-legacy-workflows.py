#!/usr/bin/env python3
"""暂停 aqiyoung/Skyward 上所有 active 的旧版 Flutter 工作流。

- 只调 Actions 的 disable 接口：工作流 .yaml 文件全部原样保留、一个字节不改。
- 暂停前把每条工作流的 id/name/path/state 存进快照 JSON，
  供 resume-legacy-workflows.py 精确恢复（只恢复原来 active 的）。
- 可重复执行：已是 disabled_manually 的会跳过，不会覆盖快照里的初始状态。

用法：
  python3 scripts/pause-legacy-workflows.py
环境变量（可选）：
  GITHUB_TOKEN / GH_TOKEN  默认回退读 /tmp/.valid_tok
  REPO                     默认 aqiyoung/Skyward
"""
import json
import os
import sys
import urllib.error
import urllib.request

REPO = os.environ.get("REPO", "aqiyoung/Skyward")
BASE = "https://api.github.com"
HERE = os.path.dirname(os.path.abspath(__file__))
SNAP = os.path.join(HERE, "legacy-workflows-state.json")


def token():
    t = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if t:
        return t.strip()
    try:
        return open("/tmp/.valid_tok").read().strip()
    except OSError:
        print("缺少凭据：请设置 GITHUB_TOKEN 或 /tmp/.valid_tok", file=sys.stderr)
        sys.exit(1)


TOK = token()


def req(method, path):
    r = urllib.request.Request(
        f"{BASE}/repos/{REPO}/{path}",
        data=b"" if method in ("PUT", "POST", "PATCH") else None,
        method=method,
        headers={
            "Authorization": f"Bearer {TOK}",
            "Accept": "application/vnd.github+json",
            "Content-Type": "application/json",
            "User-Agent": "skyward-workflow-switch",
        },
    )
    try:
        with urllib.request.urlopen(r, timeout=60) as resp:
            body = resp.read().decode()
            return resp.status, (json.loads(body) if body else {})
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code} on {method} {path}: {e.read().decode()[:300]}", file=sys.stderr)
        sys.exit(1)


def list_workflows():
    status, d = req("GET", "actions/workflows?per_page=100")
    return d.get("workflows", [])


def main():
    ws = list_workflows()
    print(f"仓库 {REPO} 共 {len(ws)} 条工作流\n")

    # 读旧快照（若存在），以「最早的 state」为准，避免重复暂停把初始状态覆盖成 disabled
    before = {}
    if os.path.exists(SNAP):
        try:
            old = json.load(open(SNAP))
            for w in old.get("workflows", []):
                before[str(w["id"])] = w["state_before"]
        except (ValueError, KeyError, OSError):
            pass

    records = []
    for w in ws:
        wid = str(w["id"])
        state_before = before.get(wid, w["state"])
        records.append({
            "id": w["id"],
            "name": w["name"],
            "path": w["path"],
            "state_before": state_before,
        })

    snap = {"repo": REPO, "workflows": records}
    json.dump(snap, open(SNAP, "w"), indent=2, ensure_ascii=False)
    print(f"快照已写入 {SNAP}\n")

    print("=== 执行暂停（disable）===")
    for w in ws:
        if w["state"] == "active":
            status, _ = req("PUT", f"actions/workflows/{w['id']}/disable")
            print(f"  disable  {w['id']:<12} {w['path']:<48} HTTP {status}")
        else:
            print(f"  skip     {w['id']:<12} {w['path']:<48} (已是 {w['state']})")

    print("\n=== 暂停后复查 ===")
    after = list_workflows()
    for w in after:
        print(f"  {w['state']:<20} {w['id']:<12} {w['path']}")
    n_active = sum(1 for w in after if w["state"] == "active")
    print(f"\n剩余 active 工作流: {n_active} 条")
    print("RESULT =", "OK" if n_active == 0 else "WARN")


if __name__ == "__main__":
    main()
