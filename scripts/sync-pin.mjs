import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { readProtocolSources } from './lib/source.mjs';
import { OUTPUT_PATHS, renderAdapters } from './lib/render.mjs';
import { inspectTargets, writeTargets } from './lib/targets.mjs';

const SHA_RE = /^[0-9a-f]{40}$/;
const CONFIG_KEYS = ['protocol_repository', 'vendor_path', 'protocol_version', 'protocol_ref'];

function usage() {
  return 'usage: sync-pin.mjs --upstream-sha <40-hex> --target <dir> [--protocol-data <dir>] [--write]';
}

function parseArgs(argv) {
  const args = {
    write: false,
    upstreamSha: '',
    protocolData: '',
    target: '',
    help: false,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === '--write') args.write = true;
    else if (token === '--help' || token === '-h') args.help = true;
    else if (token === '--upstream-sha' || token === '--protocol-data' || token === '--target') {
      const value = argv[i + 1];
      if (!value || value.startsWith('--')) throw new Error(`missing value for ${token}`);
      i += 1;
      if (token === '--upstream-sha') args.upstreamSha = value;
      if (token === '--protocol-data') args.protocolData = value;
      if (token === '--target') args.target = value;
    } else {
      throw new Error(`unknown argument: ${token}`);
    }
  }
  return args;
}

function git(cwd, args) {
  return execFileSync('git', args, {
    cwd,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
}

function readConfig(targetRoot) {
  const configPath = path.join(targetRoot, '.agentic', 'config.json');
  if (!fs.existsSync(configPath)) {
    throw new Error(`missing ${configPath}`);
  }
  let config;
  try {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  } catch {
    throw new Error(`${configPath} is not valid JSON`);
  }
  for (const key of CONFIG_KEYS) {
    if (!config || typeof config[key] !== 'string' || config[key].length === 0) {
      throw new Error(`config ${key} is missing`);
    }
  }
  if (!SHA_RE.test(config.protocol_ref)) {
    throw new Error('config protocol_ref must be 40 lowercase hex characters');
  }
  return { config, configPath };
}

function writeConfig(configPath, config, protocolVersion, protocolRef) {
  const next = {
    protocol_repository: config.protocol_repository,
    vendor_path: config.vendor_path.replaceAll('\\', '/'),
    protocol_version: protocolVersion,
    protocol_ref: protocolRef,
  };
  const extras = Object.keys(config)
    .filter((key) => !Object.prototype.hasOwnProperty.call(next, key))
    .sort();
  for (const key of extras) next[key] = config[key];
  fs.writeFileSync(configPath, `${JSON.stringify(next, null, 2)}\n`, 'utf8');
}

function commitExists(vendorDir, sha) {
  try {
    git(vendorDir, ['cat-file', '-e', `${sha}^{commit}`]);
    return true;
  } catch (error) {
    if (error.status === 1 || error.status === 128) return false;
    throw error;
  }
}

function isAncestor(vendorDir, pinned, upstream) {
  try {
    git(vendorDir, ['merge-base', '--is-ancestor', pinned, upstream]);
    return true;
  } catch (error) {
    if (error.status === 1) return false;
    throw error;
  }
}

export function runSync(argv) {
  let args;
  try {
    args = parseArgs(argv);
  } catch (error) {
    console.error(error.message);
    console.error(usage());
    return 3;
  }
  if (args.help || !args.target || !args.upstreamSha) {
    console.error(usage());
    return 3;
  }
  if (!SHA_RE.test(args.upstreamSha)) {
    console.error(`upstream SHA must be 40 lowercase hex characters: ${args.upstreamSha}`);
    return 3;
  }

  const targetRoot = path.resolve(args.target);
  let config;
  let configPath;
  try {
    ({ config, configPath } = readConfig(targetRoot));
  } catch (error) {
    console.error(error.message);
    return 3;
  }

  if (config.protocol_ref === args.upstreamSha) {
    console.log('SYNC_UNCHANGED');
    return 0;
  }

  const vendorDir = path.resolve(targetRoot, config.vendor_path);
  let pinnedPresent = false;
  let upstreamPresent = false;
  try {
    pinnedPresent = commitExists(vendorDir, config.protocol_ref);
    upstreamPresent = commitExists(vendorDir, args.upstreamSha);
  } catch (error) {
    console.error(error.stderr?.toString?.() || error.message);
    return 3;
  }
  if (!pinnedPresent || !upstreamPresent) {
    console.error(
      'upstream commit is not present in the vendor repository. Fetch it first. Refusing to execute scripts from an unverified protocol revision.',
    );
    return 3;
  }

  let ancestor = false;
  try {
    ancestor = isAncestor(vendorDir, config.protocol_ref, args.upstreamSha);
  } catch (error) {
    console.error(error.stderr?.toString?.() || error.message);
    return 3;
  }
  if (!ancestor) {
    console.log('SYNC_REFUSED pinned SHA is not an ancestor of upstream; no pull request will be opened');
    return 0;
  }

  if (!args.protocolData) {
    console.error('protocol data directory is required to update a pin');
    return 3;
  }

  let sources;
  try {
    sources = readProtocolSources(path.resolve(args.protocolData));
  } catch (error) {
    console.error(error.message);
    return 3;
  }

  const rendered = renderAdapters({
    protocolVersion: sources.protocolVersion,
    sourceSha: args.upstreamSha,
    protocolMarkdown: sources.protocolMarkdown,
    templates: sources.templates,
  });
  const { conflicts, unsafe } = inspectTargets(targetRoot, rendered);
  if (unsafe.length > 0) {
    for (const item of unsafe) console.error(`unsafe path: ${item}`);
    console.error('no files were written');
    return 3;
  }
  if (conflicts.length > 0) {
    for (const abs of conflicts) {
      console.error(`conflict: refusing to overwrite ${abs} (not generated by agentic-protocol)`);
    }
    console.error('no files were written');
    return 2;
  }

  if (!args.write) {
    console.log('SYNC_DRY_RUN');
    return 0;
  }

  writeConfig(configPath, config, sources.protocolVersion, args.upstreamSha);
  writeTargets(targetRoot, rendered);
  const vendorPath = config.vendor_path.replaceAll('\\', '/');
  try {
    git(targetRoot, ['update-index', '--add', '--cacheinfo', `160000,${args.upstreamSha},${vendorPath}`]);
    git(targetRoot, ['add', '--', '.agentic/config.json', ...OUTPUT_PATHS]);
  } catch (error) {
    console.error(error.stderr?.toString?.() || error.message);
    return 3;
  }
  console.log('SYNC_UPDATED');
  return 0;
}

function isDirectRun() {
  const entry = process.argv[1];
  if (!entry) return false;
  return import.meta.url === pathToFileURL(path.resolve(entry)).href;
}

if (isDirectRun()) {
  process.exit(runSync(process.argv.slice(2)));
}
