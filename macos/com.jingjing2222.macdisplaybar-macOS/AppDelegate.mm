#import "AppDelegate.h"

#import <HotUpdater/HotUpdater.h>
#import <React/RCTBundleURLProvider.h>
#import <ReactAppDependencyProvider/RCTAppDependencyProvider.h>

@interface AppDelegate () <NSPopoverDelegate>

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSPopover *statusPopover;
@property (nonatomic, strong) NSWindow *reactHostWindow;

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
  self.statusPopover.contentSize = NSMakeSize(380, 560);
  self.statusPopover.contentViewController = rootViewController;

  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  NSStatusBarButton *button = self.statusItem.button;
  button.toolTip = @"Mac Display Bar";
  button.target = self;
  button.action = @selector(toggleStatusPopover:);

  NSImage *statusImage = [NSImage imageNamed:@"StatusBarIcon"];
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

  if (self.statusPopover.shown) {
    [self.statusPopover performClose:sender];
    return;
  }

  [self.statusPopover showRelativeToRect:button.bounds
                                  ofView:button
                           preferredEdge:NSRectEdgeMinY];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
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
