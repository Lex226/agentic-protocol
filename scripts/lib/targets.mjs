import fs from 'node:fs';
import path from 'node:path';
import { MARKER, OUTPUT_PATHS } from './render.mjs';

function readExisting(filePath) {
  return fs.readFileSync(filePath, 'utf8').replace(/\r\n/g, '\n');
}

export function inspectTargets(targetRoot, rendered) {
  const conflicts = [];
  const drifts = [];
  for (const rel of OUTPUT_PATHS) {
    const abs = path.join(targetRoot, rel);
    if (!fs.existsSync(abs)) {
      drifts.push(rel);
      continue;
    }
    const current = readExisting(abs);
    if (!current.includes(MARKER)) {
      conflicts.push(abs);
      continue;
    }
    if (current !== rendered.get(rel)) {
      drifts.push(rel);
    }
  }
  return { conflicts, drifts };
}

export function writeTargets(targetRoot, rendered) {
  for (const rel of OUTPUT_PATHS) {
    const abs = path.join(targetRoot, rel);
    fs.mkdirSync(path.dirname(abs), { recursive: true });
    fs.writeFileSync(abs, rendered.get(rel), 'utf8');
  }
}
