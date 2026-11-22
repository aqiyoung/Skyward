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

# The changelog is built from this repository's own releases, so the timeline
# carries our version numbers and our notes rather than the pre-fork history in
# the checked-in CHANGELOG.md. If the API cannot be read, that file stands in.
if releases="$(curl -fsS --max-time 25 "${auth[@]}" "$api/releases?per_page=40" 2>/dev/null)"; then
  printf '%s' "$releases" | SITE_REPOSITORY="$repo" node "$root/tool/site_changelog.mjs" >"$out/CHANGELOG.md"
else
  echo "warning: releases unreachable; using the checked-in CHANGELOG.md" >&2
  cp "$root/CHANGELOG.md" "$out/CHANGELOG.md"
fi

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
