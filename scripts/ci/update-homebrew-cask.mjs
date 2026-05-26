import { readFileSync, writeFileSync } from 'node:fs';

const [caskPath, version, sha256] = process.argv.slice(2);

if (!caskPath || !version || !sha256) {
  console.error(
    'Usage: node scripts/ci/update-homebrew-cask.mjs <cask-path> <version> <sha256>',
  );
  process.exit(1);
}

if (!/^[a-f0-9]{64}$/.test(sha256)) {
  console.error(`Invalid sha256: ${sha256}`);
  process.exit(1);
}

const before = readFileSync(caskPath, 'utf8');
const hadVersion = /version "[^"]+"/.test(before);
const hadSha256 = /sha256 "[a-f0-9]{64}"/.test(before);

if (!hadVersion || !hadSha256) {
  console.error('Cask does not contain replaceable version and sha256 fields.');
  process.exit(1);
}

const after = before
  .replace(/version "[^"]+"/, `version "${version}"`)
  .replace(/sha256 "[a-f0-9]{64}"/, `sha256 "${sha256}"`);

if (
  !after.includes(`version "${version}"`) ||
  !after.includes(`sha256 "${sha256}"`)
) {
  console.error('Cask version or sha256 replacement failed.');
  process.exit(1);
}

if (before === after) {
  console.log('Homebrew cask already up to date.');
} else {
  writeFileSync(caskPath, after);
  console.log(`Updated Homebrew cask to ${version}.`);
}
