import fs from 'node:fs';
import path from 'node:path';

export class UnsafePathError extends Error {
  constructor(message) {
    super(message);
    this.name = 'UnsafePathError';
    this.code = 'UNSAFE_PATH';
  }
}

function partsOf(value) {
  return value.split(/[/\\]/);
}

export function isWellFormedGitPath(gitPath) {
  if (typeof gitPath !== 'string' || gitPath.length === 0 || gitPath.includes('\0') || gitPath.includes('\\')) {
    return false;
  }
  if (path.posix.isAbsolute(gitPath)) return false;
  const parts = gitPath.split('/');
  if (parts.some((part) => part.length === 0 || part === '.' || part === '..')) return false;
  return path.posix.normalize(gitPath) === gitPath;
}

export function classifyGitPath(gitPath, allowedRoots) {
  if (!isWellFormedGitPath(gitPath)) return 'unsafe';
  if (!allowedRoots.includes(gitPath.split('/')[0])) return 'ignored';
  return 'data';
}

function isLink(stat, absolutePath) {
  if (stat.isSymbolicLink()) return true;
  try {
    fs.readlinkSync(absolutePath);
    return true;
  } catch (error) {
    if (error.code === 'EINVAL' || error.code === 'ENOTSUP' || error.code === 'UNKNOWN' || error.code === 'ENOENT') {
      return false;
    }
    throw error;
  }
}

export function assertNoSymlinkChain(absolutePath) {
  const resolved = path.resolve(absolutePath);
  const parsed = path.parse(resolved);
  let current = parsed.root;
  const parts = resolved.slice(parsed.root.length).split(path.sep).filter((part) => part.length > 0);
  for (const part of parts) {
    current = path.join(current, part);
    let stat;
    try {
      stat = fs.lstatSync(current);
    } catch (error) {
      if (error.code === 'ENOENT') return;
      throw error;
    }
    if (isLink(stat, current)) {
      throw new UnsafePathError(`refusing symlink at ${current}`);
    }
  }
}

export function assertContainedRelative(root, relPath) {
  if (typeof relPath !== 'string' || relPath.length === 0 || relPath.includes('\0')) {
    throw new UnsafePathError('refusing an empty or NUL path');
  }
  if (path.isAbsolute(relPath) || path.win32.isAbsolute(relPath) || path.posix.isAbsolute(relPath)) {
    throw new UnsafePathError(`refusing absolute path ${relPath}`);
  }
  const parts = partsOf(relPath);
  if (parts.some((part) => part.length === 0 || part === '.' || part === '..')) {
    throw new UnsafePathError(`refusing unsafe path ${relPath}`);
  }
  const rootAbs = path.resolve(root);
  const targetAbs = path.resolve(rootAbs, ...parts);
  const relativeParts = path.relative(rootAbs, targetAbs).split(path.sep).filter((part) => part.length > 0);
  if (relativeParts.length !== parts.length || relativeParts.some((part) => part === '..')) {
    throw new UnsafePathError(`refusing path outside root: ${relPath}`);
  }
  assertNoSymlinkChain(rootAbs);
  assertNoSymlinkChain(targetAbs);
  return targetAbs;
}
