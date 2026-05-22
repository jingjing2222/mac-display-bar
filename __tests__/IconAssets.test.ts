import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

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
