import fs from 'node:fs';
import path from 'node:path';
import { UnsafePathError, assertContainedRelative } from './safe-path.mjs';

function parseVersion(text) {
  try {
    return JSON.parse(text);
  } catch {
    throw incompatible('incompatible protocol data: protocol/version.json is not valid JSON');
  }
}

const TEMPLATE_NAMES = ['task.md', 'report.md', 'verdict.md'];

function incompatible(message) {
  const error = new Error(`${message}; refusing to execute upstream scripts`);
  error.code = 'INCOMPATIBLE_PROTOCOL';
  return error;
}

function contained(root, relPath) {
  try {
    return assertContainedRelative(root, relPath);
  } catch (error) {
    if (error instanceof UnsafePathError) throw error;
    throw error;
  }
}

function lstatOrMissing(absolutePath) {
  try {
    return fs.lstatSync(absolutePath);
  } catch (error) {
    if (error.code === 'ENOENT') return null;
    throw error;
  }
}

function readRegularFile(root, relPath) {
  const absolutePath = contained(root, relPath);
  const stat = lstatOrMissing(absolutePath);
  if (!stat || stat.isSymbolicLink() || !stat.isFile()) {
    throw incompatible(`incompatible protocol data: ${relPath} is not a regular file`);
  }
  return fs.readFileSync(absolutePath, 'utf8').replace(/\r\n/g, '\n').trimEnd();
}

function regularDirectory(root, relPath) {
  const absolutePath = contained(root, relPath);
  const stat = lstatOrMissing(absolutePath);
  if (!stat || stat.isSymbolicLink() || !stat.isDirectory()) {
    throw incompatible(`incompatible protocol data: ${relPath} is not a real directory`);
  }
  return absolutePath;
}

export function readProtocolSources(protocolRoot) {
  const versionText = readRegularFile(protocolRoot, path.join('protocol', 'version.json'));
  const versionDoc = parseVersion(versionText);
  if (!versionDoc || typeof versionDoc.protocol_version !== 'string' || versionDoc.protocol_version.length === 0) {
    throw incompatible('incompatible protocol data: protocol_version is missing');
  }

  const protocolDir = regularDirectory(protocolRoot, 'protocol');
  const markdownNames = fs
    .readdirSync(protocolDir)
    .filter((name) => name.endsWith('.md'))
    .sort();
  if (markdownNames.length === 0) {
    throw incompatible('incompatible protocol data: protocol/*.md is missing');
  }
  const protocolMarkdown = markdownNames
    .map((name) => readRegularFile(protocolRoot, path.join('protocol', name)))
    .join('\n\n');

  const templates = {};
  regularDirectory(protocolRoot, 'templates');
  for (const name of TEMPLATE_NAMES) {
    templates[name] = readRegularFile(protocolRoot, path.join('templates', name));
  }

  return {
    protocolVersion: versionDoc.protocol_version,
    protocolMarkdown,
    templates,
  };
}
