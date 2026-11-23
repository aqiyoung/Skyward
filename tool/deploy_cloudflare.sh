#!/usr/bin/env bash
set -euo pipefail

# Deploy the site to Cloudflare Pages by building locally and uploading the
# static output. Vercel is wired to GitHub and deploys itself on push; this
# script is the Cloudflare half, run after publishing a new release or editing
# site/ so the pages.dev copy carries the same release data and changelog.
#
# Requires: node, curl, npx (wrangler), and either a GitHub token (preferred,
# for the release API) or `gh` on PATH. Cloudflare credentials come from
# CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID in the environment.

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project="${CF_PAGES_PROJECT:-skyward}"
branch="${CF_PAGES_BRANCH:-main}"
out="$(mktemp -d)"

: "${CLOUDFLARE_API_TOKEN:?set CLOUDFLARE_API_TOKEN}"
: "${CLOUDFLARE_ACCOUNT_ID:?set CLOUDFLARE_ACCOUNT_ID}"

cleanup() { rm -rf "$out"; }
trap cleanup EXIT

echo ">> Building site into $out"
bash "$root/tool/build_site.sh" "$out"

echo ">> Deploying $out to Cloudflare Pages project '$project' ($branch)"
CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN" \
CLOUDFLARE_ACCOUNT_ID="$CLOUDFLARE_ACCOUNT_ID" \
  npx --yes wrangler@latest pages deploy "$out" \
    --project-name "$project" --branch "$branch"

echo ">> Done: https://$project.pages.dev"
