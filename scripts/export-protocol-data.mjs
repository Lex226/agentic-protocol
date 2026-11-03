import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { classifyGitPath, assertContainedRelative } from './lib/safe-path.mjs';

export const DATA_PATHS = ['protocol', 'schemas', 'templates'];
const REGULAR_MODES = new Set(['100644', '100755']);

function usage() {
  return 'usage: export-protocol-data.mjs --repo <git-dir> --sha <40-hex> --dest <dir>';
}

function parseArgs(argv) {
  const args = { repo: '', sha: '', dest: '', help: false };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === '--help' || token === '-h') args.help = true;
    else if (token === '--repo' || token === '--sha' || token === '--dest') {
      const value = argv[i + 1];
      if (!value || value.startsWith('--')) throw new Error(`missing value for ${token}`);
      i += 1;
      if (token === '--repo') args.repo = value;
      if (token === '--sha') args.sha = value;
      if (token === '--dest') args.dest = value;
    } else {
      throw new Error(`unknown argument: ${token}`);
    }
  }
  return args;
}

function git(args) {
  return execFileSync('git', args, {
    encoding: 'buffer',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
}

export function parseLsTree(buffer) {
  const entries = [];
  let offset = 0;
  while (offset < buffer.length) {
    const nul = buffer.indexOf(0, offset);
    const end = nul === -1 ? buffer.length : nul;
    const record = buffer.subarray(offset, end).toString('utf8');
    offset = end + 1;
    if (!record) continue;
    const tab = record.indexOf('\t');
    if (tab === -1) {
      throw new Error(`refusing unreadable git tree record: ${record}`);
    }
    const [mode, type, object] = record.slice(0, tab).split(' ');
    entries.push({ mode, type, object, path: record.slice(tab + 1) });
  }
  return entries;
}

export function selectDataEntries(entries) {
  const selected = [];
  for (const entry of entries) {
    const kind = classifyGitPath(entry.path, DATA_PATHS);
    if (kind === 'unsafe' || entry.type !== 'blob' || !REGULAR_MODES.has(entry.mode)) {
      throw new Error(`refusing unsafe git entry ${entry.mode || 'unknown'} ${entry.type || 'unknown'} ${entry.path}`);
    }
    if (kind === 'data') selected.push(entry);
  }
  return selected;
}

function writeBlob(repo, hooks, entry, dest) {
  const rel = entry.path.split('/').join(path.sep);
  const absolutePath = assertContainedRelative(dest, rel);
  fs.mkdirSync(path.dirname(absolutePath), { recursive: true });
  assertContainedRelative(dest, rel);
  const blob = git([
    '-c',
    `core.hooksPath=${hooks}`,
    '-C',
    repo,
    'cat-file',
    'blob',
    entry.object,
  ]);
  const handle = fs.openSync(absolutePath, 'w');
  try {
    fs.writeFileSync(handle, blob);
  } finally {
    fs.closeSync(handle);
  }
}

export function runExport(argv) {
  let args;
  try {
    args = parseArgs(argv);
  } catch (error) {
    console.error(error.message);
    console.error(usage());
    return 3;
  }
  if (args.help || !args.repo || !args.sha || !args.dest) {
    console.error(usage());
    return 3;
  }
  if (!/^[0-9a-f]{40}$/.test(args.sha)) {
    console.error(`source SHA must be 40 lowercase hex characters: ${args.sha}`);
    return 3;
  }

  const repo = path.resolve(args.repo);
  const dest = path.resolve(args.dest);
  const hooks = fs.mkdtempSync(path.join(os.tmpdir(), 'agentic-hooks-')).replaceAll('\\', '/');
  try {
    const listed = git([
      '-c',
      `core.hooksPath=${hooks}`,
      '-C',
      repo,
      'ls-tree',
      '-r',
      '-z',
      args.sha,
    ]);
    const selected = selectDataEntries(parseLsTree(listed));
    fs.mkdirSync(dest, { recursive: true });
    for (const entry of selected) writeBlob(repo, hooks, entry, dest);
  } catch (error) {
    const detail = error.stderr?.toString?.() || error.message;
    console.error(`refusing protocol data export: ${detail}`);
    return 3;
  } finally {
    fs.rmSync(hooks, { recursive: true, force: true });
  }

  console.log('protocol data exported');
  return 0;
}

function isDirectRun() {
  const entry = process.argv[1];
  if (!entry) return false;
  return import.meta.url === pathToFileURL(path.resolve(entry)).href;
}

if (isDirectRun()) {
  process.exit(runExport(process.argv.slice(2)));
}
