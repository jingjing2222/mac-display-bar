import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';

const infoPlistPath = 'macos/com.jingjing2222.macdisplaybar-macOS/Info.plist';
const outputPath = 'macos/fingerprint-version.txt';

const version = readInfoVersion(readFileSync(infoPlistPath, 'utf8'));
const contents = `CFBundleShortVersionString=${version}\n`;

mkdirSync(dirname(outputPath), { recursive: true });
writeFileSync(outputPath, contents);

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
