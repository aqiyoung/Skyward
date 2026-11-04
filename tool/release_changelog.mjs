// Structured changelog for the release body.
//
// `publish-release.yaml` writes its own Chinese release notes, but the app's
// in-app update log needs the same entries as machine readable JSON so it can
// show Chinese to a Chinese UI and English to everyone else. This script emits
// that JSON block — the same schema `tool/changelog.dart` renders — without
// needing the Dart toolchain in the release job.
//
// Usage: node tool/release_changelog.mjs <from-ref> <to-ref> <version> [channel]

import { execFileSync } from 'node:child_process';

const [from, to, version, channel = 'stable'] = process.argv.slice(2);
if (!from || !to || !version) {
  console.error(
    'usage: release_changelog.mjs <from-ref> <to-ref> <version> [channel]',
  );
  process.exit(64);
}

const FIELD = '\x1f';
const RECORD = '\x1e';

const raw = execFileSync(
  'git',
  [
    'log',
    '--no-merges',
    '--reverse',
    `--format=%H${FIELD}%s${FIELD}%b${RECORD}`,
    `${from}..${to}`,
  ],
  { encoding: 'utf8' },
);

const subjectPattern = /^([a-z]+)(?:\(([^)]*)\))?(!)?:[ \t]+(.+)$/;
const trailerPattern =
  /^(BREAKING[ -]CHANGE|Changelog(?:-[A-Za-z0-9-]+)?|Breaking-[A-Za-z0-9-]+):[ \t]*(.*)$/;
const genericTrailerPattern =
  /^(?:[A-Za-z][A-Za-z0-9]*(?:-[A-Za-z0-9]+)+|Refs|Fixes|Closes):[ \t]*/i;
const zhTrailerPattern = /^Changelog-zh(?:-[A-Za-z0-9]+)?$/i;

const defaultTypes = {
  feat: 'feat',
  fix: 'fix',
  perf: 'perf',
  revert: 'revert',
};
const groups = ['breaking', 'feat', 'fix', 'perf', 'revert'];
const knownTypes = new Set(groups);

function capitalize(value) {
  return value ? value[0].toUpperCase() + value.slice(1) : value;
}

function readTrailers(body) {
  const trailers = new Map();
  let current = null;
  for (const line of body.split('\n')) {
    const match = line.match(trailerPattern);
    if (match) {
      current = match[1].replace(/BREAKING-CHANGE/i, 'BREAKING CHANGE');
      trailers.set(current, match[2].trim());
      continue;
    }
    if (current === null) {
      continue;
    }
    if (genericTrailerPattern.test(line) || line.trim() === '') {
      current = null;
      continue;
    }
    trailers.set(current, `${trailers.get(current)} ${line.trim()}`.trim());
  }
  return trailers;
}

function zhText(trailers) {
  for (const [key, value] of trailers) {
    if (zhTrailerPattern.test(key) && value) {
      return value;
    }
  }
  return undefined;
}

function resolveType(type, trailers) {
  const override = trailers.get('Changelog-Type');
  if (override) {
    return knownTypes.has(override) ? override : null;
  }
  if (defaultTypes[type]) {
    return defaultTypes[type];
  }
  return trailers.has('Changelog') ? 'feat' : null;
}

function collect() {
  const byGroup = new Map(groups.map((group) => [group, []]));
  for (const record of raw.split(RECORD)) {
    const trimmed = record.trim();
    if (!trimmed) {
      continue;
    }
    const [hash, subject, ...rest] = trimmed.split(FIELD);
    const body = rest.join(FIELD);
    const match = subject.trim().match(subjectPattern);
    if (!match) {
      continue;
    }
    const [, type, scope, bang, description] = match;
    const trailers = readTrailers(body);
    const changelog = trailers.get('Changelog');
    if (changelog && changelog.toLowerCase() === 'skip') {
      continue;
    }
    const id = hash.slice(0, 7);
    const normalizedScope = scope?.trim() || undefined;
    const zh = zhText(trailers);
    const entry = {
      id,
      ...(normalizedScope ? { scope: normalizedScope } : {}),
      text: changelog || capitalize(description.trim()),
      ...(zh ? { textZh: zh } : {}),
    };

    const breakingText = trailers.get('BREAKING CHANGE');
    if (bang || breakingText) {
      byGroup.get('breaking').push({
        ...entry,
        text: breakingText || capitalize(description.trim()),
      });
    }

    const group = resolveType(type, trailers);
    if (group) {
      byGroup.get(group).push(entry);
    }
  }
  return groups
    .filter((group) => byGroup.get(group).length > 0)
    .map((group) => ({ type: group, entries: byGroup.get(group) }));
}

const payload = {
  schemaVersion: 2,
  versions: [
    {
      version,
      tag: `v${version}`,
      date: new Date().toISOString().slice(0, 10),
      prerelease: channel !== 'stable',
      groups: collect(),
    },
  ],
};

const json = JSON.stringify(payload).replaceAll('>', '\\u003e');
process.stdout.write(`<!-- flclash:changelog:json\n${json}\n-->\n`);
