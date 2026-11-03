import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { testGitEnv } from '../helpers/git-env.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const syncScript = path.join(root, 'scripts', 'sync-pin.mjs');
const generateScript = path.join(root, 'scripts', 'generate-adapters.mjs');

function tempDir(name) {
  return fs.mkdtempSync(path.join(os.tmpdir(), `agentic-${name}-`));
}

function git(cwd, args) {
  const result = spawnSync('git', args, { cwd, encoding: 'utf8', env: testGitEnv });
  if (result.status !== 0) {
    throw new Error(`git ${args.join(' ')} failed\n${result.stderr || result.stdout}`);
  }
  return result.stdout;
}

function runSync(args) {
  return spawnSync(process.execPath, [syncScript, ...args], { encoding: 'utf8' });
}

function writeProtocol(dir, text) {
  fs.mkdirSync(path.join(dir, 'protocol'), { recursive: true });
  fs.mkdirSync(path.join(dir, 'schemas'), { recursive: true });
  fs.mkdirSync(path.join(dir, 'templates'), { recursive: true });
  fs.writeFileSync(path.join(dir, 'protocol', 'version.json'), '{"protocol_version":"0.1.0"}\n');
  fs.writeFileSync(path.join(dir, 'protocol', '00-roles.md'), `# Roles\n\n${text}\n`);
  fs.writeFileSync(path.join(dir, 'schemas', 'task.schema.json'), '{}\n');
  fs.writeFileSync(path.join(dir, 'templates', 'task.md'), '# Task\n');
  fs.writeFileSync(path.join(dir, 'templates', 'report.md'), '# Report\n');
  fs.writeFileSync(path.join(dir, 'templates', 'verdict.md'), '# Verdict\n');
}

function writeEvil(dir) {
  const sentinel = path.join(dir, 'SENTINEL');
  fs.mkdirSync(path.join(dir, 'scripts'), { recursive: true });
  fs.writeFileSync(
    path.join(dir, 'scripts', 'evil.mjs'),
    `import fs from 'node:fs';\nfs.writeFileSync(${JSON.stringify(sentinel)}, 'ran');\n`,
  );
  return sentinel;
}

function writeConfig(dir, sha) {
  const config = {
    protocol_repository: 'local/protocol',
    vendor_path: '.agentic/vendor/protocol',
    protocol_version: '0.1.0',
    protocol_ref: sha,
  };
  fs.mkdirSync(path.join(dir, '.agentic'), { recursive: true });
  fs.writeFileSync(path.join(dir, '.agentic', 'config.json'), `${JSON.stringify(config, null, 2)}\n`);
}

function readConfig(dir) {
  return JSON.parse(fs.readFileSync(path.join(dir, '.agentic', 'config.json'), 'utf8'));
}

test('equal pin is unchanged without a vendor checkout', () => {
  const consumer = tempDir('unchanged');
  const sha = 'a'.repeat(40);
  writeConfig(consumer, sha);
  const result = runSync(['--upstream-sha', sha, '--target', consumer]);
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /SYNC_UNCHANGED/);
  assert.equal(readConfig(consumer).protocol_ref, sha);
});

test('sync updates a descendant and does not execute protocol scripts', () => {
  const upstream = tempDir('sync-up');
  writeProtocol(upstream, 'rule A');
  writeEvil(upstream);
  git(upstream, ['init', '-b', 'main']);
  git(upstream, ['add', '.']);
  git(upstream, ['commit', '-m', 'A']);
  const shaA = git(upstream, ['rev-parse', 'HEAD']).trim();
  writeProtocol(upstream, 'rule B');
  git(upstream, ['add', '.']);
  git(upstream, ['commit', '-m', 'B']);
  const shaB = git(upstream, ['rev-parse', 'HEAD']).trim();

  const consumer = tempDir('sync-consumer');
  git(consumer, ['init', '-b', 'main']);
  fs.mkdirSync(path.join(consumer, '.agentic', 'vendor'), { recursive: true });
  git(consumer, ['clone', upstream, '.agentic/vendor/protocol']);
  const vendor = path.join(consumer, '.agentic', 'vendor', 'protocol');
  git(vendor, ['checkout', shaA]);
  git(consumer, ['add', '.agentic/vendor/protocol']);
  writeConfig(consumer, shaA);

  const data = tempDir('sync-data');
  writeProtocol(data, 'rule B');
  const sentinel = writeEvil(data);
  const dry = runSync([
    '--upstream-sha',
    shaB,
    '--protocol-data',
    data,
    '--target',
    consumer,
  ]);
  assert.equal(dry.status, 0, dry.stderr);
  assert.match(dry.stdout, /SYNC_DRY_RUN/);
  assert.equal(readConfig(consumer).protocol_ref, shaA);
  assert.equal(fs.existsSync(path.join(consumer, '.cursor', 'rules', 'agentic.mdc')), false);

  const updated = runSync([
    '--write',
    '--upstream-sha',
    shaB,
    '--protocol-data',
    data,
    '--target',
    consumer,
  ]);
  assert.equal(updated.status, 0, updated.stderr);
  assert.match(updated.stdout, /SYNC_UPDATED/);
  assert.equal(fs.existsSync(sentinel), false);
  assert.equal(readConfig(consumer).protocol_ref, shaB);
  const rule = fs.readFileSync(path.join(consumer, '.cursor', 'rules', 'agentic.mdc'), 'utf8');
  assert.match(rule, /rule B/);
  assert.match(rule, new RegExp(`source_sha: ${shaB}`));
  const indexed = git(consumer, ['ls-files', '-s', '--', '.agentic/vendor/protocol']);
  assert.match(indexed, new RegExp(`160000 ${shaB}`));

  const again = runSync([
    '--write',
    '--upstream-sha',
    shaB,
    '--protocol-data',
    data,
    '--target',
    consumer,
  ]);
  assert.equal(again.status, 0, again.stderr);
  assert.match(again.stdout, /SYNC_UNCHANGED/);

  git(upstream, ['checkout', '--orphan', 'side']);
  git(upstream, ['rm', '-rf', '.']);
  writeProtocol(upstream, 'rule C');
  git(upstream, ['add', '.']);
  git(upstream, ['commit', '-m', 'C']);
  const shaC = git(upstream, ['rev-parse', 'HEAD']).trim();
  git(vendor, ['fetch', 'origin', 'side']);
  const refused = runSync(['--write', '--upstream-sha', shaC, '--target', consumer]);
  assert.equal(refused.status, 0, refused.stderr);
  assert.match(refused.stdout, /SYNC_REFUSED/);
  assert.equal(readConfig(consumer).protocol_ref, shaB);

  const missing = runSync([
    '--write',
    '--upstream-sha',
    'b'.repeat(40),
    '--target',
    consumer,
  ]);
  assert.equal(missing.status, 3, missing.stdout);
  assert.match(missing.stderr, /Refusing to execute scripts/);
  assert.equal(readConfig(consumer).protocol_ref, shaB);
});

test('incompatible protocol data does not execute scripts or move the pin', () => {
  const upstream = tempDir('bad-up');
  writeProtocol(upstream, 'rule A');
  git(upstream, ['init', '-b', 'main']);
  git(upstream, ['add', '.']);
  git(upstream, ['commit', '-m', 'A']);
  const shaA = git(upstream, ['rev-parse', 'HEAD']).trim();
  fs.writeFileSync(path.join(upstream, 'protocol', '00-roles.md'), '# Roles\n\nrule B\n');
  git(upstream, ['add', '.']);
  git(upstream, ['commit', '-m', 'B']);
  const shaB = git(upstream, ['rev-parse', 'HEAD']).trim();

  const consumer = tempDir('bad-consumer');
  git(consumer, ['init', '-b', 'main']);
  fs.mkdirSync(path.join(consumer, '.agentic', 'vendor'), { recursive: true });
  git(consumer, ['clone', upstream, '.agentic/vendor/protocol']);
  writeConfig(consumer, shaA);

  const data = tempDir('bad-data');
  const sentinel = writeEvil(data);
  const result = runSync([
    '--write',
    '--upstream-sha',
    shaB,
    '--protocol-data',
    data,
    '--target',
    consumer,
  ]);
  assert.equal(result.status, 3, result.stdout);
  assert.match(result.stderr, /refusing to execute upstream scripts/i);
  assert.equal(fs.existsSync(sentinel), false);
  assert.equal(readConfig(consumer).protocol_ref, shaA);
});

test('sync stops when an adapter file is user-owned', () => {
  const upstream = tempDir('conflict-up');
  writeProtocol(upstream, 'rule A');
  git(upstream, ['init', '-b', 'main']);
  git(upstream, ['add', '.']);
  git(upstream, ['commit', '-m', 'A']);
  const shaA = git(upstream, ['rev-parse', 'HEAD']).trim();
  fs.writeFileSync(path.join(upstream, 'protocol', '00-roles.md'), '# Roles\n\nrule B\n');
  git(upstream, ['add', '.']);
  git(upstream, ['commit', '-m', 'B']);
  const shaB = git(upstream, ['rev-parse', 'HEAD']).trim();

  const consumer = tempDir('conflict-consumer');
  git(consumer, ['init', '-b', 'main']);
  fs.mkdirSync(path.join(consumer, '.agentic', 'vendor'), { recursive: true });
  git(consumer, ['clone', upstream, '.agentic/vendor/protocol']);
  git(path.join(consumer, '.agentic', 'vendor', 'protocol'), ['checkout', shaA]);
  git(consumer, ['add', '.agentic/vendor/protocol']);
  writeConfig(consumer, shaA);
  const ruleDir = path.join(consumer, '.cursor', 'rules');
  fs.mkdirSync(ruleDir, { recursive: true });
  const userRule = path.join(ruleDir, 'agentic.mdc');
  fs.writeFileSync(userRule, 'keep this user rule\n');
  const agents = path.join(consumer, 'AGENTS.md');
  fs.writeFileSync(agents, 'keep agents\n');

  const data = tempDir('conflict-data');
  writeProtocol(data, 'rule B');
  const result = runSync([
    '--write',
    '--upstream-sha',
    shaB,
    '--protocol-data',
    data,
    '--target',
    consumer,
  ]);
  assert.equal(result.status, 2, result.stderr);
  assert.match(result.stderr, /conflict: refusing to overwrite/);
  assert.equal(fs.readFileSync(userRule, 'utf8'), 'keep this user rule\n');
  assert.equal(fs.readFileSync(agents, 'utf8'), 'keep agents\n');
  assert.equal(readConfig(consumer).protocol_ref, shaA);
  assert.equal(generateScript.length > 0, true);
});
