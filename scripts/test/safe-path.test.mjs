import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { readProtocolSources } from '../lib/source.mjs';

function tempDir(name) {
  return fs.mkdtempSync(path.join(os.tmpdir(), `agentic-${name}-`));
}

function writeProtocol(dir) {
  fs.mkdirSync(path.join(dir, 'protocol'), { recursive: true });
  fs.mkdirSync(path.join(dir, 'templates'), { recursive: true });
  fs.writeFileSync(path.join(dir, 'protocol', 'version.json'), '{"protocol_version":"0.1.0"}\n');
  fs.writeFileSync(path.join(dir, 'protocol', '00-roles.md'), '# Roles\n\ninside\n');
  fs.writeFileSync(path.join(dir, 'templates', 'task.md'), '# Task\n');
  fs.writeFileSync(path.join(dir, 'templates', 'report.md'), '# Report\n');
  fs.writeFileSync(path.join(dir, 'templates', 'verdict.md'), '# Verdict\n');
}

function linkDirectory(target, linkPath) {
  fs.symlinkSync(target, linkPath, process.platform === 'win32' ? 'junction' : 'dir');
}

test('readProtocolSources refuses a templates directory link and a linked parent', () => {
  const outside = tempDir('templates-outside');
  const marker = path.join(outside, 'marker.txt');
  fs.writeFileSync(marker, 'SAFE-MARKER');
  fs.mkdirSync(path.join(outside, 'templates'));
  fs.writeFileSync(path.join(outside, 'templates', 'task.md'), '# Task\n');
  fs.writeFileSync(path.join(outside, 'templates', 'report.md'), '# Report\n');
  fs.writeFileSync(path.join(outside, 'templates', 'verdict.md'), '# Verdict\n');

  const data = tempDir('templates-data');
  writeProtocol(data);
  fs.rmSync(path.join(data, 'templates'), { recursive: true });
  linkDirectory(path.join(outside, 'templates'), path.join(data, 'templates'));
  assert.throws(() => readProtocolSources(data), /refusing symlink/);
  assert.equal(fs.readFileSync(marker, 'utf8'), 'SAFE-MARKER');

  const real = tempDir('real-root');
  writeProtocol(real);
  const parent = tempDir('linked-parent');
  const linkedRoot = path.join(parent, 'root');
  linkDirectory(real, linkedRoot);
  assert.throws(() => readProtocolSources(linkedRoot), /refusing symlink/);
  assert.equal(fs.readFileSync(marker, 'utf8'), 'SAFE-MARKER');
});
