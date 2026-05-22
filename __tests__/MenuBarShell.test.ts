import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const repoRoot = process.cwd();
const infoPlist = readFileSync(
  join(repoRoot, 'macos/com.jingjing2222.macdisplaybar-macOS/Info.plist'),
  'utf8',
);
const appDelegate = readFileSync(
  join(repoRoot, 'macos/com.jingjing2222.macdisplaybar-macOS/AppDelegate.mm'),
  'utf8',
);

test('macOS bundle is configured as a menu bar only app', () => {
  expect(infoPlist).toMatch(/<key>LSUIElement<\/key>\s*<true\/>/);
  expect(appDelegate).toContain(
    '[NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory]',
  );
});

test('React Native host view is moved into an NSPopover backed by NSStatusItem', () => {
  expect(appDelegate).toContain(
    '[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength]',
  );
  expect(appDelegate).toContain('self.statusPopover = [NSPopover new]');
  expect(appDelegate).toContain(
    'self.statusPopover.contentViewController = rootViewController',
  );
});

test('menu bar shell uses the bundled template status bar icon', () => {
  expect(appDelegate).toContain('[NSImage imageNamed:@"StatusBarIcon"]');
  expect(appDelegate).toContain('[statusImage setTemplate:YES]');
  expect(appDelegate).not.toContain('imageWithSystemSymbolName:@"display"');
});

test('startup window is hidden from normal window and app switcher flows', () => {
  expect(appDelegate).toContain(
    'self.reactHostWindow.contentViewController = nil',
  );
  expect(appDelegate).toContain('[self.reactHostWindow orderOut:nil]');
  expect(appDelegate).toContain('NSWindowCollectionBehaviorIgnoresCycle');
  expect(appDelegate).not.toContain('makeKeyAndOrderFront');
});
