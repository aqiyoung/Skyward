#!/usr/bin/env node
// Build the site's changelog from this repository's own GitHub releases.
//
// The checked-in CHANGELOG.md stops at the pre-fork 0.9.x line, so the site's
// timeline read as upstream's history with upstream's version numbers. The
// release bodies are the notes we actually publish, in our own scheme
// (<major>.<channel>.<patch>.<revision>), so they are the source of truth here.
//
// Reads the release list as JSON on stdin (build_site.sh fetches it) and writes
// markdown shaped the way site/assets/shared.js parseChangelog() expects:
//   ## <tag> (<yyyy-mm-dd>)
//   - <entry>

const repo = process.env.SITE_REPOSITORY || 'aqiyoung/Skyward';
const limit = Number(process.env.SITE_CHANGELOG_LIMIT || 30);
void repo;

const stdin = await new Promise((resolve, reject) => {
  let data = '';
  process.stdin.on('data', (chunk) => (data += chunk));
  process.stdin.on('end', () => resolve(data));
  process.stdin.on('error', reject);
});

let releases;
try {
  releases = JSON.parse(stdin);
} catch {
  releases = [];
}
if (!Array.isArray(releases)) releases = [];

const note = (body) => {
  const lines = [];
  // The body opens with a header block (channel, build number, commit) and a
  // download table; the notes are the bullets after the "changes since <tag>"
  // line. Releases without that line carry no notes and are left out.
  let inNotes = false;
  for (const raw of String(body || '').split(/\r?\n/)) {
    const line = raw.trim();
    if (!inNotes) {
      if (/以来的改动/.test(line)) inNotes = true;
      continue;
    }
    if (/^[-*] /.test(line)) lines.push(line.replace(/^[-*] /, '- '));
  }
  return lines;
};

const versions = releases
  .filter((release) => !release.draft)
  .slice(0, limit)
  .map((release) => {
    const tag = release.tag_name || '';
    const date = (release.published_at || '').slice(0, 10);
    return { tag, date, lines: note(release.body) };
  })
  .filter((version) => version.tag && version.lines.length);

if (!versions.length) {
  process.stderr.write('site_changelog: no releases to write; leaving the existing changelog\n');
  process.exit(0);
}

const out = versions
  .map((version) => `## ${version.tag} (${version.date})\n\n${version.lines.join('\n')}`)
  .join('\n\n');

process.stdout.write(`# Changelog\n\n${out}\n`);
