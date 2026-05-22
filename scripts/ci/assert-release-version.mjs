import { readFileSync } from 'node:fs';

const infoPlistPath = 'macos/com.jingjing2222.macdisplaybar-macOS/Info.plist';

const infoVersion = readInfoVersion(readFileSync(infoPlistPath, 'utf8'));
const tag = process.env.RELEASE_TAG ?? '';
const tagVersion = tag.startsWith('v') ? tag.slice(1) : tag;

const errors = [];

if (!tagVersion) {
  errors.push('RELEASE_TAG is required.');
}

if (tagVersion && infoVersion !== tagVersion) {
  errors.push(
    `Release tag (${tag}) must match ${infoPlistPath} CFBundleShortVersionString (${infoVersion}).`,
  );
}

if (errors.length > 0) {
  for (const error of errors) {
    console.error(`::error::${error}`);
  }
  process.exit(1);
}

console.log(`Release version OK: ${infoVersion}`);

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
