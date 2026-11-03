import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const verifyScript = path.join(root, 'scripts', 'verify-pin.mjs');
const generateScript = path.join(root, 'scripts', 'generate-adapters.mjs');

function tempDir(name) {
  return fs.mkdtempSync(path.join(os.tmpdir(), `agentic-${name}-`));
}

function git(cwd, args) {
  const result = spawnSync('git', args, { cwd, encoding: 'utf8' });
  assert.equal(result.status, 0, `git ${args.join(' ')}\n${result.stderr}`);
  return result.stdout;
}

function writeProtocol(dir) {
  fs.mkdirSync(path.join(dir, 'protocol'), { recursive: true });
  fs.mkdirSync(path.join(dir, 'templates'), { recursive: true });
  fs.writeFileSync(path.join(dir, 'protocol', 'version.json'), '{"protocol_version":"0.1.0"}\n');
  fs.writeFileSync(path.join(dir, 'protocol', '00-roles.md'), '# Roles\n\nPinned rule.\n');
  fs.writeFileSync(path.join(dir, 'templates', 'task.md'), '# Task\n');
  fs.writeFileSync(path.join(dir, 'templates', 'report.md'), '# Report\n');
  fs.writeFileSync(path.join(dir, 'templates', 'verdict.md'), '# Verdict\n');
}

test('verify-pin accepts a matching gitlink and rejects a moved config SHA', () => {
  const upstream = tempDir('verify-up');
  writeProtocol(upstream);
  git(upstream, ['init', '-b', 'main']);
  git(upstream, ['add', '.']);
  git(upstream, ['commit', '-m', 'proto']);
  const sha = git(upstream, ['rev-parse', 'HEAD']).trim();

  const consumer = tempDir('verify-consumer');
  git(consumer, ['init', '-b', 'main']);
  fs.mkdirSync(path.join(consumer, '.agentic', 'vendor'), { recursive: true });
  git(consumer, ['clone', upstream, '.agentic/vendor/protocol']);
  const config = {
    protocol_repository: 'local/protocol',
    vendor_path: '.agentic/vendor/protocol',
    protocol_version: '0.1.0',
    protocol_ref: sha,
  };
  fs.writeFileSync(path.join(consumer, '.agentic', 'config.json'), `${JSON.stringify(config, null, 2)}\n`);
  const generated = spawnSync(process.execPath, [
    generateScript,
    '--write',
    '--protocol-root',
    path.join(consumer, '.agentic', 'vendor', 'protocol'),
    '--source-sha',
    sha,
    '--target',
    consumer,
  ], { encoding: 'utf8' });
  assert.equal(generated.status, 0, generated.stderr);
  git(consumer, ['add', '.']);
  git(consumer, ['commit', '-m', 'pin']);

  const ok = spawnSync(process.execPath, [verifyScript, '--target', consumer], { encoding: 'utf8' });
  assert.equal(ok.status, 0, ok.stderr);
  assert.match(ok.stdout, /pin matches adapters/);

  config.protocol_ref = 'b'.repeat(40);
  fs.writeFileSync(path.join(consumer, '.agentic', 'config.json'), `${JSON.stringify(config, null, 2)}\n`);
  git(consumer, ['add', '.agentic/config.json']);
  git(consumer, ['commit', '-m', 'move pin']);
  const bad = spawnSync(process.execPath, [verifyScript, '--target', consumer], { encoding: 'utf8' });
  assert.equal(bad.status, 1, bad.stdout);
  assert.match(bad.stderr, /does not match protocol_ref/);
});
