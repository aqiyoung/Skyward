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
copy_if_present "$root/snapshots/preview.png" "$out/preview.png"
copy_if_present "$root/snapshots/preview-dark.png" "$out/preview-dark.png"
copy_if_present "$root/assets/images/icon.png" "$out/icon.png"
copy_if_present "$root/assets_source/images/icon/glyph.svg" "$out/favicon.svg"
copy_if_present "$root/assets_source/images/icon/mark.png" "$out/mark.png"

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

# The changelog comes from the released tag so the notes never run ahead of the
# downloads; the working tree copy is only a fallback for local previews.
if [[ -n "$tag" ]] && ! git -C "$root" rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  git -C "$root" fetch -q --depth=1 origin "refs/tags/$tag:refs/tags/$tag" 2>/dev/null || true
fi
if [[ -n "$tag" ]] && git -C "$root" show "$tag:CHANGELOG.md" >"$out/CHANGELOG.md" 2>/dev/null; then
  :
else
  cp "$root/CHANGELOG.md" "$out/CHANGELOG.md"
fi

# Canonical URLs in the rendered pages follow wherever the site is built: an
# explicit SITE_URL wins, then Vercel's own build-time host, then GitHub Pages.
if [[ -z "${SITE_URL:-}" && -n "${VERCEL_URL:-}" ]]; then
  SITE_URL="https://$VERCEL_URL"
fi
node "$root/tool/render_site.mjs" "$out" "${SITE_URL:-https://aqiyoung.github.io/Skyward}"

echo "site assembled in $out"
