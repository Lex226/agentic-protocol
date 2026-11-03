import fs from 'node:fs';
import path from 'node:path';
import { MARKER, OUTPUT_PATHS } from './render.mjs';
import { UnsafePathError, assertContainedRelative } from './safe-path.mjs';

function locate(targetRoot, rel) {
  try {
    return { abs: assertContainedRelative(targetRoot, rel), error: null };
  } catch (error) {
    if (error instanceof UnsafePathError || error.code === 'UNSAFE_PATH') {
      return { abs: null, error };
    }
    throw error;
  }
}

export function inspectTargets(targetRoot, rendered) {
  const conflicts = [];
  const drifts = [];
  const unsafe = [];
  for (const rel of OUTPUT_PATHS) {
    const located = locate(targetRoot, rel);
    if (located.error) {
      unsafe.push(located.error.message);
      continue;
    }
    let stat;
    try {
      stat = fs.lstatSync(located.abs);
    } catch (error) {
      if (error.code === 'ENOENT') {
        drifts.push(rel);
        continue;
      }
      throw error;
    }
    if (stat.isSymbolicLink() || !stat.isFile()) {
      unsafe.push(`refusing symlink at ${located.abs}`);
      continue;
    }
    const current = fs.readFileSync(located.abs, 'utf8').replace(/\r\n/g, '\n');
    if (!current.includes(MARKER)) {
      conflicts.push(located.abs);
      continue;
    }
    if (current !== rendered.get(rel)) drifts.push(rel);
  }
  return { conflicts, drifts, unsafe };
}

function writeRegularFile(absolutePath, body) {
  const stat = fs.existsSync(absolutePath) ? fs.lstatSync(absolutePath) : null;
  if (stat?.isSymbolicLink()) {
    throw new UnsafePathError(`refusing symlink at ${absolutePath}`);
  }
  const handle = fs.openSync(absolutePath, 'w');
  try {
    fs.writeFileSync(handle, body);
  } finally {
    fs.closeSync(handle);
  }
}

export function writeTargets(targetRoot, rendered) {
  const planned = OUTPUT_PATHS.map((rel) => ({
    rel,
    abs: assertContainedRelative(targetRoot, rel),
    body: rendered.get(rel),
  }));
  for (const item of planned) {
    fs.mkdirSync(path.dirname(item.abs), { recursive: true });
    assertContainedRelative(targetRoot, item.rel);
    writeRegularFile(item.abs, item.body);
  }
}
