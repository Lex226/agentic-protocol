import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { DATA_PATHS } from '../export-protocol-data.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const script = path.join(root, 'scripts', 'export-protocol-data.mjs');

function tempDir(name) {
  return fs.mkdtempSync(path.join(os.tmpdir(), `agentic-${name}-`));
}

function git(cwd, args) {
  const result = spawnSync('git', args, { cwd, encoding: 'utf8' });
  assert.equal(result.status, 0, `git ${args.join(' ')}\n${result.stderr}`);
  return result.stdout;
}

test('data export allowlist excludes scripts', () => {
  assert.deepEqual(DATA_PATHS, ['protocol', 'schemas', 'templates']);
});

test('git archive export copies data and does not run scripts', () => {
  const upstream = tempDir('export-up');
  fs.mkdirSync(path.join(upstream, 'protocol'), { recursive: true });
  fs.mkdirSync(path.join(upstream, 'schemas'), { recursive: true });
  fs.mkdirSync(path.join(upstream, 'templates'), { recursive: true });
  fs.mkdirSync(path.join(upstream, 'scripts'), { recursive: true });
  fs.writeFileSync(path.join(upstream, 'protocol', 'version.json'), '{"protocol_version":"0.1.0"}\n');
  fs.writeFileSync(path.join(upstream, 'protocol', '00-roles.md'), '# Roles\n');
  fs.writeFileSync(path.join(upstream, 'schemas', 'task.schema.json'), '{}\n');
  fs.writeFileSync(path.join(upstream, 'templates', 'task.md'), '# Task\n');
  const sentinel = path.join(upstream, 'SENTINEL');
  fs.writeFileSync(
    path.join(upstream, 'scripts', 'evil.mjs'),
    `import fs from 'node:fs';\nfs.writeFileSync(${JSON.stringify(sentinel)}, 'ran');\n`,
  );
  git(upstream, ['init', '-b', 'main']);
  git(upstream, ['add', '.']);
  git(upstream, ['commit', '-m', 'data']);
  const sha = git(upstream, ['rev-parse', 'HEAD']).trim();
  const dest = tempDir('export-dest');
  const result = spawnSync(process.execPath, [
    script,
    '--repo',
    upstream,
    '--sha',
    sha,
    '--dest',
    dest,
  ], { encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(fs.existsSync(path.join(dest, 'protocol', 'version.json')), true);
  assert.equal(fs.existsSync(path.join(dest, 'schemas', 'task.schema.json')), true);
  assert.equal(fs.existsSync(path.join(dest, 'templates', 'task.md')), true);
  assert.equal(fs.existsSync(path.join(dest, 'scripts')), false);
  assert.equal(fs.existsSync(sentinel), false);
});
