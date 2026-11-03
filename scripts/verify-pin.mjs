import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { MARKER, OUTPUT_PATHS } from './lib/render.mjs';

const SHA_RE = /^[0-9a-f]{40}$/;

function usage() {
  return 'usage: verify-pin.mjs --target <dir>';
}

function parseArgs(argv) {
  const args = { target: '', help: false };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === '--help' || token === '-h') args.help = true;
    else if (token === '--target') {
      const value = argv[i + 1];
      if (!value || value.startsWith('--')) throw new Error('missing value for --target');
      args.target = value;
      i += 1;
    } else {
      throw new Error(`unknown argument: ${token}`);
    }
  }
  return args;
}

function fail(message) {
  console.error(message);
  return 1;
}

export function runVerify(argv) {
  let args;
  try {
    args = parseArgs(argv);
  } catch (error) {
    console.error(error.message);
    console.error(usage());
    return 3;
  }
  if (args.help || !args.target) {
    console.error(usage());
    return 3;
  }

  const targetRoot = path.resolve(args.target);
  const configPath = path.join(targetRoot, '.agentic', 'config.json');
  if (!fs.existsSync(configPath)) return fail(`missing ${configPath}`);
  let config;
  try {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  } catch {
    return fail(`${configPath} is not valid JSON`);
  }
  const vendorPath = typeof config.vendor_path === 'string' ? config.vendor_path.replaceAll('\\', '/') : '';
  if (!vendorPath || !SHA_RE.test(config.protocol_ref || '') || typeof config.protocol_version !== 'string') {
    return fail('config is missing vendor_path, protocol_version, or a 40-character protocol_ref');
  }

  let gitlink = '';
  try {
    gitlink = execFileSync('git', ['rev-parse', `HEAD:${vendorPath}`], {
      cwd: targetRoot,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    }).trim();
  } catch (error) {
    return fail(`gitlink ${vendorPath} is not in HEAD${error.stderr ? `: ${error.stderr.toString().trim()}` : ''}`);
  }
  if (gitlink !== config.protocol_ref) {
    return fail(`gitlink ${gitlink} does not match protocol_ref ${config.protocol_ref}`);
  }

  const versionPath = path.join(targetRoot, vendorPath, 'protocol', 'version.json');
  if (!fs.existsSync(versionPath)) return fail(`missing ${versionPath}`);
  let vendoredVersion = '';
  try {
    vendoredVersion = JSON.parse(fs.readFileSync(versionPath, 'utf8')).protocol_version;
  } catch {
    return fail(`${versionPath} is not valid JSON`);
  }
  if (vendoredVersion !== config.protocol_version) {
    return fail(`vendored protocol_version ${vendoredVersion} does not match config ${config.protocol_version}`);
  }

  for (const rel of OUTPUT_PATHS) {
    const abs = path.join(targetRoot, rel);
    if (!fs.existsSync(abs)) return fail(`missing adapter ${rel}`);
    const text = fs.readFileSync(abs, 'utf8').replace(/\r\n/g, '\n');
    if (!text.includes(MARKER)) return fail(`missing generator marker: ${rel}`);
    if (!text.includes(`protocol_version: ${config.protocol_version}\n`)) {
      return fail(`protocol_version mismatch in ${rel}`);
    }
    if (!text.includes(`source_sha: ${config.protocol_ref}\n`)) {
      return fail(`source_sha mismatch in ${rel}`);
    }
  }

  console.log('pin matches adapters');
  return 0;
}

function isDirectRun() {
  const entry = process.argv[1];
  if (!entry) return false;
  return import.meta.url === pathToFileURL(path.resolve(entry)).href;
}

if (isDirectRun()) {
  process.exit(runVerify(process.argv.slice(2)));
}
