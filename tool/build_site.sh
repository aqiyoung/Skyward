#!/usr/bin/env bash
set -euo pipefail

repo="${SITE_REPOSITORY:-aqiyoung/Skyward}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="${1:-$root/build/site}"

if ! command -v node >/dev/null; then
  echo "error: tool/render_site.mjs needs Node.js on PATH" >&2
  exit 1
fi

rm -rf "$out"
mkdir -p "$out"
cp -R "$root/site/." "$out/"

# Screenshots and icons are design-pass artifacts; a checkout that lacks one
# still builds, it just ships without that picture. A hard cp here is what kept
# the whole site from building whenever the shots were out of date.
copy_if_present() {
  if [ -f "$1" ]; then
    cp "$1" "$2"
  else
    echo "note: $1 is absent; continuing without it" >&2
  fi
}
# site/mark.png, site/favicon.png, site/apple-touch-icon.png and site/og.png are
# rendered from the logo artwork by tool/prepare_logo.mjs + tool/build_icons.mjs,
# and committed so building needs no image tooling. Regenerate when the logo or
# the brand hue changes.
copy_if_present "$root/snapshots/preview.png" "$out/preview.png"
copy_if_present "$root/snapshots/preview-dark.png" "$out/preview-dark.png"

# Release metadata feeds the download list, so it has to exist wherever the site
# is built. `gh` is used when present; Vercel's build image has only curl, which
# answers the same public endpoints (a token just raises the rate limit).
api="https://api.github.com/repos/$repo"
auth=()
[[ -n "${GITHUB_TOKEN:-}" ]] && auth=(-H "Authorization: Bearer ${GITHUB_TOKEN}")

json_get() {
  local path="$1" pick="$2" body
  if body=$(curl -fsS --max-time 20 "${auth[@]}" "$api$path" 2>/dev/null); then
    printf '%s' "$body" | node -e '
      let raw = "";
      process.stdin.on("data", (d) => (raw += d)).on("end", () => {
        try {
          const value = JSON.parse(raw);
          const pick = process.argv[1];
          const out = pick ? pick.split(".").reduce((node, key) => node?.[key], value) : value;
          console.log(typeof out === "string" ? out : JSON.stringify(out));
        } catch {}
      });
    ' "$pick"
  fi
}

stars="$(gh api "repos/$repo" --jq '.stargazers_count' 2>/dev/null || json_get '' 'stargazers_count')"
assets="$(json_get '/releases/latest' 'assets')"
latest_tag="$(gh api "repos/$repo/releases/latest" --jq '.tag_name' 2>/dev/null || json_get '/releases/latest' 'tag_name')"
published="$(json_get '/releases/latest' 'published_at')"
if [[ -n "$latest_tag" && -n "$assets" ]] &&
  release="$(node -e '
    const [tag, publishedAt, stars, assets] = process.argv.slice(1);
    console.log(JSON.stringify({ tag, publishedAt, stars: Number(stars) || null, assets: JSON.parse(assets) }));
  ' "$latest_tag" "$published" "$stars" "$assets" 2>/dev/null)"; then
  printf '%s\n' "$release" >"$out/release.json"
  tag="$latest_tag"
else
  echo "warning: no release metadata from $repo; the page falls back to CHANGELOG.md" >&2
  tag=""
fi

# The Rust-core build ships as a separate `-rust` tagged release. Pull the
# newest one into its own file so the download page can offer it side by side
# with the stable Go-core build. Reuse the releases list below: both this and
# the changelog need it, so fetch once into a file (the response is ~2 MB and
# streaming it through a pipe can truncate) and read it from disk.
rust_list="$out/.releases.json"
if command -v gh >/dev/null 2>&1; then
  gh api "repos/$repo/releases?per_page=100" >"$rust_list" 2>/dev/null || curl -fsS --max-time 60 "${auth[@]}" "$api/releases?per_page=100" -o "$rust_list" 2>/dev/null
else
  curl -fsS --max-time 60 "${auth[@]}" "$api/releases?per_page=100" -o "$rust_list" 2>/dev/null
fi
if [[ -s "$rust_list" ]]; then
  rust_release="$(node -e '
    try {
      const list = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
      const rust = (Array.isArray(list) ? list : []).find((r) => /-rust$/.test(r.tag_name));
      if (!rust) { console.log(""); process.exit(0); }
      console.log(JSON.stringify({
        tag: rust.tag_name,
        name: rust.name,
        publishedAt: rust.published_at,
        url: rust.html_url,
        prerelease: Boolean(rust.prerelease),
        assets: (rust.assets || []).map((a) => ({
          name: a.name, size: a.size, url: a.browser_download_url || a.url,
        })),
      }));
    } catch { console.log(""); }
  ' "$rust_list")"
  if [[ -n "$rust_release" ]]; then
    printf '%s\n' "$rust_release" >"$out/rust-release.json"
  else
    echo "note: no -rust release found; page omits the Rust-core card" >&2
  fi

  # A release often ships only one platform (e.g. an Android-only point
  # release), which would leave desktop visitors with no recommended download.
  # Build a per-platform map: for each OS, the most recent release that actually
  # carries an installer for it. The page falls back to this when the latest
  # release has nothing for the visitor's device.
  platform_releases="$(node -e '
    try {
      const list = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
      const osOf = (name) => {
        const n = name.toLowerCase();
        if (/android/.test(n) || n.endsWith(".apk")) return "android";
        if (/windows|\.exe|\.msi/.test(n)) return "windows";
        if (/macos|mac-|\.dmg/.test(n)) return "macos";
        if (/linux|\.deb|\.rpm|\.appimage/.test(n)) return "linux";
        return null;
      };
      const result = {};
      for (const r of (Array.isArray(list) ? list : [])) {
        if (/-rust$/.test(r.tag_name) || /^preview-|^dev-/.test(r.tag_name)) continue;
        for (const a of (r.assets || [])) {
          const os = osOf(a.name);
          if (!os || result[os]) continue;
          result[os] = {
            tag: r.tag_name,
            publishedAt: r.published_at,
            name: a.name,
            size: a.size,
            url: a.browser_download_url || a.url,
            releaseUrl: r.html_url,
          };
        }
      }
      console.log(JSON.stringify(result));
    } catch { console.log("{}"); }
  ' "$rust_list")"
  printf '%s\n' "$platform_releases" >"$out/platform-releases.json"
else
  echo "warning: releases unreachable; page omits the Rust-core card" >&2
  printf '{}\n' >"$out/platform-releases.json"
fi

# The changelog is built from this repository's own releases, so the timeline
# carries our version numbers and our notes rather than the pre-fork history in
# the checked-in CHANGELOG.md. If the API cannot be read, that file stands in.
if [[ -s "$rust_list" ]]; then
  SITE_REPOSITORY="$repo" node "$root/tool/site_changelog.mjs" <"$rust_list" >"$out/CHANGELOG.md"
else
  echo "warning: releases unreachable; using the checked-in CHANGELOG.md" >&2
  cp "$root/CHANGELOG.md" "$out/CHANGELOG.md"
fi
rm -f "$rust_list"

# Every data-i18n key and every t() call must resolve in both languages; a typo
# otherwise renders as the bare key on the page.
node "$root/tool/check_i18n.cjs"

# Canonical URLs in the rendered pages follow wherever the site is built: an
# explicit SITE_URL wins, then Vercel's own build-time host, then GitHub Pages.
if [[ -z "${SITE_URL:-}" && -n "${VERCEL_URL:-}" ]]; then
  SITE_URL="https://$VERCEL_URL"
fi
node "$root/tool/render_site.mjs" "$out" "${SITE_URL:-https://aqiyoung.github.io/Skyward}"

echo "site assembled in $out"
