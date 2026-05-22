import { execFileSync } from 'node:child_process';
import { appendFileSync, readFileSync } from 'node:fs';

const infoPlistPath = 'macos/com.jingjing2222.macdisplaybar-macOS/Info.plist';
const packageVersion = JSON.parse(readFileSync('package.json', 'utf8')).version;
const currentVersion = readInfoVersion(readFileSync(infoPlistPath, 'utf8'));
const baseSha = process.env.BASE_SHA;
const outputPath = process.env.GITHUB_OUTPUT;
let previousVersion = '';

if (packageVersion !== currentVersion) {
  console.error(
    `::error::package.json version (${packageVersion}) must match ${infoPlistPath} CFBundleShortVersionString (${currentVersion}).`,
  );
  process.exit(1);
}

if (baseSha && !/^0+$/.test(baseSha)) {
  try {
    previousVersion = readInfoVersion(
      git(['show', `${baseSha}:${infoPlistPath}`]),
    );
  } catch {
    previousVersion = '';
  }
}

const versionChanged =
  previousVersion !== '' && previousVersion !== currentVersion;

writeOutput('version', currentVersion);
writeOutput('tag', `v${currentVersion}`);
writeOutput('previous_version', previousVersion);
writeOutput('version_changed', String(versionChanged));

console.log(
  versionChanged
    ? `Release required: ${previousVersion} -> ${currentVersion}`
    : `No release required. Version: ${currentVersion}`,
);

function git(args) {
  return execFileSync('git', args, { encoding: 'utf8' }).trim();
}

function readInfoVersion(plist) {
  const match = plist.match(
    /<key>CFBundleShortVersionString<\/key>\s*<string>([^<]+)<\/string>/,
  );

  if (!match) {
    throw new Error(
      `${infoPlistPath} has no CFBundleShortVersionString string.`,
    );
  }

  return match[1];
}

function writeOutput(name, value) {
  if (outputPath) {
    appendFileSync(outputPath, `${name}=${value}\n`);
  }
}
