import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import Ajv from 'ajv/dist/2020.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const ajv = new Ajv({ allErrors: true, strict: true });

function load(rel) {
  return JSON.parse(fs.readFileSync(path.join(root, rel), 'utf8'));
}

const validators = {
  task: ajv.compile(load('schemas/task.schema.json')),
  report: ajv.compile(load('schemas/report.schema.json')),
  verdict: ajv.compile(load('schemas/verdict.schema.json')),
};

test('protocol version is 0.1.0', () => {
  const version = load('protocol/version.json');
  const pkg = load('package.json');
  assert.equal(version.protocol_version, '0.1.0');
  assert.equal(pkg.version, version.protocol_version);
});

test('valid examples match their schemas', () => {
  for (const name of ['task', 'report', 'verdict']) {
    const valid = validators[name](load(`schemas/examples/${name}.example.json`));
    assert.equal(valid, true, ajv.errorsText(validators[name].errors));
  }
});

test('invalid documents are rejected', () => {
  const cases = [
    ['report', 'schemas/examples/invalid/report-not-checked-pass.json'],
    ['report', 'schemas/examples/invalid/report-with-decision.json'],
    ['report', 'schemas/examples/invalid/report-missing-exit-code.json'],
    ['verdict', 'schemas/examples/invalid/verdict-missing-sha.json'],
    ['verdict', 'schemas/examples/invalid/verdict-self-issued.json'],
  ];
  for (const [name, rel] of cases) {
    const valid = validators[name](load(rel));
    assert.equal(valid, false, `${rel} should be invalid`);
  }
});
