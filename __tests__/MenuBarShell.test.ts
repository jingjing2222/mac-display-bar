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
const xcodeProject = readFileSync(
  join(
    repoRoot,
    'macos/com.jingjing2222.macdisplaybar.xcodeproj/project.pbxproj',
  ),
  'utf8',
);
const xcodeScheme = readFileSync(
  join(
    repoRoot,
    'macos/com.jingjing2222.macdisplaybar.xcodeproj/xcshareddata/xcschemes/com.jingjing2222.macdisplaybar-macOS.xcscheme',
  ),
  'utf8',
);
const mainStoryboard = readFileSync(
  join(
    repoRoot,
    'macos/com.jingjing2222.macdisplaybar-macOS/Base.lproj/Main.storyboard',
  ),
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
    '[[NSStatusBar systemStatusBar] statusItemWithLength:28.0]',
  );
  expect(appDelegate).toContain('self.statusPopover = [NSPopover new]');
  expect(appDelegate).toContain(
    'self.statusPopover.contentSize = NSMakeSize(520, 720)',
  );
  expect(appDelegate).toContain(
    'self.statusPopover.contentViewController = rootViewController',
  );
});

test('menu bar shell uses the bundled template status bar icon', () => {
  expect(appDelegate).toContain('[NSImage imageNamed:@"StatusBarIcon"]');
  expect(appDelegate).toContain('statusItemWithLength:28.0');
  expect(appDelegate).toContain('statusImage.size = NSMakeSize(22.0, 22.0)');
  expect(appDelegate).toContain('[statusImage setTemplate:YES]');
  expect(appDelegate).toContain('button.toolTip = @"macDisplayBar"');
  expect(appDelegate).not.toContain('imageWithSystemSymbolName:@"display"');
});

test('menu bar app installs a minimal main menu to avoid AppKit submenu inconsistencies', () => {
  expect(appDelegate).toContain('- (void)configureMainMenu');
  expect(appDelegate).toContain(
    'NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Main Menu"]',
  );
  expect(appDelegate).toContain('NSApp.mainMenu = mainMenu');
});

test('status item right click exposes a quit menu', () => {
  expect(appDelegate).toContain(
    '[button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp]',
  );
  expect(appDelegate).toContain('NSEventTypeRightMouseUp');
  expect(appDelegate).toContain('popUpContextMenu');
  expect(appDelegate).toContain('initWithTitle:@"Quit macDisplayBar"');
  expect(appDelegate).toContain('[NSApp terminate:sender]');
});

test('menu bar popover closes when focus moves outside the app', () => {
  expect(appDelegate).toContain('NSApplicationDidResignActiveNotification');
  expect(appDelegate).toContain('closeStatusPopover:');
  expect(appDelegate).toContain(
    'NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown',
  );
  expect(appDelegate).toContain('addGlobalMonitorForEventsMatchingMask');
  expect(appDelegate).toContain('removeMonitor:self.outsideClickMonitor');
  expect(appDelegate).toContain('popoverDidClose:');
});

test('menu bar popover stays open while an admin install prompt is active', () => {
  expect(appDelegate).toContain(
    'RCTDisplayPrivilegedInstallWillBeginNotification',
  );
  expect(appDelegate).toContain('privilegedPromptDepth');
  expect(appDelegate).toContain('NSPopoverBehaviorApplicationDefined');
  expect(appDelegate).toContain(
    'shouldKeepStatusPopoverOpenForPrivilegedPrompt',
  );
  expect(appDelegate).toContain('NSPopoverBehaviorTransient');
});

test('startup window is hidden from normal window and app switcher flows', () => {
  expect(appDelegate).toContain(
    'self.reactHostWindow.contentViewController = nil',
  );
  expect(appDelegate).toContain('[self.reactHostWindow orderOut:nil]');
  expect(appDelegate).toContain('NSWindowCollectionBehaviorIgnoresCycle');
  expect(appDelegate).not.toContain('makeKeyAndOrderFront');
});

test('macOS app exposes the product name used by Spotlight and system menus', () => {
  expect(infoPlist).toMatch(
    /<key>CFBundleDisplayName<\/key>\s*<string>macDisplayBar<\/string>/,
  );
  expect(infoPlist).toMatch(
    /<key>CFBundleName<\/key>\s*<string>macDisplayBar<\/string>/,
  );
  expect(xcodeProject).toContain('PRODUCT_NAME = macDisplayBar;');
  expect(xcodeProject).toContain('productName = macDisplayBar;');
  expect(xcodeProject).toContain('path = macDisplayBar.app;');
  expect(xcodeScheme).toContain('BuildableName = "macDisplayBar.app"');
  expect(mainStoryboard).toContain('title="macDisplayBar"');
  expect(mainStoryboard).not.toContain(
    'title="com.jingjing2222.macdisplaybar"',
  );
});
