import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const repoRoot = process.cwd();
const fontDir = join(
  repoRoot,
  'macos/com.jingjing2222.macdisplaybar-macOS/Fonts',
);
const infoPlist = readFileSync(
  join(repoRoot, 'macos/com.jingjing2222.macdisplaybar-macOS/Info.plist'),
  'utf8',
);
const projectFile = readFileSync(
  join(
    repoRoot,
    'macos/com.jingjing2222.macdisplaybar.xcodeproj/project.pbxproj',
  ),
  'utf8',
);
const uiSources = [
  'src/components/MenuShell.tsx',
  'src/components/TopUpdateHeader.tsx',
  'src/components/DisplayDropdown.tsx',
  'src/components/DisplayControlPanel.tsx',
  'src/components/ControlSlider.tsx',
  'src/components/ResolutionPicker.tsx',
  'src/components/SegmentedTabs.tsx',
]
  .map((path) => readFileSync(join(repoRoot, path), 'utf8'))
  .join('\n');

test('Inter font files are bundled with the macOS target', () => {
  for (const filename of [
    'Inter-Regular.ttf',
    'Inter-Medium.ttf',
    'Inter-SemiBold.ttf',
    'Inter-Bold.ttf',
    'Inter-LICENSE.txt',
  ]) {
    expect(existsSync(join(fontDir, filename))).toBe(true);
  }

  expect(infoPlist).toMatch(
    /<key>ATSApplicationFontsPath<\/key>\s*<string>Fonts<\/string>/,
  );
  expect(projectFile).toContain('Fonts in Resources');
});

test('React Native text styles use the bundled Inter font family', () => {
  expect(uiSources).toContain("family: 'Inter'");
  expect(uiSources).toContain('fontFamily: font.family');
});
