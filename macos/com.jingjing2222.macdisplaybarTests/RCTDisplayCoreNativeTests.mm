#import <XCTest/XCTest.h>

#import "../com.jingjing2222.macdisplaybar-macOS/DisplayCore/RCTDisplayCore.h"
#import "../com.jingjing2222.macdisplaybar-macOS/NativeDisplayControl/RCTNativeDisplayLocale.h"

@interface MDBTestDisplayCore : RCTDisplayCore

@property (nonatomic, assign) NSUInteger snapshotCount;
@property (nonatomic, strong) NSMutableArray<NSString *> *events;
@property (nonatomic, assign) BOOL nativeBrightnessResult;
@property (nonatomic, copy) NSString *nativeBrightnessError;
@property (nonatomic, assign) BOOL ddcSendResult;
@property (nonatomic, assign) BOOL supportsHdr;
@property (nonatomic, copy) NSString *edidPath;
@property (nonatomic, copy) NSString *bundlePath;
@property (nonatomic, assign) BOOL overridePayloadExists;
@property (nonatomic, assign) BOOL installResult;
@property (nonatomic, assign) BOOL installDidMutate;
@property (nonatomic, assign) BOOL removeResult;
@property (nonatomic, assign) BOOL reinitializeResult;
@property (nonatomic, copy) NSString *virtualCreateError;

@end

@implementation MDBTestDisplayCore

- (instancetype)init
{
  self = [super init];

  if (self) {
    _events = [NSMutableArray new];
    _nativeBrightnessResult = YES;
    _ddcSendResult = YES;
    _supportsHdr = YES;
    _edidPath = @"/tmp/macDisplayBar-test-edid.bin";
    _bundlePath = @"/tmp/macDisplayBar-test-override";
    _overridePayloadExists = YES;
    _installResult = YES;
    _installDidMutate = YES;
    _removeResult = YES;
    _reinitializeResult = YES;
  }

  return self;
}

- (NSDictionary *)stubbedSnapshot
{
  self.snapshotCount += 1;
  return @{ @"snapshotCount" : @(self.snapshotCount) };
}

- (void)clearRebootPendingStatesAfterSystemBoot
{
}

- (void)restoreManagedVirtualDisplays
{
}

- (void)refreshDdcValuesForActiveDisplays
{
  [self.events addObject:@"refreshDdc"];
}

- (BOOL)setNativeBrightnessForDisplayID:(CGDirectDisplayID)displayID
                                  level:(double)level
                           errorMessage:(NSString **)errorMessage
{
  [self.events addObject:[NSString stringWithFormat:@"nativeBrightness:%u:%.2f", displayID, level]];

  if (!self.nativeBrightnessResult && errorMessage != nil) {
    *errorMessage = self.nativeBrightnessError ?: @"Native brightness failed";
  }

  return self.nativeBrightnessResult;
}

- (void)syncNativeBrightnessFromDisplayIDString:(NSString *)displayID level:(double)level
{
  [self.events addObject:[NSString stringWithFormat:@"syncNative:%@:%.2f", displayID, level]];
}

- (void)syncDimmingWindowForDisplayID:(CGDirectDisplayID)displayID level:(double)level
{
  [self.events addObject:[NSString stringWithFormat:@"syncDimming:%u:%.2f", displayID, level]];
}

- (void)syncSoftwareDimmingFromDisplayIDString:(NSString *)displayID level:(double)level
{
  [self.events addObject:[NSString stringWithFormat:@"syncSoftware:%@:%.2f", displayID, level]];
}

- (void)applyDisplayModeForDisplayID:(CGDirectDisplayID)displayID
                               modeID:(NSString *)modeID
                      displayIDString:(NSString *)displayIDString
{
  [self.events addObject:[NSString stringWithFormat:@"mode:%u:%@:%@", displayID, modeID, displayIDString]];
}

- (void)applyDisplayOriginForDisplayID:(CGDirectDisplayID)displayID x:(int32_t)x y:(int32_t)y
{
  [self.events addObject:[NSString stringWithFormat:@"origin:%u:%d:%d", displayID, x, y]];
}

- (void)applyColorProfileForDisplayID:(CGDirectDisplayID)displayID
                            profileID:(NSString *)profileID
                      displayIDString:(NSString *)displayIDString
{
  [self.events addObject:[NSString stringWithFormat:@"profile:%u:%@:%@", displayID, profileID, displayIDString]];
}

- (NSDictionary *)currentPresetDisplayStates
{
  return @{
    @"7" : @{
      @"modeID" : @"mode-1",
      @"colorProfileID" : @"profile-1",
      @"frame" : @{ @"x" : @1, @"y" : @2 },
      @"softwareDimming" : @0.4,
      @"nativeBrightness" : @0.7,
      @"ddc" : @{ @"brightness" : @70 },
    },
  };
}

- (NSDictionary *)currentLayoutState
{
  return @{ @"7" : @{ @"x" : @11, @"y" : @22, @"width" : @100, @"height" : @80 } };
}

- (NSDictionary *)currentLayoutStateForDisplayIDStrings:(NSArray<NSString *> *)displayIDStrings
{
  [self.events addObject:[NSString stringWithFormat:@"layoutFor:%lu", (unsigned long)displayIDStrings.count]];
  return [self currentLayoutState];
}

- (void)restoreLayoutState:(NSDictionary *)layout
{
  [self.events addObject:[NSString stringWithFormat:@"restoreLayout:%lu", (unsigned long)layout.count]];
}

- (NSString *)resolveDisplayIDString:(NSString *)displayID storedState:(NSDictionary *)storedState
{
  return displayID.length > 0 ? displayID : @"7";
}

- (void)applyDdcPresetState:(NSDictionary *)ddc displayIDString:(NSString *)displayIDString displayID:(CGDirectDisplayID)displayID
{
  [self.events addObject:[NSString stringWithFormat:@"ddcPreset:%@:%u", displayIDString, displayID]];
}

- (void)applySyncGroupDictionary:(NSDictionary *)group
{
  [self.events addObject:[NSString stringWithFormat:@"syncGroup:%@", group[@"id"] ?: @""]];
}

- (NSString *)exportEdidFileForDisplayIDString:(NSString *)displayID
{
  [self.events addObject:[NSString stringWithFormat:@"exportEdid:%@", displayID]];
  return self.edidPath;
}

- (NSString *)writeOverrideBundleForDisplayIDString:(NSString *)displayID
{
  [self.events addObject:[NSString stringWithFormat:@"writeBundle:%@", displayID]];
  return self.bundlePath;
}

- (BOOL)overridePayloadExistsForDisplayIDString:(NSString *)displayID
{
  [self.events addObject:[NSString stringWithFormat:@"payloadExists:%@", displayID]];
  return self.overridePayloadExists;
}

- (BOOL)installOverrideBundleAtPath:(NSString *)bundlePath
                     displayIDString:(NSString *)displayIDString
                           didMutate:(BOOL *)didMutate
                        errorMessage:(NSString **)errorMessage
{
  [self.events addObject:[NSString stringWithFormat:@"installBundle:%@:%@", displayIDString, bundlePath]];
  if (didMutate != nil) {
    *didMutate = self.installDidMutate;
  }
  if (!self.installResult && errorMessage != nil) {
    *errorMessage = @"Install failed";
  }
  return self.installResult;
}

- (NSURL *)overrideTargetFileURLForDisplayIDString:(NSString *)displayID
{
  return [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"DisplayProductID-%@", displayID]]];
}

- (BOOL)removeInstalledOverrideForDisplayIDString:(NSString *)displayID errorMessage:(NSString **)errorMessage
{
  [self.events addObject:[NSString stringWithFormat:@"removeOverride:%@", displayID]];
  if (!self.removeResult && errorMessage != nil) {
    *errorMessage = @"Remove failed";
  }
  return self.removeResult;
}

- (BOOL)requestDisplayReinitializeForDisplayID:(CGDirectDisplayID)displayID errorMessage:(NSString **)errorMessage
{
  [self.events addObject:[NSString stringWithFormat:@"reinitialize:%u", displayID]];
  if (!self.reinitializeResult && errorMessage != nil) {
    *errorMessage = @"Reinitialize failed";
  }
  return self.reinitializeResult;
}

- (void)persistOverrideLifecycleStateForDisplayID:(NSString *)displayID
{
  [self.events addObject:[NSString stringWithFormat:@"persistOverride:%@", displayID]];
}

- (void)persistNativePanelResolutionState
{
  [self.events addObject:@"persistPanel"];
}

- (BOOL)displaySupportsHdrForDisplayID:(CGDirectDisplayID)displayID
{
  [self.events addObject:[NSString stringWithFormat:@"supportsHdr:%u", displayID]];
  return self.supportsHdr;
}

- (void)syncXdrUpscaleWindowForDisplayID:(CGDirectDisplayID)displayID enabled:(BOOL)enabled
{
  [self.events addObject:[NSString stringWithFormat:@"syncXdr:%u:%@", displayID, enabled ? @"YES" : @"NO"]];
}

- (BOOL)sendDdcSetVcpForDisplayID:(CGDirectDisplayID)displayID
                       controlCode:(uint8_t)controlCode
                             value:(uint16_t)value
                      errorMessage:(NSString **)errorMessage
{
  [self.events addObject:[NSString stringWithFormat:@"ddcSend:%u:%u:%u", displayID, controlCode, value]];
  if (!self.ddcSendResult && errorMessage != nil) {
    *errorMessage = @"DDC failed";
  }
  return self.ddcSendResult;
}

- (NSDictionary *)createVirtualDisplayRecordWithID:(NSString *)virtualDisplayID
                                   targetDisplayID:(NSString *)targetDisplayID
                                      serialNumber:(NSNumber *)serialNumber
                                             width:(double)width
                                            height:(double)height
                                       refreshRate:(double)refreshRate
                                           isHiDpi:(BOOL)isHiDpi
                                      errorMessage:(NSString **)errorMessage
{
  [self.events addObject:[NSString stringWithFormat:@"createVirtual:%@:%@:%0.f:%0.f", virtualDisplayID, targetDisplayID, width, height]];
  if (self.virtualCreateError.length > 0) {
    if (errorMessage != nil) {
      *errorMessage = self.virtualCreateError;
    }
    return @{};
  }
  return @{
    @"id" : virtualDisplayID,
    @"targetDisplayID" : targetDisplayID ?: @"",
    @"displayID" : @"88",
    @"status" : @"Created",
    @"name" : @"Virtual",
    @"width" : @(MAX(width, 1)),
    @"height" : @(MAX(height, 1)),
    @"refreshRate" : @(refreshRate > 0 ? refreshRate : 60),
    @"isHiDpi" : @(isHiDpi),
  };
}

- (void)persistVirtualDisplayRecords
{
  [self.events addObject:@"persistVirtual"];
}

- (NSDictionary *)recordByApplyingVirtualMirrorForID:(NSString *)virtualDisplayID
                                             record:(NSDictionary *)record
                                       errorMessage:(NSString **)errorMessage
{
  [self.events addObject:[NSString stringWithFormat:@"mirrorVirtual:%@", virtualDisplayID]];
  NSMutableDictionary *updatedRecord = [record mutableCopy];
  updatedRecord[@"mirrorStatus"] = @"Mirrored";
  return updatedRecord;
}

- (BOOL)configureDisplayID:(CGDirectDisplayID)displayID mirrorOfDisplay:(CGDirectDisplayID)sourceDisplayID errorMessage:(NSString **)errorMessage
{
  [self.events addObject:[NSString stringWithFormat:@"configureMirror:%u:%u", displayID, sourceDisplayID]];
  return YES;
}

- (NSString *)visibleDisplayIDForVirtualDisplay:(id)virtualDisplay
{
  return @"88";
}

- (BOOL)displayIDStringIsActive:(NSString *)displayID
{
  return [displayID isEqualToString:@"7"];
}

- (void)capturePipFrameForID:(NSString *)pipWindowID
{
  [self.events addObject:[NSString stringWithFormat:@"capturePip:%@", pipWindowID]];
}

- (void)recordAdvancedOperation:(NSString *)operation displayID:(NSString *)displayID
{
  [self.events addObject:[NSString stringWithFormat:@"advanced:%@:%@", operation ?: @"", displayID ?: @""]];
}

@end

@interface RCTDisplayCoreNativeTests : XCTestCase
@end

@implementation RCTDisplayCoreNativeTests

- (MDBTestDisplayCore *)core
{
  NSString *suiteName = [NSString stringWithFormat:@"macDisplayBarTests.%@", NSUUID.UUID.UUIDString];
  [NSUserDefaults.standardUserDefaults addSuiteNamed:suiteName];
  return [MDBTestDisplayCore new];
}

- (NSMutableDictionary *)dict:(RCTDisplayCore *)core key:(NSString *)key
{
  return [core valueForKey:key];
}

- (NSArray<NSString *> *)snapshotSelectorNames
{
  return @[
    @"getSnapshot",
    @"refreshSnapshot",
    @"setNativeBrightness:level:",
    @"setSoftwareDimming:level:",
    @"setDisplayMode:modeID:",
    @"setDisplayOrigin:x:y:",
    @"savePreset:",
    @"applyPreset:",
    @"deletePreset:",
    @"setColorProfile:profileID:",
    @"resetColorProfile:",
    @"saveProtectedLayout",
    @"restoreProtectedLayout",
    @"clearProtectedLayout",
    @"saveSyncGroup:displayIDs:brightnessSync:scaleSync:layoutProtection:",
    @"applySyncGroup:",
    @"deleteSyncGroup:",
    @"exportEdid:",
    @"addCustomResolution:width:height:refreshRate:isHiDpi:",
    @"removeCustomResolution:requestID:",
    @"queueEdidOverride:",
    @"clearEdidOverride:",
    @"writeOverrideBundle:",
    @"installDisplayOverride:",
    @"removeDisplayOverride:",
    @"reinitializeDisplay:",
    @"setNativePanelResolutionOverride:width:height:",
    @"clearNativePanelResolutionOverride:",
    @"setFlexibleScalingEnabled:enabled:",
    @"setDisplayRotation:rotation:",
    @"enableXdrUpscale:",
    @"disableXdrUpscale:",
    @"softDisconnectDisplay:",
    @"reconnectDisplay:",
    @"createVirtualDisplay:width:height:refreshRate:isHiDpi:",
    @"removeVirtualDisplay:",
    @"mirrorVirtualDisplayToTarget:",
    @"stopVirtualDisplayMirroring:",
    @"openDisplayPip:",
    @"setPipWindowFilter:filter:",
    @"closeDisplayPip:",
    @"saveFavoriteMode:modeID:",
    @"removeFavoriteMode:modeID:",
    @"setDdcControl:controlCode:value:",
    @"setSettings:refreshIntervalSeconds:showAdvancedMetadata:",
  ];
}

- (void)testNativeApiInventoryIsCoveredByDisplayCore
{
  MDBTestDisplayCore *core = [self core];
  NSArray<NSString *> *selectorNames = [self snapshotSelectorNames];

  XCTAssertEqual(selectorNames.count, 45);

  for (NSString *selectorName in selectorNames) {
    SEL selector = NSSelectorFromString(selectorName);
    XCTAssertTrue([core respondsToSelector:selector], @"Missing native selector %@", selectorName);
  }
}

- (void)testSystemLocaleResolutionUsesNativeFallbackRules
{
  XCTAssertEqualObjects(
      RCTNativeDisplayResolvedSystemLocaleFromValues(@[ @"ko-KR" ], @"en-US"),
      @"ko-KR");
  XCTAssertEqualObjects(
      RCTNativeDisplayResolvedSystemLocaleFromValues(@[ @"zh-Hant-TW" ], @"en-US"),
      @"zh-Hant-TW");
  XCTAssertEqualObjects(
      RCTNativeDisplayResolvedSystemLocaleFromValues(@[], @"en-US"),
      @"en-US");
  XCTAssertEqualObjects(
      RCTNativeDisplayResolvedSystemLocaleFromValues(@[ @"" ], @"ja-JP"),
      @"ja-JP");
  XCTAssertEqualObjects(
      RCTNativeDisplayResolvedSystemLocaleFromValues(nil, @""),
      @"en-US");
  XCTAssertTrue(RCTNativeDisplayResolvedSystemLocale().length > 0);
}

- (void)testSnapshotAndRefreshUseNativeSnapshotPath
{
  MDBTestDisplayCore *core = [self core];

  XCTAssertEqualObjects([core getSnapshot][@"snapshotCount"], @1);
  XCTAssertEqualObjects([core refreshSnapshot][@"snapshotCount"], @2);
  XCTAssertTrue([core.events containsObject:@"refreshDdc"]);
}

- (void)testBrightnessDimmingModeOriginAndColorApisUseNativeHelpersAndClampInputs
{
  MDBTestDisplayCore *core = [self core];

  [core setNativeBrightness:@"7" level:2.5];
  [core setSoftwareDimming:@"7" level:2.5];
  [core setDisplayMode:@"7" modeID:@"mode-1"];
  [core setDisplayOrigin:@"7" x:11.9 y:-4.2];
  [core setColorProfile:@"7" profileID:@"profile-1"];
  [core resetColorProfile:@"7"];

  XCTAssertTrue([core.events containsObject:@"nativeBrightness:7:1.00"]);
  XCTAssertTrue([core.events containsObject:@"syncNative:7:1.00"]);
  XCTAssertTrue([core.events containsObject:@"syncDimming:7:0.80"]);
  XCTAssertTrue([core.events containsObject:@"syncSoftware:7:0.80"]);
  XCTAssertTrue([core.events containsObject:@"mode:7:mode-1:7"]);
  XCTAssertTrue([core.events containsObject:@"origin:7:11:-4"]);
  XCTAssertTrue([core.events containsObject:@"profile:7:profile-1:7"]);
  XCTAssertTrue([core.events containsObject:@"profile:7:__factory__:7"]);

  core.nativeBrightnessResult = NO;
  core.nativeBrightnessError = @"No brightness";
  [core setNativeBrightness:@"7" level:0.2];
  XCTAssertEqualObjects([self dict:core key:@"brightnessErrors"][@"7"], @"No brightness");
}

- (void)testPresetLayoutAndSyncGroupApisPersistAndHandleMissingRecords
{
  MDBTestDisplayCore *core = [self core];

  [core savePreset:@" Desk "];
  NSDictionary *presets = [self dict:core key:@"displayPresets"];
  XCTAssertNotNil(presets[@"Desk"]);

  [core applyPreset:@"Desk"];
  XCTAssertTrue([core.events containsObject:@"mode:7:mode-1:7"]);
  XCTAssertTrue([core.events containsObject:@"profile:7:profile-1:7"]);
  XCTAssertTrue([core.events containsObject:@"ddcPreset:7:7"]);

  [core applyPreset:@"Missing"];
  [core deletePreset:@"Desk"];
  XCTAssertNil([self dict:core key:@"displayPresets"][@"Desk"]);

  [core saveProtectedLayout];
  XCTAssertEqualObjects([core valueForKey:@"protectedLayout"], [core currentLayoutState]);
  [core restoreProtectedLayout];
  XCTAssertTrue([core.events containsObject:@"restoreLayout:1"]);
  [core clearProtectedLayout];
  XCTAssertEqualObjects([core valueForKey:@"protectedLayout"], @{});

  [core saveSyncGroup:@" Group " displayIDs:@[ @"7" ] brightnessSync:YES scaleSync:YES layoutProtection:YES];
  NSDictionary *groups = [self dict:core key:@"syncGroups"];
  NSString *groupID = groups.allKeys.firstObject;
  XCTAssertNotNil(groupID);
  [core applySyncGroup:groupID];
  NSString *syncEvent = [NSString stringWithFormat:@"syncGroup:%@", groupID];
  XCTAssertTrue([core.events containsObject:syncEvent]);
  [core applySyncGroup:@"missing"];
  [core deleteSyncGroup:groupID];
  XCTAssertNil([self dict:core key:@"syncGroups"][groupID]);
}

- (void)testEdidCustomResolutionAndOverrideApisCoverSuccessAndFailurePaths
{
  MDBTestDisplayCore *core = [self core];

  [core exportEdid:@"7"];
  XCTAssertTrue([core.events containsObject:@"exportEdid:7"]);

  [core addCustomResolution:@"7" width:-1 height:0 refreshRate:-10 isHiDpi:YES];
  NSDictionary *customRequests = [self dict:core key:@"customResolutionRequests"];
  NSArray *requests = [customRequests.allValues.firstObject copy];
  XCTAssertEqualObjects(requests.firstObject[@"width"], @1);
  XCTAssertEqualObjects(requests.firstObject[@"height"], @1);
  XCTAssertEqualObjects(requests.firstObject[@"refreshRate"], @0);
  NSString *requestID = requests.firstObject[@"id"];
  XCTAssertNotNil(requestID);
  [core removeCustomResolution:@"7" requestID:requestID];
  NSArray *remainingRequests = [self dict:core key:@"customResolutionRequests"].allValues.firstObject;
  XCTAssertEqual(remainingRequests.count, 0);

  [core queueEdidOverride:@"7"];
  XCTAssertEqualObjects([self dict:core key:@"edidOverrideStatus"][@"7"], @"Override prepared");
  [core clearEdidOverride:@"7"];
  XCTAssertNotNil([self dict:core key:@"edidOverrideStatus"][@"7"]);
  [core writeOverrideBundle:@"7"];
  XCTAssertEqualObjects([self dict:core key:@"overrideBundleStatus"][@"7"], @"Bundle written");
  [core installDisplayOverride:@"7"];
  XCTAssertEqualObjects([self dict:core key:@"overrideBundleStatus"][@"7"], @"Installed");

  core.installResult = NO;
  [core installDisplayOverride:@"7"];
  XCTAssertEqualObjects([self dict:core key:@"overrideBundleStatus"][@"7"], @"Install failed");

  core.overridePayloadExists = NO;
  [core installDisplayOverride:@"7"];
  XCTAssertEqualObjects([self dict:core key:@"overrideBundleStatus"][@"7"], @"No payload");

  [core removeDisplayOverride:@"7"];
  XCTAssertEqualObjects([self dict:core key:@"overrideBundleStatus"][@"7"], @"No override");

  [core reinitializeDisplay:@"7"];
  XCTAssertTrue([core.events containsObject:@"reinitialize:7"]);
}

- (void)testPanelScalingRotationXdrDdcConnectionFavoritesAndSettingsApis
{
  MDBTestDisplayCore *core = [self core];

  [core setNativePanelResolutionOverride:@"7" width:-100 height:0];
  NSDictionary *panel = [self dict:core key:@"nativePanelResolutionOverrides"].allValues.firstObject;
  XCTAssertEqualObjects(panel[@"width"], @1);
  XCTAssertEqualObjects(panel[@"height"], @1);

  [core clearNativePanelResolutionOverride:@"7"];
  XCTAssertEqual([self dict:core key:@"nativePanelResolutionOverrides"].count, 0);

  [core setFlexibleScalingEnabled:@"7" enabled:YES];
  XCTAssertEqualObjects([self dict:core key:@"flexibleScalingEnabled"].allValues.firstObject, @YES);

  [core setDisplayRotation:@"7" rotation:95];
  XCTAssertEqualObjects([self dict:core key:@"rotationRequests"][@"7"], @90);

  [core enableXdrUpscale:@"7"];
  XCTAssertEqualObjects([self dict:core key:@"xdrUpscaleStates"][@"7"], @"enabled");
  core.supportsHdr = NO;
  [core enableXdrUpscale:@"7"];
  XCTAssertEqualObjects([self dict:core key:@"xdrUpscaleStates"][@"7"], @"unsupported");
  [core disableXdrUpscale:@"7"];
  XCTAssertEqualObjects([self dict:core key:@"xdrUpscaleStates"][@"7"], @"disabled");

  [core softDisconnectDisplay:@"7"];
  XCTAssertEqualObjects([self dict:core key:@"softConnectionStates"][@"7"], @"disconnect-requested");
  [core reconnectDisplay:@"7"];
  XCTAssertEqualObjects([self dict:core key:@"softConnectionStates"][@"7"], @"connected");

  [core setDdcControl:@"7" controlCode:999 value:99999];
  XCTAssertTrue([core.events containsObject:@"ddcSend:7:255:65535"]);

  [core saveFavoriteMode:@"7" modeID:@"mode-1"];
  [core saveFavoriteMode:@"7" modeID:@"mode-1"];
  XCTAssertEqual([[self dict:core key:@"favoriteModes"][@"7"] count], 1);
  [core removeFavoriteMode:@"7" modeID:@"mode-1"];
  XCTAssertEqual([[self dict:core key:@"favoriteModes"][@"7"] count], 0);

  [core setSettings:YES refreshIntervalSeconds:1 showAdvancedMetadata:NO];
  XCTAssertEqualObjects([core valueForKeyPath:@"settings.refreshIntervalSeconds"], @5);
  XCTAssertEqualObjects([core valueForKeyPath:@"settings.autoRefresh"], @YES);
  XCTAssertEqualObjects([core valueForKeyPath:@"settings.showAdvancedMetadata"], @NO);
}

- (void)testVirtualDisplayAndPipApisCoverMockedSuccessAndEdgePaths
{
  MDBTestDisplayCore *core = [self core];

  [core createVirtualDisplay:@"7" width:3440 height:1440 refreshRate:165 isHiDpi:YES];
  NSDictionary *virtualRecords = [self dict:core key:@"virtualDisplayRecords"];
  NSString *virtualID = virtualRecords.allKeys.firstObject;
  XCTAssertNotNil(virtualID);
  XCTAssertTrue([core.events containsObject:@"persistVirtual"]);

  [core mirrorVirtualDisplayToTarget:virtualID];
  NSString *mirrorEvent = [NSString stringWithFormat:@"mirrorVirtual:%@", virtualID];
  XCTAssertTrue([core.events containsObject:mirrorEvent]);
  [core stopVirtualDisplayMirroring:virtualID];
  [core removeVirtualDisplay:virtualID];
  XCTAssertNil([self dict:core key:@"virtualDisplayRecords"][virtualID]);

  [core mirrorVirtualDisplayToTarget:@"missing"];
  [core stopVirtualDisplayMirroring:@"missing"];
  [core removeVirtualDisplay:@""];

  [core openDisplayPip:@"missing"];
  [core setPipWindowFilter:@"missing" filter:@"mono"];
  [core closeDisplayPip:@"missing"];
}

@end
