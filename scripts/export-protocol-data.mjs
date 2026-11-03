import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

export const DATA_PATHS = ['protocol', 'schemas', 'templates'];

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
  const archive = path.join(os.tmpdir(), `agentic-data-${args.sha}.tar`);
  fs.mkdirSync(dest, { recursive: true });
  try {
    git([
      '-c',
      `core.hooksPath=${hooks}`,
      '-C',
      repo,
      'archive',
      '--format=tar',
      '--output',
      archive,
      args.sha,
      '--',
      ...DATA_PATHS,
    ]);
    execFileSync('tar', ['-xf', archive, '-C', dest], {
      stdio: ['ignore', 'pipe', 'pipe'],
    });
  } catch (error) {
    const detail = error.stderr?.toString?.() || error.message;
    console.error(`failed to export protocol data without executing scripts: ${detail}`);
    return 3;
  } finally {
    fs.rmSync(archive, { force: true });
    fs.rmSync(hooks, { recursive: true, force: true });
  }

  const scriptsDir = path.join(dest, 'scripts');
  if (fs.existsSync(scriptsDir)) {
    console.error('export included scripts/; refusing to leave executable protocol files in the data directory');
    return 3;
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
