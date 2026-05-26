import { execFileSync } from 'node:child_process';
import { appendFileSync, readFileSync } from 'node:fs';

const infoPlistPath = 'macos/com.jingjing2222.macdisplaybar-macOS/Info.plist';
const currentVersion = readInfoVersion(readFileSync(infoPlistPath, 'utf8'));
const baseSha = process.env.BASE_SHA;
const outputPath = process.env.GITHUB_OUTPUT;
let previousVersion = '';

if (baseSha && !/^0+$/.test(baseSha)) {
  try {
    previousVersion = readInfoVersion(
      git(['show', `${baseSha}:${infoPlistPath}`]),
    );
  } catch {
    previousVersion = '';
  }
}

const currentTag = `v${currentVersion}`;
const versionChanged =
  previousVersion !== ''
    ? previousVersion !== currentVersion
    : !tagExists(currentTag);

writeOutput('version', currentVersion);
writeOutput('tag', currentTag);
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

function tagExists(tag) {
  try {
    git(['rev-parse', '--verify', '--quiet', `refs/tags/${tag}`]);
    return true;
  } catch {
    return false;
  }
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
