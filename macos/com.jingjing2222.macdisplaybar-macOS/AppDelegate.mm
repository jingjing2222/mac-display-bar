#import "AppDelegate.h"

#import <HotUpdater/HotUpdater.h>
#import <React/RCTBundleURLProvider.h>
#import <ReactAppDependencyProvider/RCTAppDependencyProvider.h>

@interface AppDelegate () <NSPopoverDelegate>

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSPopover *statusPopover;
@property (nonatomic, strong) NSWindow *reactHostWindow;
@property (nonatomic, strong) id outsideClickMonitor;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  self.moduleName = @"com.jingjing2222.macdisplaybar";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};
  self.dependencyProvider = [RCTAppDependencyProvider new];

  [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
  [super applicationDidFinishLaunching:notification];
  [self configureMenuBarShell];
}

- (void)configureMenuBarShell
{
  self.reactHostWindow = self.window;
  NSViewController *rootViewController = self.reactHostWindow.contentViewController;

  self.statusPopover = [NSPopover new];
  self.statusPopover.behavior = NSPopoverBehaviorTransient;
  self.statusPopover.delegate = self;
  self.statusPopover.animates = YES;
  self.statusPopover.contentSize = NSMakeSize(520, 720);
  self.statusPopover.contentViewController = rootViewController;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(closeStatusPopover:)
                                               name:NSApplicationDidResignActiveNotification
                                             object:NSApp];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleScreenParametersChanged:)
                                               name:NSApplicationDidChangeScreenParametersNotification
                                             object:NSApp];

  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:28.0];
  NSStatusBarButton *button = self.statusItem.button;
  button.toolTip = @"macDisplayBar";
  button.target = self;
  button.action = @selector(toggleStatusPopover:);
  [button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp];

  NSImage *statusImage = [NSImage imageNamed:@"StatusBarIcon"];
  statusImage.size = NSMakeSize(22.0, 22.0);
  [statusImage setTemplate:YES];
  button.image = statusImage;
  button.imagePosition = NSImageOnly;

  self.reactHostWindow.contentViewController = nil;
  self.reactHostWindow.releasedWhenClosed = NO;
  self.reactHostWindow.collectionBehavior = NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorIgnoresCycle;
  [self.reactHostWindow orderOut:nil];
}

- (void)toggleStatusPopover:(id)sender
{
  NSStatusBarButton *button = self.statusItem.button;
  NSEvent *event = NSApp.currentEvent;

  if (event.type == NSEventTypeRightMouseUp) {
    [self closeStatusPopover:sender];
    [NSMenu popUpContextMenu:[self statusContextMenu] withEvent:event forView:button];
    return;
  }

  if (self.statusPopover.shown) {
    [self closeStatusPopover:sender];
    return;
  }

  [self showStatusPopoverAnchoredToStatusItem];
}

- (void)closeStatusPopover:(id)sender
{
  if (self.statusPopover.shown) {
    [self.statusPopover performClose:sender];
  }

  [self uninstallOutsideClickMonitor];
}

- (void)showStatusPopoverAnchoredToStatusItem
{
  NSStatusBarButton *button = self.statusItem.button;

  if (button == nil || button.window == nil) {
    return;
  }

  [self.statusPopover showRelativeToRect:button.bounds
                                  ofView:button
                           preferredEdge:NSRectEdgeMinY];
  [self installOutsideClickMonitor];
}

- (void)handleScreenParametersChanged:(NSNotification *)notification
{
  [self repositionStatusPopoverAfterDelay:0.10];
  [self repositionStatusPopoverAfterDelay:0.35];
}

- (void)repositionStatusPopoverAfterDelay:(NSTimeInterval)delay
{
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self repositionStatusPopoverIfShown];
  });
}

- (void)repositionStatusPopoverIfShown
{
  if (!self.statusPopover.shown) {
    return;
  }

  BOOL animates = self.statusPopover.animates;
  self.statusPopover.animates = NO;
  [self.statusPopover close];
  [self showStatusPopoverAnchoredToStatusItem];
  self.statusPopover.animates = animates;
}

- (void)installOutsideClickMonitor
{
  if (self.outsideClickMonitor != nil) {
    return;
  }

  __weak AppDelegate *weakSelf = self;
  self.outsideClickMonitor =
      [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown
                                             handler:^(NSEvent *event) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                 [weakSelf closeStatusPopover:event];
                                               });
                                             }];
}

- (void)uninstallOutsideClickMonitor
{
  if (self.outsideClickMonitor == nil) {
    return;
  }

  [NSEvent removeMonitor:self.outsideClickMonitor];
  self.outsideClickMonitor = nil;
}

- (void)popoverDidClose:(NSNotification *)notification
{
  [self uninstallOutsideClickMonitor];
}

- (NSMenu *)statusContextMenu
{
  NSMenu *menu = [NSMenu new];
  NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit macDisplayBar"
                                                   action:@selector(quitApplication:)
                                            keyEquivalent:@"q"];
  quitItem.target = self;
  [menu addItem:quitItem];

  return menu;
}

- (void)quitApplication:(id)sender
{
  [NSApp terminate:sender];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self uninstallOutsideClickMonitor];

  if (self.statusItem != nil) {
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
  }
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self bundleURL];
}

- (NSURL *)bundleURL
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [HotUpdater bundleURLWithBundle:[NSBundle mainBundle]];
#endif
}

/// This method controls whether the `concurrentRoot`feature of React18 is turned on or off.
///
/// @see: https://reactjs.org/blog/2022/03/29/react-v18.html
/// @note: This requires to be rendering on Fabric (i.e. on the New Architecture).
/// @return: `true` if the `concurrentRoot` feature is enabled. Otherwise, it returns `false`.
- (BOOL)concurrentRootEnabled
{
#ifdef RN_FABRIC_ENABLED
  return true;
#else
  return false;
#endif
}

@end
