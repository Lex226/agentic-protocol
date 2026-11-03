import fs from 'node:fs';
import path from 'node:path';

const TEMPLATE_NAMES = ['task.md', 'report.md', 'verdict.md'];

function readText(filePath) {
  return fs.readFileSync(filePath, 'utf8').replace(/\r\n/g, '\n').trimEnd();
}

function incompatible(message) {
  const error = new Error(
    `${message}; refusing to execute upstream scripts`,
  );
  error.code = 'INCOMPATIBLE_PROTOCOL';
  return error;
}

export function readProtocolSources(protocolRoot) {
  const protocolDir = path.join(protocolRoot, 'protocol');
  const versionPath = path.join(protocolDir, 'version.json');
  if (!fs.existsSync(versionPath) || !fs.statSync(versionPath).isFile()) {
    throw incompatible('incompatible protocol data: protocol/version.json is missing');
  }

  let versionDoc;
  try {
    versionDoc = JSON.parse(fs.readFileSync(versionPath, 'utf8'));
  } catch (cause) {
    throw incompatible('incompatible protocol data: protocol/version.json is not valid JSON');
  }

  if (!versionDoc || typeof versionDoc.protocol_version !== 'string' || versionDoc.protocol_version.length === 0) {
    throw incompatible('incompatible protocol data: protocol_version is missing');
  }

  if (!fs.existsSync(protocolDir) || !fs.statSync(protocolDir).isDirectory()) {
    throw incompatible('incompatible protocol data: protocol/ is missing');
  }

  const markdownNames = fs
    .readdirSync(protocolDir)
    .filter((name) => name.endsWith('.md'))
    .sort();
  if (markdownNames.length === 0) {
    throw incompatible('incompatible protocol data: protocol/*.md is missing');
  }

  const protocolMarkdown = markdownNames
    .map((name) => readText(path.join(protocolDir, name)))
    .join('\n\n');

  const templates = {};
  for (const name of TEMPLATE_NAMES) {
    const templatePath = path.join(protocolRoot, 'templates', name);
    if (!fs.existsSync(templatePath) || !fs.statSync(templatePath).isFile()) {
      throw incompatible(`incompatible protocol data: templates/${name} is missing`);
    }
    templates[name] = readText(templatePath);
  }

  return {
    protocolVersion: versionDoc.protocol_version,
    protocolMarkdown,
    templates,
  };
}
