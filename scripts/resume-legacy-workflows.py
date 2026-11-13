#!/usr/bin/env python3
"""恢复（enable）被 pause-legacy-workflows.py 暂停的旧版 Flutter 工作流。

- 读快照 legacy-workflows-state.json，只 enable「暂停前 state_before=active」的条目。
- 本来就是 disabled_manually 的（如 pages.yaml）保持停用，不会被误开。
- 这就是「下次我要启用的时候再启用」的那一步。

用法：
  python3 scripts/resume-legacy-workflows.py
环境变量（可选）：GITHUB_TOKEN / GH_TOKEN, REPO
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
    _, d = req("GET", "actions/workflows?per_page=100")
    return d.get("workflows", [])


def main():
    if not os.path.exists(SNAP):
        print(f"找不到快照 {SNAP}，无法精确恢复", file=sys.stderr)
        sys.exit(1)
    snap = json.load(open(SNAP))
    targets = [w for w in snap["workflows"] if w["state_before"] == "active"]
    print(f"快照记录 {len(snap['workflows'])} 条，其中暂停前 active 需恢复 {len(targets)} 条\n")

    remote = {str(w["id"]): w for w in list_workflows()}
    print("=== 执行恢复（enable）===")
    for w in targets:
        wid = str(w["id"])
        cur = remote.get(wid, {}).get("state", "缺失")
        if cur == "active":
            print(f"  skip     {wid:<12} {w['path']:<48} (已是 active)")
            continue
        status, _ = req("PUT", f"actions/workflows/{wid}/enable")
        print(f"  enable   {wid:<12} {w['path']:<48} HTTP {status}")

    print("\n=== 恢复后复查 ===")
    after = list_workflows()
    for w in after:
        print(f"  {w['state']:<20} {w['id']:<12} {w['path']}")
    n_active = sum(1 for w in after if w["state"] == "active")
    print(f"\n当前 active 工作流: {n_active} 条（暂停前 active 共 {len(targets)} 条）")
    print("RESULT = OK")


if __name__ == "__main__":
    main()
