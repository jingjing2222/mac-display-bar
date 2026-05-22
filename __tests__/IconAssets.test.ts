import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { inflateSync } from 'node:zlib';

const appIconDir = join(
  process.cwd(),
  'macos/com.jingjing2222.macdisplaybar-macOS/Assets.xcassets/AppIcon.appiconset',
);
const statusIconDir = join(
  process.cwd(),
  'macos/com.jingjing2222.macdisplaybar-macOS/Assets.xcassets/StatusBarIcon.imageset',
);

test('macOS app icon set references all required icon files', () => {
  const contents = JSON.parse(
    readFileSync(join(appIconDir, 'Contents.json'), 'utf8'),
  ) as {
    images: Array<{
      filename?: string;
      idiom: string;
      scale: string;
      size: string;
    }>;
  };

  const requiredIconFiles = [
    '16.png',
    '32.png',
    '64.png',
    '128.png',
    '256.png',
    '512.png',
    '1024.png',
  ];

  for (const filename of requiredIconFiles) {
    expect(existsSync(join(appIconDir, filename))).toBe(true);
  }

  expect(contents.images).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        filename: '16.png',
        idiom: 'mac',
        scale: '1x',
        size: '16x16',
      }),
      expect.objectContaining({
        filename: '32.png',
        idiom: 'mac',
        scale: '2x',
        size: '16x16',
      }),
      expect.objectContaining({
        filename: '64.png',
        idiom: 'mac',
        scale: '2x',
        size: '32x32',
      }),
      expect.objectContaining({
        filename: '1024.png',
        idiom: 'mac',
        scale: '2x',
        size: '512x512',
      }),
    ]),
  );
});

test('menu bar icon asset is available as a template image set', () => {
  const contents = JSON.parse(
    readFileSync(join(statusIconDir, 'Contents.json'), 'utf8'),
  ) as {
    properties?: { 'template-rendering-intent'?: string };
  };

  expect(existsSync(join(statusIconDir, 'status-bar-icon.png'))).toBe(true);
  expect(existsSync(join(statusIconDir, 'status-bar-icon@2x.png'))).toBe(true);
  expect(contents.properties?.['template-rendering-intent']).toBe('template');
});

test('menu bar icon has no opaque white background', () => {
  for (const filename of ['status-bar-icon.png', 'status-bar-icon@2x.png']) {
    const pixels = readPngPixels(join(statusIconDir, filename));

    expect(pixels.transparent).toBeGreaterThan(0);
    expect(pixels.opaqueWhite).toBe(0);
  }
});

function readPngPixels(path: string) {
  const file = readFileSync(path);
  const width = file.readUInt32BE(16);
  const height = file.readUInt32BE(20);
  const idatChunks: Array<Buffer> = [];
  let offset = 8;

  while (offset < file.length) {
    const length = file.readUInt32BE(offset);
    const type = file.toString('ascii', offset + 4, offset + 8);
    const dataStart = offset + 8;
    const dataEnd = dataStart + length;

    if (type === 'IDAT') {
      idatChunks.push(file.subarray(dataStart, dataEnd));
    }

    offset = dataEnd + 4;
  }

  const data = inflateSync(Buffer.concat(idatChunks));
  let cursor = 0;
  let transparent = 0;
  let opaqueWhite = 0;

  for (let y = 0; y < height; y += 1) {
    const filter = data[cursor];
    cursor += 1;
    expect(filter).toBe(0);

    for (let x = 0; x < width; x += 1) {
      const red = data[cursor];
      const green = data[cursor + 1];
      const blue = data[cursor + 2];
      const alpha = data[cursor + 3];
      cursor += 4;

      if (alpha === 0) {
        transparent += 1;
      }

      if (alpha > 0 && red > 245 && green > 245 && blue > 245) {
        opaqueWhite += 1;
      }
    }
  }

  return { opaqueWhite, transparent };
}
