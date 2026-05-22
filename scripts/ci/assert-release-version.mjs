import { readFileSync } from 'node:fs';
import { basename } from 'node:path';

const infoPlistPath = 'macos/com.jingjing2222.macdisplaybar-macOS/Info.plist';

const packageVersion = JSON.parse(readFileSync('package.json', 'utf8')).version;
const infoVersion = readInfoVersion(readFileSync(infoPlistPath, 'utf8'));
const tag = process.env.RELEASE_TAG ?? '';
const tagVersion = tag.startsWith('v') ? tag.slice(1) : tag;

const errors = [];

if (!tagVersion) {
  errors.push('RELEASE_TAG is required.');
}

if (packageVersion !== infoVersion) {
  errors.push(
    `package.json version (${packageVersion}) must match ${basename(infoPlistPath)} CFBundleShortVersionString (${infoVersion}).`,
  );
}

if (tagVersion && packageVersion !== tagVersion) {
  errors.push(
    `Release tag (${tag}) must match package.json version (${packageVersion}).`,
  );
}

if (errors.length > 0) {
  for (const error of errors) {
    console.error(`::error::${error}`);
  }
  process.exit(1);
}

console.log(`Release version OK: ${packageVersion}`);

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
