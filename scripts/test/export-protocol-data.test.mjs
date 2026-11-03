import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { DATA_PATHS } from '../export-protocol-data.mjs';
import { testGitEnv } from '../helpers/git-env.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const script = path.join(root, 'scripts', 'export-protocol-data.mjs');

function tempDir(name) {
  return fs.mkdtempSync(path.join(os.tmpdir(), `agentic-${name}-`));
}

function git(cwd, args) {
  const result = spawnSync('git', args, { cwd, encoding: 'utf8', env: testGitEnv });
  assert.equal(result.status, 0, `git ${args.join(' ')}\n${result.stderr}`);
  return result.stdout;
}

test('data export allowlist excludes scripts', () => {
  assert.deepEqual(DATA_PATHS, ['protocol', 'schemas', 'templates']);
});

function addGitSymlink(repo, gitPath, targetText) {
  const hashed = spawnSync('git', ['hash-object', '-w', '--stdin'], {
    cwd: repo,
    input: targetText,
    encoding: 'utf8',
    env: testGitEnv,
  });
  assert.equal(hashed.status, 0, hashed.stderr);
  const updated = spawnSync('git', [
    'update-index',
    '--add',
    '--cacheinfo',
    `120000,${hashed.stdout.trim()},${gitPath}`,
  ], {
    cwd: repo,
    encoding: 'utf8',
    env: testGitEnv,
  });
  assert.equal(updated.status, 0, updated.stderr);
}

function exportResult(repo, sha, dest) {
  return spawnSync(process.execPath, [
    script,
    '--repo',
    repo,
    '--sha',
    sha,
    '--dest',
    dest,
  ], { encoding: 'utf8' });
}

test('export copies data and does not run scripts', () => {
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

test('export refuses a markdown symlink and does not touch the outside marker', () => {
  const rootDir = tempDir('export-md-link');
  const marker = path.join(rootDir, 'marker.txt');
  fs.writeFileSync(marker, 'SAFE-MARKER');
  const repo = path.join(rootDir, 'repo');
  fs.mkdirSync(path.join(repo, 'protocol'), { recursive: true });
  fs.mkdirSync(path.join(repo, 'schemas'), { recursive: true });
  fs.mkdirSync(path.join(repo, 'templates'), { recursive: true });
  fs.writeFileSync(path.join(repo, 'protocol', 'version.json'), '{"protocol_version":"0.1.0"}\n');
  fs.writeFileSync(path.join(repo, 'protocol', '00-roles.md'), '# Roles\n');
  fs.writeFileSync(path.join(repo, 'schemas', 'task.schema.json'), '{}\n');
  fs.writeFileSync(path.join(repo, 'templates', 'task.md'), '# Task\n');
  git(repo, ['init', '-b', 'main']);
  git(repo, ['add', '.']);
  addGitSymlink(repo, 'protocol/linked.md', marker);
  git(repo, ['commit', '-m', 'link']);
  const sha = git(repo, ['rev-parse', 'HEAD']).trim();
  const dest = path.join(rootDir, 'dest');
  fs.mkdirSync(dest);
  fs.writeFileSync(path.join(dest, 'canary.txt'), 'CANARY');
  const result = exportResult(repo, sha, dest);
  assert.equal(result.status, 3, result.stdout);
  assert.match(result.stderr, /refusing unsafe git entry 120000/);
  assert.equal(fs.readFileSync(marker, 'utf8'), 'SAFE-MARKER');
  assert.equal(fs.readFileSync(path.join(dest, 'canary.txt'), 'utf8'), 'CANARY');
  assert.equal(fs.existsSync(path.join(dest, 'protocol')), false);
});

test('export refuses a symlink in place of templates and does not touch the outside marker', () => {
  const rootDir = tempDir('export-dir-link');
  const marker = path.join(rootDir, 'marker.txt');
  fs.writeFileSync(marker, 'SAFE-MARKER');
  const repo = path.join(rootDir, 'repo');
  fs.mkdirSync(path.join(repo, 'protocol'), { recursive: true });
  fs.mkdirSync(path.join(repo, 'schemas'), { recursive: true });
  fs.writeFileSync(path.join(repo, 'protocol', 'version.json'), '{"protocol_version":"0.1.0"}\n');
  fs.writeFileSync(path.join(repo, 'protocol', '00-roles.md'), '# Roles\n');
  fs.writeFileSync(path.join(repo, 'schemas', 'task.schema.json'), '{}\n');
  git(repo, ['init', '-b', 'main']);
  git(repo, ['add', '.']);
  addGitSymlink(repo, 'templates', marker);
  git(repo, ['commit', '-m', 'templates-link']);
  const sha = git(repo, ['rev-parse', 'HEAD']).trim();
  const dest = path.join(rootDir, 'dest');
  fs.mkdirSync(dest);
  fs.writeFileSync(path.join(dest, 'canary.txt'), 'CANARY');
  const result = exportResult(repo, sha, dest);
  assert.equal(result.status, 3, result.stdout);
  assert.match(result.stderr, /refusing unsafe git entry 120000/);
  assert.equal(fs.readFileSync(marker, 'utf8'), 'SAFE-MARKER');
  assert.equal(fs.readFileSync(path.join(dest, 'canary.txt'), 'utf8'), 'CANARY');
  assert.equal(fs.existsSync(path.join(dest, 'protocol')), false);
});
