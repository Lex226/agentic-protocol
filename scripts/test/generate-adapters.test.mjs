import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const script = path.join(root, 'scripts', 'generate-adapters.mjs');
const sha = 'a'.repeat(40);

function tempDir(name) {
  return fs.mkdtempSync(path.join(os.tmpdir(), `agentic-${name}-`));
}

function run(args, cwd) {
  return spawnSync(process.execPath, [script, ...args], {
    cwd,
    encoding: 'utf8',
  });
}

function outputs(target) {
  return [
    '.cursor/rules/agentic.mdc',
    '.agentic/reviewer-context.md',
    '.agentic/handoff/executor-to-reviewer.md',
    '.agentic/handoff/reviewer-to-executor.md',
  ].map((rel) => path.join(target, rel));
}

test('generator is deterministic and stamps version and source SHA', () => {
  const target = tempDir('gen');
  const args = ['--write', '--target', target, '--protocol-root', root, '--source-sha', sha];
  const first = run(args);
  assert.equal(first.status, 0, first.stderr);
  const before = outputs(target).map((file) => fs.readFileSync(file));
  const second = run(args);
  assert.equal(second.status, 0, second.stderr);
  const after = outputs(target).map((file) => fs.readFileSync(file));
  assert.deepEqual(after, before);

  const cursor = fs.readFileSync(outputs(target)[0], 'utf8');
  const reviewer = fs.readFileSync(outputs(target)[1], 'utf8');
  const toReviewer = fs.readFileSync(outputs(target)[2], 'utf8');
  const toExecutor = fs.readFileSync(outputs(target)[3], 'utf8');
  for (const text of [cursor, reviewer, toReviewer, toExecutor]) {
    assert.equal(text.includes('\r'), false);
    assert.match(text, /agentic-protocol: generated/);
    assert.match(text, /protocol_version: 0\.1\.0/);
    assert.match(text, new RegExp(`source_sha: ${sha}`));
    assert.match(text, /Не выдаёт вердикт ревьюера/);
  }
  assert.match(reviewer, /Perplexity не читает этот файл из репозитория автоматически и не запускается из него/);
  assert.match(toReviewer, /# Отчёт исполнителя/);
  assert.equal(toReviewer.includes('# Вердикт ревьюера'), false);
  assert.match(toExecutor, /# Вердикт ревьюера/);

  const check = run(['--check', '--target', target, '--protocol-root', root, '--source-sha', sha]);
  assert.equal(check.status, 0, check.stderr);
});

test('--check reports a stale adapter and does not rewrite it', () => {
  const target = tempDir('stale');
  const args = ['--protocol-root', root, '--source-sha', sha, '--target', target];
  assert.equal(run(['--write', ...args]).status, 0);
  const file = path.join(target, '.agentic', 'reviewer-context.md');
  const stale = `${fs.readFileSync(file, 'utf8')}\nstale line\n`;
  fs.writeFileSync(file, stale);
  const check = run(['--check', ...args]);
  assert.equal(check.status, 1, check.stderr);
  assert.match(check.stderr, /stale: \.agentic\/reviewer-context\.md/);
  assert.equal(fs.readFileSync(file, 'utf8'), stale);
});

test('an unmarked existing adapter is a conflict and nothing is written', () => {
  const target = tempDir('conflict');
  const ruleDir = path.join(target, '.cursor', 'rules');
  fs.mkdirSync(ruleDir, { recursive: true });
  const userRule = path.join(ruleDir, 'agentic.mdc');
  const personal = path.join(ruleDir, 'personal.mdc');
  const agents = path.join(target, 'AGENTS.md');
  fs.writeFileSync(userRule, 'user rule, do not touch\n');
  fs.writeFileSync(personal, 'personal cursor rule\n');
  fs.writeFileSync(agents, 'personal agents\n');

  const result = run([
    '--write',
    '--target',
    target,
    '--protocol-root',
    root,
    '--source-sha',
    sha,
  ]);
  assert.equal(result.status, 2, result.stderr);
  assert.match(result.stderr, /conflict: refusing to overwrite/);
  assert.match(result.stderr, /no files were written/);
  assert.equal(fs.readFileSync(userRule, 'utf8'), 'user rule, do not touch\n');
  assert.equal(fs.readFileSync(personal, 'utf8'), 'personal cursor rule\n');
  assert.equal(fs.readFileSync(agents, 'utf8'), 'personal agents\n');
  assert.equal(fs.existsSync(path.join(target, '.agentic', 'reviewer-context.md')), false);
});

test('default source SHA is the protocol checkout HEAD', () => {
  const protocol = tempDir('proto');
  fs.mkdirSync(path.join(protocol, 'protocol'), { recursive: true });
  fs.mkdirSync(path.join(protocol, 'templates'), { recursive: true });
  fs.writeFileSync(path.join(protocol, 'protocol', 'version.json'), '{"protocol_version":"0.1.0"}\n');
  fs.writeFileSync(path.join(protocol, 'protocol', '00-roles.md'), '# Roles\n\nLocal rule.\n');
  fs.writeFileSync(path.join(protocol, 'templates', 'task.md'), '# Task\n');
  fs.writeFileSync(path.join(protocol, 'templates', 'report.md'), '# Report\n');
  fs.writeFileSync(path.join(protocol, 'templates', 'verdict.md'), '# Verdict\n');
  const git = (args) => {
    const result = spawnSync('git', args, { cwd: protocol, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout;
  };
  git(['init', '-b', 'main']);
  git(['add', '.']);
  git(['commit', '-m', 'init']);
  const head = git(['rev-parse', 'HEAD']).trim();
  const target = tempDir('default-sha');
  const result = run(['--write', '--protocol-root', protocol, '--target', target]);
  assert.equal(result.status, 0, result.stderr);
  const text = fs.readFileSync(path.join(target, '.cursor', 'rules', 'agentic.mdc'), 'utf8');
  assert.match(text, new RegExp(`source_sha: ${head}`));
});
