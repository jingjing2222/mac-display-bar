#import "RCTDisplayCore.h"

#import <AppKit/AppKit.h>
#import <ColorSync/ColorSync.h>
#import <CoreGraphics/CoreGraphics.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#import <IOKit/IOKitLib.h>
#import <dispatch/dispatch.h>

extern "C" {
#import <IOKit/i2c/IOI2CInterface.h>
}

#include <vector>
#include <float.h>
#include <math.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>

static NSString *const RCTDisplayDimmingDefaultsKey = @"displayDimmingLevels";
static NSString *const RCTDisplayDdcDefaultsKey = @"displayDdcValues";
static NSString *const RCTDisplayPresetsDefaultsKey = @"displayPresets";
static NSString *const RCTDisplayProtectedLayoutDefaultsKey = @"displayProtectedLayout";
static NSString *const RCTDisplaySyncGroupsDefaultsKey = @"displaySyncGroups";
static NSString *const RCTDisplayCustomResolutionsDefaultsKey = @"displayCustomResolutionRequests";
static NSString *const RCTDisplayEdidExportPathsDefaultsKey = @"displayEdidExportPaths";
static NSString *const RCTDisplaySoftConnectionDefaultsKey = @"displaySoftConnectionStates";
static NSString *const RCTDisplayAdvancedOperationDefaultsKey = @"displayAdvancedOperations";
static NSString *const RCTDisplayAdvancedOperationDatesDefaultsKey = @"displayAdvancedOperationDates";
static NSString *const RCTDisplayFavoriteModesDefaultsKey = @"displayFavoriteModes";
static NSString *const RCTDisplayEdidOverridePathsDefaultsKey = @"displayEdidOverridePaths";
static NSString *const RCTDisplayEdidOverrideStatusDefaultsKey = @"displayEdidOverrideStatus";
static NSString *const RCTDisplayXdrUpscaleDefaultsKey = @"displayXdrUpscaleStates";
static NSString *const RCTDisplayRotationRequestsDefaultsKey = @"displayRotationRequests";
static NSString *const RCTDisplayRotationStatusDefaultsKey = @"displayRotationStatus";
static NSString *const RCTDisplayOverrideBundlePathsDefaultsKey = @"displayOverrideBundlePaths";
static NSString *const RCTDisplayOverrideBundleStatusDefaultsKey = @"displayOverrideBundleStatus";
static NSString *const RCTDisplaySettingsDefaultsKey = @"displaySettings";
static const uint8_t RCTDdcDestinationAddress = 0x6E;
static const uint8_t RCTDdcReplyAddress = 0x6F;
static const uint8_t RCTDdcHostAddress = 0x51;
static const uint8_t RCTDdcGetVcpFeatureCommand = 0x01;
static const uint8_t RCTDdcSetVcpControlCommand = 0x03;
static NSString *const RCTFactoryColorProfileID = @"__factory__";

typedef struct {
  CFUUIDRef displayUUID;
  NSMutableArray<NSDictionary *> *__unsafe_unretained profiles;
} RCTColorProfileContext;

@class RCTDisplayCore;

@interface RCTDisplayCore (Reconfiguration)

- (void)handleDisplayReconfiguration:(CGDirectDisplayID)displayID flags:(CGDisplayChangeSummaryFlags)flags;

@end

static bool RCTCollectColorProfile(CFDictionaryRef profileInfo, void *userInfo)
{
  RCTColorProfileContext *context = (RCTColorProfileContext *)userInfo;
  NSDictionary *profile = (__bridge NSDictionary *)profileInfo;
  id deviceID = profile[(__bridge NSString *)kColorSyncDeviceID];
  NSString *deviceClass = profile[(__bridge NSString *)kColorSyncDeviceClass];

  if (![deviceClass isEqualToString:(__bridge NSString *)kColorSyncDisplayDeviceClass]) {
    return true;
  }

  if (deviceID == nil || !CFEqual((__bridge CFTypeRef)deviceID, context->displayUUID)) {
    return true;
  }

  id profileIDValue = profile[(__bridge NSString *)kColorSyncDeviceProfileID];
  NSURL *profileURL = profile[(__bridge NSString *)kColorSyncDeviceProfileURL];
  NSString *modeDescription = profile[(__bridge NSString *)kColorSyncDeviceModeDescription];
  NSNumber *isCurrent = profile[(__bridge NSString *)kColorSyncDeviceProfileIsCurrent];
  NSNumber *isFactory = profile[(__bridge NSString *)kColorSyncDeviceProfileIsFactory];
  NSString *profileID = [profileIDValue respondsToSelector:@selector(stringValue)]
      ? [profileIDValue stringValue]
      : [profileIDValue description];

  if (profileID.length == 0) {
    return true;
  }

  [context->profiles addObject:@{
    @"id" : profileID,
    @"name" : modeDescription.length > 0 ? modeDescription : profileID,
    @"path" : profileURL.path ?: @"",
    @"isCurrent" : @(isCurrent.boolValue),
    @"isFactory" : @(isFactory.boolValue),
  }];

  return true;
}

static void RCTDisplayReconfigurationCallback(CGDirectDisplayID displayID,
                                              CGDisplayChangeSummaryFlags flags,
                                              void *userInfo)
{
  RCTDisplayCore *displayCore = (__bridge RCTDisplayCore *)userInfo;
  [displayCore handleDisplayReconfiguration:displayID flags:flags];
}

@interface RCTDisplayCore ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *dimmingLevels;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSWindow *> *dimmingWindows;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSWindow *> *xdrUpscaleWindows;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *ddcValues;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *ddcErrors;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *ddcReadStatus;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *brightnessErrors;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *modeStatus;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *modeErrors;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *colorProfileStatus;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *colorProfileErrors;
@property (nonatomic, assign) NSUInteger displayTopologyRevision;
@property (nonatomic, copy) NSString *displayTopologyStatus;
@property (nonatomic, copy) NSString *displayTopologyChangedAt;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *displayPresets;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *syncGroups;
@property (nonatomic, strong) NSDictionary *protectedLayout;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<NSDictionary *> *> *customResolutionRequests;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *edidExportPaths;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *softConnectionStates;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *advancedOperations;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *advancedOperationDates;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<NSString *> *> *favoriteModes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *edidOverridePaths;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *edidOverrideStatus;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *xdrUpscaleStates;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *rotationRequests;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *rotationStatus;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *overrideBundlePaths;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *overrideBundleStatus;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *settings;

@end

@implementation RCTDisplayCore

- (instancetype)init
{
  self = [super init];

  if (self) {
    NSDictionary *storedLevels = [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayDimmingDefaultsKey];
    NSDictionary *storedDdcValues = [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayDdcDefaultsKey];
    NSDictionary *storedPresets = [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayPresetsDefaultsKey];
    NSDictionary *storedSyncGroups = [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplaySyncGroupsDefaultsKey];
    NSDictionary *storedProtectedLayout =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayProtectedLayoutDefaultsKey];
    NSDictionary *storedCustomResolutions =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayCustomResolutionsDefaultsKey];
    NSDictionary *storedEdidExportPaths =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayEdidExportPathsDefaultsKey];
    NSDictionary *storedSoftConnectionStates =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplaySoftConnectionDefaultsKey];
    NSDictionary *storedAdvancedOperations =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayAdvancedOperationDefaultsKey];
    NSDictionary *storedAdvancedOperationDates =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayAdvancedOperationDatesDefaultsKey];
    NSDictionary *storedFavoriteModes =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayFavoriteModesDefaultsKey];
    NSDictionary *storedEdidOverridePaths =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayEdidOverridePathsDefaultsKey];
    NSDictionary *storedEdidOverrideStatus =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayEdidOverrideStatusDefaultsKey];
    NSDictionary *storedXdrUpscaleStates =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayXdrUpscaleDefaultsKey];
    NSDictionary *storedRotationRequests =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayRotationRequestsDefaultsKey];
    NSDictionary *storedRotationStatus =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayRotationStatusDefaultsKey];
    NSDictionary *storedOverrideBundlePaths =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayOverrideBundlePathsDefaultsKey];
    NSDictionary *storedOverrideBundleStatus =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayOverrideBundleStatusDefaultsKey];
    NSDictionary *storedSettings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplaySettingsDefaultsKey];
    self.dimmingLevels = storedLevels != nil ? [storedLevels mutableCopy] : [NSMutableDictionary new];
    self.dimmingWindows = [NSMutableDictionary new];
    self.xdrUpscaleWindows = [NSMutableDictionary new];
    self.ddcValues = storedDdcValues != nil ? [storedDdcValues mutableCopy] : [NSMutableDictionary new];
    self.ddcErrors = [NSMutableDictionary new];
    self.ddcReadStatus = [NSMutableDictionary new];
    self.brightnessErrors = [NSMutableDictionary new];
    self.modeStatus = [NSMutableDictionary new];
    self.modeErrors = [NSMutableDictionary new];
    self.colorProfileStatus = [NSMutableDictionary new];
    self.colorProfileErrors = [NSMutableDictionary new];
    self.displayTopologyRevision = 0;
    self.displayTopologyStatus = @"Stable";
    self.displayTopologyChangedAt = @"";
    self.displayPresets = storedPresets != nil ? [storedPresets mutableCopy] : [NSMutableDictionary new];
    self.syncGroups = storedSyncGroups != nil ? [storedSyncGroups mutableCopy] : [NSMutableDictionary new];
    self.protectedLayout = storedProtectedLayout ?: @{};
    self.customResolutionRequests =
        storedCustomResolutions != nil ? [storedCustomResolutions mutableCopy] : [NSMutableDictionary new];
    self.edidExportPaths = storedEdidExportPaths != nil ? [storedEdidExportPaths mutableCopy] : [NSMutableDictionary new];
    self.softConnectionStates =
        storedSoftConnectionStates != nil ? [storedSoftConnectionStates mutableCopy] : [NSMutableDictionary new];
    self.advancedOperations =
        storedAdvancedOperations != nil ? [storedAdvancedOperations mutableCopy] : [NSMutableDictionary new];
    self.advancedOperationDates =
        storedAdvancedOperationDates != nil ? [storedAdvancedOperationDates mutableCopy] : [NSMutableDictionary new];
    self.favoriteModes = storedFavoriteModes != nil ? [storedFavoriteModes mutableCopy] : [NSMutableDictionary new];
    self.edidOverridePaths =
        storedEdidOverridePaths != nil ? [storedEdidOverridePaths mutableCopy] : [NSMutableDictionary new];
    self.edidOverrideStatus =
        storedEdidOverrideStatus != nil ? [storedEdidOverrideStatus mutableCopy] : [NSMutableDictionary new];
    self.xdrUpscaleStates =
        storedXdrUpscaleStates != nil ? [storedXdrUpscaleStates mutableCopy] : [NSMutableDictionary new];
    self.rotationRequests =
        storedRotationRequests != nil ? [storedRotationRequests mutableCopy] : [NSMutableDictionary new];
    self.rotationStatus =
        storedRotationStatus != nil ? [storedRotationStatus mutableCopy] : [NSMutableDictionary new];
    self.overrideBundlePaths =
        storedOverrideBundlePaths != nil ? [storedOverrideBundlePaths mutableCopy] : [NSMutableDictionary new];
    self.overrideBundleStatus =
        storedOverrideBundleStatus != nil ? [storedOverrideBundleStatus mutableCopy] : [NSMutableDictionary new];
    self.settings = [[self normalizedSettingsFromDictionary:storedSettings] mutableCopy];
    CGDisplayRegisterReconfigurationCallback(RCTDisplayReconfigurationCallback, (__bridge void *)self);
  }

  return self;
}

- (void)dealloc
{
  CGDisplayRemoveReconfigurationCallback(RCTDisplayReconfigurationCallback, (__bridge void *)self);
}

- (NSDictionary *)getSnapshot
{
  return [self stubbedSnapshot];
}

- (NSDictionary *)refreshSnapshot
{
  [self refreshDdcValuesForActiveDisplays];

  return [self stubbedSnapshot];
}

- (NSDictionary *)setNativeBrightness:(NSString *)displayID level:(double)level
{
  double clampedLevel = MIN(MAX(level, 0), 1);
  NSString *errorMessage = nil;
  BOOL didSet = [self setNativeBrightnessForDisplayID:(CGDirectDisplayID)displayID.integerValue
                                                level:clampedLevel
                                         errorMessage:&errorMessage];

  if (didSet) {
    [self.brightnessErrors removeObjectForKey:displayID];
    [self syncNativeBrightnessFromDisplayIDString:displayID level:clampedLevel];
  } else {
    self.brightnessErrors[displayID] = errorMessage ?: @"Native brightness unavailable";
  }

  return [self stubbedSnapshot];
}

- (NSDictionary *)setSoftwareDimming:(NSString *)displayID level:(double)level
{
  double clampedLevel = MIN(MAX(level, 0), 0.8);
  self.dimmingLevels[displayID] = @(clampedLevel);
  [[NSUserDefaults standardUserDefaults] setObject:self.dimmingLevels forKey:RCTDisplayDimmingDefaultsKey];
  [self syncDimmingWindowForDisplayID:(CGDirectDisplayID)displayID.integerValue level:clampedLevel];
  [self syncSoftwareDimmingFromDisplayIDString:displayID level:clampedLevel];

  return [self stubbedSnapshot];
}

- (NSDictionary *)setDisplayMode:(NSString *)displayID modeID:(NSString *)modeID
{
  [self applyDisplayModeForDisplayID:(CGDirectDisplayID)displayID.integerValue
                               modeID:modeID
                      displayIDString:displayID];

  return [self stubbedSnapshot];
}

- (NSDictionary *)setDisplayOrigin:(NSString *)displayID x:(double)x y:(double)y
{
  [self applyDisplayOriginForDisplayID:(CGDirectDisplayID)displayID.integerValue x:(int32_t)x y:(int32_t)y];

  return [self stubbedSnapshot];
}

- (NSDictionary *)savePreset:(NSString *)name
{
  NSString *presetName = [self normalizedPresetName:name];
  NSISO8601DateFormatter *formatter = [NSISO8601DateFormatter new];
  NSDictionary *preset = @{
    @"name" : presetName,
    @"createdAt" : [formatter stringFromDate:[NSDate date]],
    @"displays" : [self currentPresetDisplayStates],
  };

  self.displayPresets[presetName] = preset;
  [[NSUserDefaults standardUserDefaults] setObject:self.displayPresets forKey:RCTDisplayPresetsDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)applyPreset:(NSString *)name
{
  NSDictionary *preset = self.displayPresets[name];
  NSDictionary *displayStates = preset[@"displays"];

  if (![displayStates isKindOfClass:NSDictionary.class]) {
    return [self stubbedSnapshot];
  }

  for (NSString *displayID in displayStates) {
    NSDictionary *displayState = displayStates[displayID];

    if (![displayState isKindOfClass:NSDictionary.class]) {
      continue;
    }

    NSString *resolvedDisplayID = [self resolveDisplayIDString:displayID storedState:displayState];
    CGDirectDisplayID directDisplayID = (CGDirectDisplayID)resolvedDisplayID.integerValue;
    NSString *modeID = displayState[@"modeID"];
    NSString *colorProfileID = displayState[@"colorProfileID"];
    NSDictionary *frame = displayState[@"frame"];
    NSNumber *dimmingLevel = displayState[@"softwareDimming"];
    NSNumber *nativeBrightness = displayState[@"nativeBrightness"];
    NSDictionary *ddc = displayState[@"ddc"];

    if ([modeID isKindOfClass:NSString.class]) {
      [self applyDisplayModeForDisplayID:directDisplayID
                                   modeID:modeID
                          displayIDString:resolvedDisplayID];
    }

    if ([colorProfileID isKindOfClass:NSString.class]) {
      [self applyColorProfileForDisplayID:directDisplayID
                                profileID:colorProfileID
                          displayIDString:resolvedDisplayID];
    }

    if ([frame isKindOfClass:NSDictionary.class]) {
      [self applyDisplayOriginForDisplayID:directDisplayID
                                         x:[frame[@"x"] intValue]
                                         y:[frame[@"y"] intValue]];
    }

    if ([dimmingLevel isKindOfClass:NSNumber.class]) {
      double clampedLevel = MIN(MAX(dimmingLevel.doubleValue, 0), 0.8);
      self.dimmingLevels[resolvedDisplayID] = @(clampedLevel);
      [self syncDimmingWindowForDisplayID:directDisplayID level:clampedLevel];
    }

    if ([nativeBrightness isKindOfClass:NSNumber.class]) {
      [self setNativeBrightnessForDisplayID:directDisplayID
                                      level:MIN(MAX(nativeBrightness.doubleValue, 0), 1)
                               errorMessage:nil];
    }

    if ([ddc isKindOfClass:NSDictionary.class]) {
      [self applyDdcPresetState:ddc displayIDString:resolvedDisplayID displayID:directDisplayID];
    }
  }

  [[NSUserDefaults standardUserDefaults] setObject:self.dimmingLevels forKey:RCTDisplayDimmingDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.ddcValues forKey:RCTDisplayDdcDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)deletePreset:(NSString *)name
{
  [self.displayPresets removeObjectForKey:name];
  [[NSUserDefaults standardUserDefaults] setObject:self.displayPresets forKey:RCTDisplayPresetsDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)setColorProfile:(NSString *)displayID profileID:(NSString *)profileID
{
  [self applyColorProfileForDisplayID:(CGDirectDisplayID)displayID.integerValue
                            profileID:profileID
                      displayIDString:displayID];

  return [self stubbedSnapshot];
}

- (NSDictionary *)resetColorProfile:(NSString *)displayID
{
  [self applyColorProfileForDisplayID:(CGDirectDisplayID)displayID.integerValue
                            profileID:RCTFactoryColorProfileID
                      displayIDString:displayID];

  return [self stubbedSnapshot];
}

- (NSDictionary *)saveProtectedLayout
{
  self.protectedLayout = [self currentLayoutState];
  [[NSUserDefaults standardUserDefaults] setObject:self.protectedLayout forKey:RCTDisplayProtectedLayoutDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)restoreProtectedLayout
{
  [self restoreLayoutState:self.protectedLayout];

  return [self stubbedSnapshot];
}

- (NSDictionary *)clearProtectedLayout
{
  self.protectedLayout = @{};
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:RCTDisplayProtectedLayoutDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)saveSyncGroup:(NSString *)name
                     displayIDs:(NSArray<NSString *> *)displayIDs
                 brightnessSync:(BOOL)brightnessSync
                      scaleSync:(BOOL)scaleSync
                layoutProtection:(BOOL)layoutProtection
{
  NSString *groupID = [[NSUUID UUID] UUIDString];
  NSString *groupName = [self normalizedSyncGroupName:name];
  NSDictionary *group = @{
    @"id" : groupID,
    @"name" : groupName,
    @"displayIDs" : displayIDs,
    @"brightnessSync" : @(brightnessSync),
    @"scaleSync" : @(scaleSync),
    @"layoutProtection" : @(layoutProtection),
    @"layout" : layoutProtection ? [self currentLayoutStateForDisplayIDStrings:displayIDs] : @{},
  };

  self.syncGroups[groupID] = group;
  [[NSUserDefaults standardUserDefaults] setObject:self.syncGroups forKey:RCTDisplaySyncGroupsDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)applySyncGroup:(NSString *)groupID
{
  NSDictionary *group = self.syncGroups[groupID];

  if (![group isKindOfClass:NSDictionary.class]) {
    return [self stubbedSnapshot];
  }

  [self applySyncGroupDictionary:group];

  return [self stubbedSnapshot];
}

- (NSDictionary *)deleteSyncGroup:(NSString *)groupID
{
  [self.syncGroups removeObjectForKey:groupID];
  [[NSUserDefaults standardUserDefaults] setObject:self.syncGroups forKey:RCTDisplaySyncGroupsDefaultsKey];

  return [self stubbedSnapshot];
}

- (void)recordAdvancedOperation:(NSString *)operation displayID:(NSString *)displayID
{
  if (displayID.length == 0) {
    return;
  }

  NSISO8601DateFormatter *formatter = [NSISO8601DateFormatter new];
  self.advancedOperations[displayID] = operation ?: @"";
  self.advancedOperationDates[displayID] = [formatter stringFromDate:[NSDate date]];
  [[NSUserDefaults standardUserDefaults] setObject:self.advancedOperations forKey:RCTDisplayAdvancedOperationDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.advancedOperationDates
                                            forKey:RCTDisplayAdvancedOperationDatesDefaultsKey];
}

- (NSDictionary *)exportEdid:(NSString *)displayID
{
  [self exportEdidFileForDisplayIDString:displayID];

  return [self stubbedSnapshot];
}

- (NSString *)exportEdidFileForDisplayIDString:(NSString *)displayID
{
  CGDirectDisplayID directDisplayID = (CGDirectDisplayID)displayID.integerValue;
  NSData *edidData = [self edidDataForDisplayID:directDisplayID];

  if (edidData.length == 0) {
    [self recordAdvancedOperation:@"EDID unavailable" displayID:displayID];
    return @"";
  }

  NSURL *directoryURL =
      [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject
          URLByAppendingPathComponent:@"MacDisplayBar"
                          isDirectory:YES];
  [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:nil];
  NSURL *fileURL = [directoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"EDID-%@.bin", displayID]];
  BOOL didWrite = [edidData writeToURL:fileURL atomically:YES];

  if (!didWrite) {
    [self recordAdvancedOperation:@"EDID export failed" displayID:displayID];
    return @"";
  }

  self.edidExportPaths[displayID] = fileURL.path;
  [self recordAdvancedOperation:@"EDID exported" displayID:displayID];
  [[NSUserDefaults standardUserDefaults] setObject:self.edidExportPaths forKey:RCTDisplayEdidExportPathsDefaultsKey];

  return fileURL.path;
}

- (NSDictionary *)addCustomResolution:(NSString *)displayID
                                width:(double)width
                               height:(double)height
                          refreshRate:(double)refreshRate
                              isHiDpi:(BOOL)isHiDpi
{
  NSDictionary *request = @{
    @"id" : [[NSUUID UUID] UUIDString],
    @"width" : @(MAX(width, 1)),
    @"height" : @(MAX(height, 1)),
    @"refreshRate" : @(MAX(refreshRate, 0)),
    @"isHiDpi" : @(isHiDpi),
    @"status" : @"Queued for override",
  };
  NSMutableArray<NSDictionary *> *requests = [self.customResolutionRequests[displayID] mutableCopy] ?: [NSMutableArray new];
  [requests addObject:request];
  self.customResolutionRequests[displayID] = requests;
  [self recordAdvancedOperation:@"Custom resolution request saved" displayID:displayID];
  [[NSUserDefaults standardUserDefaults] setObject:self.customResolutionRequests
                                            forKey:RCTDisplayCustomResolutionsDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)removeCustomResolution:(NSString *)displayID requestID:(NSString *)requestID
{
  NSMutableArray<NSDictionary *> *requests = [self.customResolutionRequests[displayID] mutableCopy] ?: [NSMutableArray new];
  NSIndexSet *matchingIndexes = [requests indexesOfObjectsPassingTest:^BOOL(NSDictionary *request, NSUInteger index, BOOL *stop) {
    return [request[@"id"] isEqualToString:requestID];
  }];
  [requests removeObjectsAtIndexes:matchingIndexes];
  self.customResolutionRequests[displayID] = requests;
  [self recordAdvancedOperation:@"Custom resolution request removed" displayID:displayID];
  [[NSUserDefaults standardUserDefaults] setObject:self.customResolutionRequests
                                            forKey:RCTDisplayCustomResolutionsDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)queueEdidOverride:(NSString *)displayID
{
  NSString *edidPath = self.edidExportPaths[displayID];

  if (edidPath.length == 0) {
    edidPath = [self exportEdidFileForDisplayIDString:displayID];
  }

  if (edidPath.length > 0) {
    self.edidOverridePaths[displayID] = edidPath;
    self.edidOverrideStatus[displayID] = @"Override requested";
    [self recordAdvancedOperation:@"EDID override request queued" displayID:displayID];
    [[NSUserDefaults standardUserDefaults] setObject:self.edidOverridePaths forKey:RCTDisplayEdidOverridePathsDefaultsKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.edidOverrideStatus forKey:RCTDisplayEdidOverrideStatusDefaultsKey];
  } else {
    self.edidOverrideStatus[displayID] = @"EDID unavailable";
    [self recordAdvancedOperation:@"EDID override unavailable" displayID:displayID];
  }

  return [self stubbedSnapshot];
}

- (NSDictionary *)clearEdidOverride:(NSString *)displayID
{
  [self.edidOverridePaths removeObjectForKey:displayID];
  self.edidOverrideStatus[displayID] = @"Override cleared";
  [self recordAdvancedOperation:@"EDID override cleared" displayID:displayID];
  [[NSUserDefaults standardUserDefaults] setObject:self.edidOverridePaths forKey:RCTDisplayEdidOverridePathsDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.edidOverrideStatus forKey:RCTDisplayEdidOverrideStatusDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)writeOverrideBundle:(NSString *)displayID
{
  NSString *bundlePath = [self writeOverrideBundleForDisplayIDString:displayID];

  if (bundlePath.length > 0) {
    self.overrideBundlePaths[displayID] = bundlePath;
    self.overrideBundleStatus[displayID] = @"Bundle written";
    [self recordAdvancedOperation:@"Display override bundle written" displayID:displayID];
    [[NSUserDefaults standardUserDefaults] setObject:self.overrideBundlePaths
                                              forKey:RCTDisplayOverrideBundlePathsDefaultsKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.overrideBundleStatus
                                              forKey:RCTDisplayOverrideBundleStatusDefaultsKey];
  } else {
    self.overrideBundleStatus[displayID] = @"Bundle write failed";
    [self recordAdvancedOperation:@"Display override bundle failed" displayID:displayID];
  }

  return [self stubbedSnapshot];
}

- (NSDictionary *)setDisplayRotation:(NSString *)displayID rotation:(double)rotation
{
  double normalizedRotation = [self normalizedRotation:rotation];
  CGDirectDisplayID directDisplayID = (CGDirectDisplayID)displayID.integerValue;
  double currentRotation = CGDisplayRotation(directDisplayID);

  self.rotationRequests[displayID] = @(normalizedRotation);

  if (llround(currentRotation) == llround(normalizedRotation)) {
    self.rotationStatus[displayID] = [NSString stringWithFormat:@"Already %.0f degrees", normalizedRotation];
    [self recordAdvancedOperation:@"Rotation already current" displayID:displayID];
  } else {
    self.rotationStatus[displayID] = [NSString stringWithFormat:@"Queued %.0f degrees", normalizedRotation];
    [self recordAdvancedOperation:@"Rotation request queued" displayID:displayID];
  }

  [[NSUserDefaults standardUserDefaults] setObject:self.rotationRequests forKey:RCTDisplayRotationRequestsDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.rotationStatus forKey:RCTDisplayRotationStatusDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)enableXdrUpscale:(NSString *)displayID
{
  CGDirectDisplayID directDisplayID = (CGDirectDisplayID)displayID.integerValue;
  BOOL supportsHdr = [self displaySupportsHdrForDisplayID:directDisplayID];

  if (supportsHdr) {
    [self setNativeBrightnessForDisplayID:directDisplayID level:1 errorMessage:nil];
    [self syncXdrUpscaleWindowForDisplayID:directDisplayID enabled:YES];
    self.xdrUpscaleStates[displayID] = @"enabled";
    [self recordAdvancedOperation:@"Extra brightness enabled" displayID:displayID];
  } else {
    [self syncXdrUpscaleWindowForDisplayID:directDisplayID enabled:NO];
    self.xdrUpscaleStates[displayID] = @"unsupported";
    [self recordAdvancedOperation:@"Extra brightness unsupported" displayID:displayID];
  }

  [[NSUserDefaults standardUserDefaults] setObject:self.xdrUpscaleStates forKey:RCTDisplayXdrUpscaleDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)disableXdrUpscale:(NSString *)displayID
{
  [self syncXdrUpscaleWindowForDisplayID:(CGDirectDisplayID)displayID.integerValue enabled:NO];
  self.xdrUpscaleStates[displayID] = @"disabled";
  [self recordAdvancedOperation:@"Extra brightness disabled" displayID:displayID];
  [[NSUserDefaults standardUserDefaults] setObject:self.xdrUpscaleStates forKey:RCTDisplayXdrUpscaleDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)softDisconnectDisplay:(NSString *)displayID
{
  BOOL didSend = [self sendDdcSetVcpForDisplayID:(CGDirectDisplayID)displayID.integerValue
                                     controlCode:0xD6
                                           value:0x04
                                    errorMessage:nil];

  self.softConnectionStates[displayID] = didSend ? @"disconnect-requested" : @"disconnect-unavailable";
  [self recordAdvancedOperation:(didSend ? @"DDC power-mode disconnect requested" : @"DDC power-mode disconnect unavailable")
                       displayID:displayID];
  [[NSUserDefaults standardUserDefaults] setObject:self.softConnectionStates forKey:RCTDisplaySoftConnectionDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)reconnectDisplay:(NSString *)displayID
{
  BOOL didSend = [self sendDdcSetVcpForDisplayID:(CGDirectDisplayID)displayID.integerValue
                                     controlCode:0xD6
                                           value:0x01
                                    errorMessage:nil];

  self.softConnectionStates[displayID] = didSend ? @"connected" : @"reconnect-unavailable";
  [self recordAdvancedOperation:(didSend ? @"DDC power-mode reconnect requested" : @"DDC power-mode reconnect unavailable")
                       displayID:displayID];
  [[NSUserDefaults standardUserDefaults] setObject:self.softConnectionStates forKey:RCTDisplaySoftConnectionDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)saveFavoriteMode:(NSString *)displayID modeID:(NSString *)modeID
{
  NSMutableArray<NSString *> *modes = [self.favoriteModes[displayID] mutableCopy] ?: [NSMutableArray new];

  if (![modes containsObject:modeID]) {
    [modes addObject:modeID];
  }

  self.favoriteModes[displayID] = modes;
  [[NSUserDefaults standardUserDefaults] setObject:self.favoriteModes forKey:RCTDisplayFavoriteModesDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)removeFavoriteMode:(NSString *)displayID modeID:(NSString *)modeID
{
  NSMutableArray<NSString *> *modes = [self.favoriteModes[displayID] mutableCopy] ?: [NSMutableArray new];
  [modes removeObject:modeID];
  self.favoriteModes[displayID] = modes;
  [[NSUserDefaults standardUserDefaults] setObject:self.favoriteModes forKey:RCTDisplayFavoriteModesDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary *)setDdcControl:(NSString *)displayID controlCode:(double)controlCode value:(double)value
{
  uint8_t clampedControlCode = (uint8_t)MIN(MAX(controlCode, 0), 255);
  uint16_t clampedValue = (uint16_t)MIN(MAX(value, 0), 65535);
  NSString *errorMessage = nil;
  CGDirectDisplayID directDisplayID = (CGDirectDisplayID)displayID.integerValue;

  BOOL didSend = [self sendDdcSetVcpForDisplayID:directDisplayID
                                     controlCode:clampedControlCode
                                           value:clampedValue
                                    errorMessage:&errorMessage];

  if (didSend) {
    self.ddcValues[[self ddcKeyForDisplayIDString:displayID controlCode:clampedControlCode]] = @(clampedValue);
    [self.ddcErrors removeObjectForKey:displayID];
    [[NSUserDefaults standardUserDefaults] setObject:self.ddcValues forKey:RCTDisplayDdcDefaultsKey];

    if (clampedControlCode == 0x10) {
      [self syncDdcBrightnessFromDisplayIDString:displayID value:clampedValue];
    }
  } else {
    self.ddcErrors[displayID] = errorMessage ?: @"DDC command failed";
  }

  return [self stubbedSnapshot];
}

- (NSDictionary *)setSettings:(BOOL)autoRefresh
        refreshIntervalSeconds:(double)refreshIntervalSeconds
          showAdvancedMetadata:(BOOL)showAdvancedMetadata
{
  self.settings = [[self normalizedSettingsFromDictionary:@{
    @"autoRefresh" : @(autoRefresh),
    @"refreshIntervalSeconds" : @(refreshIntervalSeconds),
    @"showAdvancedMetadata" : @(showAdvancedMetadata),
  }] mutableCopy];
  [[NSUserDefaults standardUserDefaults] setObject:self.settings forKey:RCTDisplaySettingsDefaultsKey];

  return [self stubbedSnapshot];
}

- (NSDictionary<NSString *, NSNumber *> *)normalizedSettingsFromDictionary:(NSDictionary *)settings
{
  NSNumber *autoRefresh = [settings[@"autoRefresh"] isKindOfClass:NSNumber.class] ? settings[@"autoRefresh"] : @NO;
  NSNumber *showAdvancedMetadata =
      [settings[@"showAdvancedMetadata"] isKindOfClass:NSNumber.class] ? settings[@"showAdvancedMetadata"] : @YES;
  double refreshInterval = [settings[@"refreshIntervalSeconds"] isKindOfClass:NSNumber.class]
      ? [settings[@"refreshIntervalSeconds"] doubleValue]
      : 15;

  refreshInterval = MIN(MAX(refreshInterval, 5), 300);

  return @{
    @"autoRefresh" : @(autoRefresh.boolValue),
    @"refreshIntervalSeconds" : @(refreshInterval),
    @"showAdvancedMetadata" : @(showAdvancedMetadata.boolValue),
  };
}

- (NSDictionary *)stubbedSnapshot
{
  NSISO8601DateFormatter *formatter = [NSISO8601DateFormatter new];
  NSDictionary<NSString *, NSDictionary *> *screenMetadata = [self screenMetadataForActiveDisplays];
  NSArray<NSDictionary *> *displays = [self activeDisplayDictionariesWithScreenMetadata:screenMetadata];
  NSUInteger layoutDriftCount = [self protectedLayoutDriftCount];
  BOOL layoutProtectionEnabled = self.protectedLayout.count > 0;

  return @{
    @"moduleStatus" : @"ready",
    @"generatedAt" : [formatter stringFromDate:[NSDate date]],
    @"platform" : NSProcessInfo.processInfo.operatingSystemVersionString,
    @"architecture" : [self machineArchitecture],
    @"machineModel" : [self machineModel],
    @"isAppleSilicon" : @([[self machineArchitecture] isEqualToString:@"arm64"]),
    @"displayTopologyRevision" : @(self.displayTopologyRevision),
    @"displayTopologyStatus" : self.displayTopologyStatus ?: @"Stable",
    @"displayTopologyChangedAt" : self.displayTopologyChangedAt ?: @"",
    @"displays" : displays,
    @"presets" : [self presetSummaries],
    @"syncGroups" : [self syncGroupSummaries],
    @"layoutProtectionEnabled" : @(layoutProtectionEnabled),
    @"layoutProtectionStatus" :
        !layoutProtectionEnabled ? @"Unprotected" : (layoutDriftCount == 0 ? @"Protected" : @"Drift detected"),
    @"layoutDriftCount" : @(layoutDriftCount),
    @"settings" : [self normalizedSettingsFromDictionary:self.settings],
  };
}

- (NSArray<NSDictionary *> *)activeDisplayDictionaries
{
  return [self activeDisplayDictionariesWithScreenMetadata:[self screenMetadataForActiveDisplays]];
}

- (NSArray<NSDictionary *> *)activeDisplayDictionariesWithScreenMetadata:
    (NSDictionary<NSString *, NSDictionary *> *)screenMetadata
{
  uint32_t displayCount = 0;
  CGError countError = CGGetActiveDisplayList(0, NULL, &displayCount);

  if (countError != kCGErrorSuccess || displayCount == 0) {
    return @[];
  }

  std::vector<CGDirectDisplayID> displayIDs(displayCount);
  CGError listError = CGGetActiveDisplayList(displayCount, displayIDs.data(), &displayCount);

  if (listError != kCGErrorSuccess) {
    return @[];
  }

  NSMutableArray<NSDictionary *> *displays = [NSMutableArray arrayWithCapacity:displayCount];

  for (uint32_t index = 0; index < displayCount; index++) {
    [displays addObject:[self dictionaryForDisplay:displayIDs[index] screenMetadata:screenMetadata]];
  }

  return displays;
}

- (NSDictionary<NSString *, NSDictionary *> *)screenMetadataForActiveDisplays
{
  if (![NSThread isMainThread]) {
    __block NSDictionary<NSString *, NSDictionary *> *metadata = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
      metadata = [self screenMetadataForActiveDisplays];
    });

    return metadata ?: @{};
  }

  NSMutableDictionary<NSString *, NSDictionary *> *metadata = [NSMutableDictionary new];

  for (NSScreen *screen in NSScreen.screens) {
    NSNumber *screenNumber = screen.deviceDescription[@"NSScreenNumber"];

    if (![screenNumber isKindOfClass:NSNumber.class]) {
      continue;
    }

    NSString *displayIDString = [NSString stringWithFormat:@"%u", screenNumber.unsignedIntValue];
    metadata[displayIDString] = @{
      @"localizedName" : screen.localizedName ?: @"",
      @"hdr" : [self hdrStateForScreen:screen],
    };
  }

  return metadata;
}

- (NSDictionary *)dictionaryForDisplay:(CGDirectDisplayID)displayID
                        screenMetadata:(NSDictionary<NSString *, NSDictionary *> *)screenMetadata
{
  CGDisplayModeRef mode = CGDisplayCopyDisplayMode(displayID);
  size_t width = mode != NULL ? CGDisplayModeGetWidth(mode) : CGDisplayPixelsWide(displayID);
  size_t height = mode != NULL ? CGDisplayModeGetHeight(mode) : CGDisplayPixelsHigh(displayID);
  double refreshRate = mode != NULL ? CGDisplayModeGetRefreshRate(mode) : 0;
  BOOL isHiDpi = mode != NULL && CGDisplayModeGetPixelWidth(mode) > width;
  NSString *currentModeID = mode != NULL ? [self modeIDForMode:mode] : @"";
  CGRect frame = CGDisplayBounds(displayID);
  BOOL isBuiltin = CGDisplayIsBuiltin(displayID);
  CGDirectDisplayID mirroredDisplayID = CGDisplayMirrorsDisplay(displayID);
  NSString *displayIDString = [NSString stringWithFormat:@"%u", displayID];
  NSDictionary *currentScreenMetadata = screenMetadata[displayIDString] ?: @{};
  NSString *screenName = [currentScreenMetadata[@"localizedName"] isKindOfClass:NSString.class]
      ? currentScreenMetadata[@"localizedName"]
      : @"";
  NSDictionary *identity = [self identityForDisplayID:displayID screenName:screenName];
  double dimmingLevel = [self dimmingLevelForDisplayIDString:displayIDString];
  BOOL supportsDdc = [self displaySupportsDdc:displayID];
  BOOL supportsNativeBrightness = [self displaySupportsNativeBrightness:displayID];
  double nativeBrightness = [self nativeBrightnessForDisplayID:displayID didRead:nil];
  NSDictionary *hdrState = [currentScreenMetadata[@"hdr"] isKindOfClass:NSDictionary.class] ? currentScreenMetadata[@"hdr"] : [self unavailableHdrState];

  NSDictionary *display = @{
    @"id" : displayIDString,
    @"name" : [self displayNameForDisplayID:displayID screenName:screenName],
    @"connectionType" : isBuiltin ? @"built-in" : @"external",
    @"isPrimary" : @(CGDisplayIsMain(displayID)),
    @"isBuiltin" : @(isBuiltin),
    @"isOnline" : @(CGDisplayIsOnline(displayID)),
    @"isActive" : @(CGDisplayIsActive(displayID)),
    @"isAsleep" : @(CGDisplayIsAsleep(displayID)),
    @"isMirrored" : @(CGDisplayIsInMirrorSet(displayID)),
    @"isHardwareMirrored" : @(CGDisplayIsInHWMirrorSet(displayID)),
    @"mirrorsDisplayID" : mirroredDisplayID == kCGNullDirectDisplay ? @"" : [NSString stringWithFormat:@"%u", mirroredDisplayID],
    @"identity" : identity,
    @"rotation" : @(CGDisplayRotation(displayID)),
    @"frame" : @{
      @"x" : @(frame.origin.x),
      @"y" : @(frame.origin.y),
      @"width" : @(frame.size.width),
      @"height" : @(frame.size.height),
    },
    @"currentMode" : @{
      @"id" : currentModeID,
      @"width" : @(width),
      @"height" : @(height),
      @"refreshRate" : @(refreshRate),
      @"isHiDpi" : @(isHiDpi),
      @"isCurrent" : @YES,
      @"isFavorite" : @([self modeIDIsFavorite:currentModeID displayIDString:displayIDString]),
    },
    @"availableModes" : [self availableModeDictionariesForDisplayID:displayID currentModeID:currentModeID],
    @"modeStatus" : self.modeStatus[displayIDString] ?: @"Ready",
    @"modeError" : self.modeErrors[displayIDString] ?: @"",
    @"nativeBrightness" : @(nativeBrightness),
    @"brightnessControl" : supportsNativeBrightness ? @"native" : (supportsDdc ? @"ddc" : @"none"),
    @"brightnessError" : self.brightnessErrors[displayIDString] ?: @"",
    @"softwareDimming" : @(dimmingLevel),
    @"supportsBrightness" : @(supportsNativeBrightness || supportsDdc),
    @"supportsSoftwareDimming" : @YES,
    @"supportsDdc" : @(supportsDdc),
    @"ddc" : [self ddcStateForDisplayIDString:displayIDString supportsDdc:supportsDdc],
    @"supportsHdr" : hdrState[@"isSupported"],
    @"hdr" : hdrState,
    @"colorProfileStatus" : self.colorProfileStatus[displayIDString] ?: @"Ready",
    @"colorProfileError" : self.colorProfileErrors[displayIDString] ?: @"",
    @"colorProfiles" : [self colorProfilesForDisplayID:displayID],
    @"advanced" : [self advancedStateForDisplayID:displayID displayIDString:displayIDString],
  };

  if (mode != NULL) {
    CGDisplayModeRelease(mode);
  }

  return display;
}

- (NSDictionary *)identityForDisplayID:(CGDirectDisplayID)displayID screenName:(NSString *)screenName
{
  uint32_t vendorID = CGDisplayVendorNumber(displayID);
  uint32_t modelID = CGDisplayModelNumber(displayID);
  uint32_t serialNumber = CGDisplaySerialNumber(displayID);
  NSDictionary *ioDisplayInfo = [self ioDisplayInfoForDisplayID:displayID];
  NSString *productName = [self productNameFromIODisplayInfo:ioDisplayInfo
                                                    fallback:[self displayNameForDisplayID:displayID screenName:screenName]];
  NSString *transport = CGDisplayIsBuiltin(displayID) ? @"built-in" : @"external";

  return @{
    @"uuid" : [self displayUUIDStringForDisplayID:displayID],
    @"vendorID" : @(vendorID),
    @"modelID" : @(modelID),
    @"serialNumber" : @(serialNumber),
    @"productName" : productName,
    @"transport" : transport,
  };
}

- (NSDictionary *)ioDisplayInfoForDisplayID:(CGDirectDisplayID)displayID
{
  uint32_t vendorID = CGDisplayVendorNumber(displayID);
  uint32_t productID = CGDisplayModelNumber(displayID);
  uint32_t serialNumber = CGDisplaySerialNumber(displayID);
  io_iterator_t iterator = MACH_PORT_NULL;
  kern_return_t result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"), &iterator);

  if (result != KERN_SUCCESS || iterator == MACH_PORT_NULL) {
    return @{};
  }

  io_service_t service = MACH_PORT_NULL;

  while ((service = IOIteratorNext(iterator)) != MACH_PORT_NULL) {
    NSDictionary *info = CFBridgingRelease(IODisplayCreateInfoDictionary(service, kIODisplayOnlyPreferredName));
    NSNumber *candidateVendorID = info[[NSString stringWithUTF8String:kDisplayVendorID]];
    NSNumber *candidateProductID = info[[NSString stringWithUTF8String:kDisplayProductID]];
    NSNumber *candidateSerialNumber = info[[NSString stringWithUTF8String:kDisplaySerialNumber]];
    BOOL vendorMatches = candidateVendorID.unsignedIntValue == vendorID;
    BOOL productMatches = candidateProductID.unsignedIntValue == productID;
    BOOL serialMatches = serialNumber == 0 || candidateSerialNumber.unsignedIntValue == serialNumber;

    if (vendorMatches && productMatches && serialMatches) {
      IOObjectRelease(service);
      IOObjectRelease(iterator);
      return info ?: @{};
    }

    IOObjectRelease(service);
  }

  IOObjectRelease(iterator);
  return @{};
}

- (NSString *)productNameFromIODisplayInfo:(NSDictionary *)info fallback:(NSString *)fallback
{
  NSDictionary *names = info[[NSString stringWithUTF8String:kDisplayProductName]];

  if ([names isKindOfClass:NSDictionary.class]) {
    NSString *preferredName = names.allValues.firstObject;

    if ([preferredName isKindOfClass:NSString.class] && preferredName.length > 0) {
      return preferredName;
    }
  }

  return fallback;
}

- (NSString *)displayUUIDStringForDisplayID:(CGDirectDisplayID)displayID
{
  CFUUIDRef displayUUID = CGDisplayCreateUUIDFromDisplayID(displayID);

  if (displayUUID == NULL) {
    return @"";
  }

  NSString *uuidString = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, displayUUID));
  CFRelease(displayUUID);

  return uuidString ?: @"";
}

- (NSString *)displayNameForDisplayID:(CGDirectDisplayID)displayID screenName:(NSString *)screenName
{
  if (screenName.length > 0) {
    return screenName;
  }

  return [NSString stringWithFormat:@"Display %u", displayID];
}

- (NSString *)machineArchitecture
{
  struct utsname systemInfo;

  if (uname(&systemInfo) != 0) {
    return @"unknown";
  }

  return [NSString stringWithUTF8String:systemInfo.machine];
}

- (NSString *)machineModel
{
  size_t size = 0;

  if (sysctlbyname("hw.model", NULL, &size, NULL, 0) != 0 || size == 0) {
    return @"unknown";
  }

  std::vector<char> model(size);

  if (sysctlbyname("hw.model", model.data(), &size, NULL, 0) != 0) {
    return @"unknown";
  }

  return [NSString stringWithUTF8String:model.data()];
}

- (void)handleDisplayReconfiguration:(CGDirectDisplayID)displayID flags:(CGDisplayChangeSummaryFlags)flags
{
  NSISO8601DateFormatter *formatter = [NSISO8601DateFormatter new];

  @synchronized(self) {
    self.displayTopologyRevision += 1;
    self.displayTopologyStatus = [NSString stringWithFormat:@"Display %@ %@",
                                                            [NSString stringWithFormat:@"%u", displayID],
                                                            [self displayChangeStatusForFlags:flags]];
    self.displayTopologyChangedAt = [formatter stringFromDate:[NSDate date]];
  }
}

- (NSString *)displayChangeStatusForFlags:(CGDisplayChangeSummaryFlags)flags
{
  NSMutableArray<NSString *> *parts = [NSMutableArray new];

  if (flags & kCGDisplayBeginConfigurationFlag) {
    [parts addObject:@"begin"];
  }

  if (flags & kCGDisplayMovedFlag) {
    [parts addObject:@"moved"];
  }

  if (flags & kCGDisplaySetMainFlag) {
    [parts addObject:@"main"];
  }

  if (flags & kCGDisplaySetModeFlag) {
    [parts addObject:@"mode"];
  }

  if (flags & kCGDisplayAddFlag) {
    [parts addObject:@"added"];
  }

  if (flags & kCGDisplayRemoveFlag) {
    [parts addObject:@"removed"];
  }

  if (flags & kCGDisplayEnabledFlag) {
    [parts addObject:@"enabled"];
  }

  if (flags & kCGDisplayDisabledFlag) {
    [parts addObject:@"disabled"];
  }

  if (flags & kCGDisplayMirrorFlag) {
    [parts addObject:@"mirror"];
  }

  if (flags & kCGDisplayUnMirrorFlag) {
    [parts addObject:@"unmirror"];
  }

  if (flags & kCGDisplayDesktopShapeChangedFlag) {
    [parts addObject:@"shape"];
  }

  return parts.count > 0 ? [parts componentsJoinedByString:@"+"] : @"changed";
}

- (NSScreen *)screenForDisplayID:(CGDirectDisplayID)displayID
{
  for (NSScreen *screen in NSScreen.screens) {
    NSNumber *screenNumber = screen.deviceDescription[@"NSScreenNumber"];

    if (screenNumber.unsignedIntValue == displayID) {
      return screen;
    }
  }

  return nil;
}

- (BOOL)displaySupportsHdrForDisplayID:(CGDirectDisplayID)displayID
{
  if (![NSThread isMainThread]) {
    __block BOOL supportsHdr = NO;
    dispatch_sync(dispatch_get_main_queue(), ^{
      supportsHdr = [self displaySupportsHdrForDisplayID:displayID];
    });

    return supportsHdr;
  }

  NSScreen *screen = [self screenForDisplayID:displayID];
  return [self screenSupportsHdr:screen];
}

- (BOOL)screenSupportsHdr:(NSScreen *)screen
{
  if (screen == nil) {
    return NO;
  }

  return screen.maximumPotentialExtendedDynamicRangeColorComponentValue > 1;
}

- (NSDictionary *)hdrStateForScreen:(NSScreen *)screen
{
  if (screen == nil) {
    return [self unavailableHdrState];
  }

  CGFloat currentHeadroom = screen.maximumExtendedDynamicRangeColorComponentValue;
  CGFloat potentialHeadroom = screen.maximumPotentialExtendedDynamicRangeColorComponentValue;
  CGFloat referenceHeadroom = screen.maximumReferenceExtendedDynamicRangeColorComponentValue;
  BOOL isSupported = potentialHeadroom > 1;
  BOOL isActive = currentHeadroom > 1;
  NSString *xdrPreset = isSupported ? @"System managed" : @"Unavailable";

  if (referenceHeadroom > 1) {
    xdrPreset = @"Reference capable";
  }

  return @{
    @"isSupported" : @(isSupported),
    @"isActive" : @(isActive),
    @"currentHeadroom" : @(currentHeadroom),
    @"potentialHeadroom" : @(potentialHeadroom),
    @"referenceHeadroom" : @(referenceHeadroom),
    @"xdrPreset" : xdrPreset,
  };
}

- (NSDictionary *)unavailableHdrState
{
  return @{
    @"isSupported" : @NO,
    @"isActive" : @NO,
    @"currentHeadroom" : @1,
    @"potentialHeadroom" : @1,
    @"referenceHeadroom" : @0,
    @"xdrPreset" : @"Unavailable",
  };
}

- (NSArray<NSDictionary *> *)colorProfilesForDisplayID:(CGDirectDisplayID)displayID
{
  CFUUIDRef displayUUID = CGDisplayCreateUUIDFromDisplayID(displayID);

  if (displayUUID == NULL) {
    return @[];
  }

  NSMutableArray<NSDictionary *> *profiles = [NSMutableArray new];
  RCTColorProfileContext context = {displayUUID, profiles};
  ColorSyncIterateDeviceProfiles(RCTCollectColorProfile, &context);
  CFRelease(displayUUID);

  [profiles sortUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
    NSNumber *leftCurrent = left[@"isCurrent"];
    NSNumber *rightCurrent = right[@"isCurrent"];

    if (leftCurrent.boolValue != rightCurrent.boolValue) {
      return leftCurrent.boolValue ? NSOrderedAscending : NSOrderedDescending;
    }

    return [left[@"name"] compare:right[@"name"]];
  }];

  return profiles;
}

- (NSDictionary *)advancedStateForDisplayID:(CGDirectDisplayID)displayID displayIDString:(NSString *)displayIDString
{
  NSData *edidData = [self edidDataForDisplayID:displayID];
  NSArray *customResolutions = self.customResolutionRequests[displayIDString] ?: @[];
  NSNumber *rotationRequest = self.rotationRequests[displayIDString] ?: @(CGDisplayRotation(displayID));

  return @{
    @"supportsEdidExport" : @(edidData.length > 0),
    @"edidBytes" : @(edidData.length),
    @"edidExportPath" : self.edidExportPaths[displayIDString] ?: @"",
    @"edidOverridePath" : self.edidOverridePaths[displayIDString] ?: @"",
    @"edidOverrideStatus" : self.edidOverrideStatus[displayIDString] ?: @"No override",
    @"overrideBundlePath" : self.overrideBundlePaths[displayIDString] ?: @"",
    @"overrideBundleStatus" : self.overrideBundleStatus[displayIDString] ?: @"No bundle",
    @"rotationRequest" : rotationRequest,
    @"rotationStatus" : self.rotationStatus[displayIDString] ?: @"Current",
    @"softConnectionState" : self.softConnectionStates[displayIDString] ?: @"connected",
    @"xdrUpscaleState" : self.xdrUpscaleStates[displayIDString] ?: @"disabled",
    @"lastOperation" : self.advancedOperations[displayIDString] ?: @"",
    @"lastOperationAt" : self.advancedOperationDates[displayIDString] ?: @"",
    @"customResolutions" : customResolutions,
  };
}

- (NSData *)edidDataForDisplayID:(CGDirectDisplayID)displayID
{
  uint32_t vendorID = CGDisplayVendorNumber(displayID);
  uint32_t productID = CGDisplayModelNumber(displayID);
  uint32_t serialNumber = CGDisplaySerialNumber(displayID);
  io_iterator_t iterator = MACH_PORT_NULL;
  kern_return_t result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"), &iterator);

  if (result != KERN_SUCCESS || iterator == MACH_PORT_NULL) {
    return nil;
  }

  io_service_t service = MACH_PORT_NULL;

  while ((service = IOIteratorNext(iterator)) != MACH_PORT_NULL) {
    NSDictionary *info = CFBridgingRelease(IODisplayCreateInfoDictionary(service, kIODisplayOnlyPreferredName));
    NSNumber *candidateVendorID = info[[NSString stringWithUTF8String:kDisplayVendorID]];
    NSNumber *candidateProductID = info[[NSString stringWithUTF8String:kDisplayProductID]];
    NSNumber *candidateSerialNumber = info[[NSString stringWithUTF8String:kDisplaySerialNumber]];
    BOOL vendorMatches = candidateVendorID.unsignedIntValue == vendorID;
    BOOL productMatches = candidateProductID.unsignedIntValue == productID;
    BOOL serialMatches = serialNumber == 0 || candidateSerialNumber.unsignedIntValue == serialNumber;

    if (vendorMatches && productMatches && serialMatches) {
      NSData *edidData = CFBridgingRelease(IORegistryEntryCreateCFProperty(
          service, CFSTR(kIODisplayEDIDKey), kCFAllocatorDefault, kNilOptions));
      IOObjectRelease(service);
      IOObjectRelease(iterator);
      return edidData;
    }

    IOObjectRelease(service);
  }

  IOObjectRelease(iterator);
  return nil;
}

- (NSString *)writeOverrideBundleForDisplayIDString:(NSString *)displayID
{
  CGDirectDisplayID directDisplayID = (CGDirectDisplayID)displayID.integerValue;
  uint32_t vendorID = CGDisplayVendorNumber(directDisplayID);
  uint32_t productID = CGDisplayModelNumber(directDisplayID);
  uint32_t serialNumber = CGDisplaySerialNumber(directDisplayID);
  NSData *edidData = [self edidDataForDisplayID:directDisplayID];
  NSArray *customResolutions = self.customResolutionRequests[displayID] ?: @[];
  NSISO8601DateFormatter *formatter = [NSISO8601DateFormatter new];
  NSString *vendorDirectoryName = [NSString stringWithFormat:@"DisplayVendorID-%x", vendorID];
  NSString *productFileName = [NSString stringWithFormat:@"DisplayProductID-%x.plist", productID];
  NSURL *baseDirectoryURL =
      [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject
          URLByAppendingPathComponent:@"MacDisplayBar/Overrides"
                          isDirectory:YES];
  NSURL *vendorDirectoryURL = [baseDirectoryURL URLByAppendingPathComponent:vendorDirectoryName isDirectory:YES];
  NSURL *fileURL = [vendorDirectoryURL URLByAppendingPathComponent:productFileName];

  [[NSFileManager defaultManager] createDirectoryAtURL:vendorDirectoryURL
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:nil];

  NSMutableDictionary *manifest = [@{
    @"DisplayID" : displayID,
    @"DisplayVendorID" : @(vendorID),
    @"DisplayProductID" : @(productID),
    @"DisplaySerialNumber" : @(serialNumber),
    @"GeneratedAt" : [formatter stringFromDate:[NSDate date]],
    @"TargetInstallDirectory" :
        @"/Library/Displays/Contents/Resources/Overrides",
    @"RequiresPrivilegedInstall" : @YES,
    @"CustomResolutions" : customResolutions,
    @"EdidOverrideSourcePath" : self.edidOverridePaths[displayID] ?: @"",
    @"RotationRequest" : self.rotationRequests[displayID] ?: @(CGDisplayRotation(directDisplayID)),
    @"XdrUpscaleState" : self.xdrUpscaleStates[displayID] ?: @"disabled",
    @"LastOperation" : self.advancedOperations[displayID] ?: @"",
    @"LastOperationAt" : self.advancedOperationDates[displayID] ?: @"",
  } mutableCopy];

  if (edidData.length > 0) {
    manifest[@"IODisplayEDID"] = edidData;
  }

  NSError *serializationError = nil;
  NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:manifest
                                                                  format:NSPropertyListXMLFormat_v1_0
                                                                 options:0
                                                                   error:&serializationError];

  if (plistData.length == 0 || serializationError != nil) {
    return @"";
  }

  BOOL didWrite = [plistData writeToURL:fileURL atomically:YES];
  return didWrite ? fileURL.path : @"";
}

- (double)normalizedRotation:(double)rotation
{
  NSArray<NSNumber *> *allowedRotations = @[ @0, @90, @180, @270 ];
  NSNumber *closestRotation = allowedRotations.firstObject;
  double closestDistance = DBL_MAX;

  for (NSNumber *candidate in allowedRotations) {
    double distance = fabs(candidate.doubleValue - rotation);

    if (distance < closestDistance) {
      closestDistance = distance;
      closestRotation = candidate;
    }
  }

  return closestRotation.doubleValue;
}

- (NSArray<NSDictionary *> *)availableModeDictionariesForDisplayID:(CGDirectDisplayID)displayID
                                                     currentModeID:(NSString *)currentModeID
{
  NSDictionary *options = @{(__bridge NSString *)kCGDisplayShowDuplicateLowResolutionModes : @YES};
  CFArrayRef copiedModes = CGDisplayCopyAllDisplayModes(displayID, (__bridge CFDictionaryRef)options);

  if (copiedModes == NULL) {
    return @[];
  }

  NSArray *modes = CFBridgingRelease(copiedModes);
  NSMutableArray<NSDictionary *> *modeDictionaries = [NSMutableArray arrayWithCapacity:modes.count];
  NSMutableSet<NSString *> *seenModeIDs = [NSMutableSet new];
  NSString *displayIDString = [NSString stringWithFormat:@"%u", displayID];

  for (id item in modes) {
    CGDisplayModeRef candidate = (__bridge CGDisplayModeRef)item;
    NSString *modeID = [self modeIDForMode:candidate];

    if ([seenModeIDs containsObject:modeID]) {
      continue;
    }

    [seenModeIDs addObject:modeID];
    NSMutableDictionary *modeDictionary = [[self dictionaryForMode:candidate currentModeID:currentModeID] mutableCopy];
    modeDictionary[@"isFavorite"] = @([self modeIDIsFavorite:modeID displayIDString:displayIDString]);
    [modeDictionaries addObject:modeDictionary];
  }

  [modeDictionaries sortUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
    NSNumber *leftFavorite = left[@"isFavorite"];
    NSNumber *rightFavorite = right[@"isFavorite"];
    NSNumber *leftWidth = left[@"width"];
    NSNumber *rightWidth = right[@"width"];
    NSNumber *leftHeight = left[@"height"];
    NSNumber *rightHeight = right[@"height"];
    NSNumber *leftRefreshRate = left[@"refreshRate"];
    NSNumber *rightRefreshRate = right[@"refreshRate"];

    if (leftFavorite.boolValue != rightFavorite.boolValue) {
      return leftFavorite.boolValue ? NSOrderedAscending : NSOrderedDescending;
    }

    if (leftWidth.integerValue != rightWidth.integerValue) {
      return leftWidth.integerValue > rightWidth.integerValue ? NSOrderedAscending : NSOrderedDescending;
    }

    if (leftHeight.integerValue != rightHeight.integerValue) {
      return leftHeight.integerValue > rightHeight.integerValue ? NSOrderedAscending : NSOrderedDescending;
    }

    if (leftRefreshRate.doubleValue != rightRefreshRate.doubleValue) {
      return leftRefreshRate.doubleValue > rightRefreshRate.doubleValue ? NSOrderedAscending : NSOrderedDescending;
    }

    return NSOrderedSame;
  }];

  return modeDictionaries;
}

- (BOOL)modeIDIsFavorite:(NSString *)modeID displayIDString:(NSString *)displayIDString
{
  return [self.favoriteModes[displayIDString] containsObject:modeID];
}

- (NSDictionary *)dictionaryForMode:(CGDisplayModeRef)mode currentModeID:(NSString *)currentModeID
{
  NSString *modeID = [self modeIDForMode:mode];
  size_t width = CGDisplayModeGetWidth(mode);
  size_t height = CGDisplayModeGetHeight(mode);
  double refreshRate = CGDisplayModeGetRefreshRate(mode);
  BOOL isHiDpi = CGDisplayModeGetPixelWidth(mode) > width;

  return @{
    @"id" : modeID,
    @"width" : @(width),
    @"height" : @(height),
    @"refreshRate" : @(refreshRate),
    @"isHiDpi" : @(isHiDpi),
    @"isCurrent" : @([modeID isEqualToString:currentModeID]),
    @"isFavorite" : @NO,
  };
}

- (NSString *)modeIDForMode:(CGDisplayModeRef)mode
{
  return [NSString stringWithFormat:@"%d-%zu-%zu-%zu-%zu-%.3f",
                                    CGDisplayModeGetIODisplayModeID(mode),
                                    CGDisplayModeGetWidth(mode),
                                    CGDisplayModeGetHeight(mode),
                                    CGDisplayModeGetPixelWidth(mode),
                                    CGDisplayModeGetPixelHeight(mode),
                                    CGDisplayModeGetRefreshRate(mode)];
}

- (BOOL)applyDisplayModeForDisplayID:(CGDirectDisplayID)displayID
                               modeID:(NSString *)modeID
                      displayIDString:(NSString *)displayIDString
{
  NSDictionary *options = @{(__bridge NSString *)kCGDisplayShowDuplicateLowResolutionModes : @YES};
  CFArrayRef copiedModes = CGDisplayCopyAllDisplayModes(displayID, (__bridge CFDictionaryRef)options);

  if (copiedModes == NULL) {
    self.modeStatus[displayIDString] = @"Unavailable";
    self.modeErrors[displayIDString] = @"Mode list unavailable";
    return NO;
  }

  NSArray *modes = CFBridgingRelease(copiedModes);

  for (id item in modes) {
    CGDisplayModeRef candidate = (__bridge CGDisplayModeRef)item;

    if ([[self modeIDForMode:candidate] isEqualToString:modeID]) {
      CGError result = CGDisplaySetDisplayMode(displayID, candidate, NULL);

      if (result == kCGErrorSuccess) {
        self.modeStatus[displayIDString] = @"Applied";
        [self.modeErrors removeObjectForKey:displayIDString];
        return YES;
      }

      self.modeStatus[displayIDString] = @"Failed";
      self.modeErrors[displayIDString] = [NSString stringWithFormat:@"Mode apply failed: %d", result];
      return NO;
    }
  }

  self.modeStatus[displayIDString] = @"Not found";
  self.modeErrors[displayIDString] = @"Requested mode not available";
  return NO;
}

- (void)applyDisplayOriginForDisplayID:(CGDirectDisplayID)displayID x:(int32_t)x y:(int32_t)y
{
  CGDisplayConfigRef config = NULL;
  CGError beginError = CGBeginDisplayConfiguration(&config);

  if (beginError != kCGErrorSuccess || config == NULL) {
    return;
  }

  CGError originError = CGConfigureDisplayOrigin(config, displayID, x, y);

  if (originError == kCGErrorSuccess) {
    CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
  } else {
    CGCancelDisplayConfiguration(config);
  }
}

- (NSDictionary *)currentPresetDisplayStates
{
  uint32_t displayCount = 0;
  CGError countError = CGGetActiveDisplayList(0, NULL, &displayCount);

  if (countError != kCGErrorSuccess || displayCount == 0) {
    return @{};
  }

  std::vector<CGDirectDisplayID> displayIDs(displayCount);
  CGError listError = CGGetActiveDisplayList(displayCount, displayIDs.data(), &displayCount);

  if (listError != kCGErrorSuccess) {
    return @{};
  }

  NSMutableDictionary<NSString *, NSDictionary *> *displayStates = [NSMutableDictionary new];

  for (uint32_t index = 0; index < displayCount; index++) {
    CGDirectDisplayID displayID = displayIDs[index];
    CGDisplayModeRef mode = CGDisplayCopyDisplayMode(displayID);
    CGRect frame = CGDisplayBounds(displayID);
    NSString *displayIDString = [NSString stringWithFormat:@"%u", displayID];

    displayStates[displayIDString] = @{
      @"identityKey" : [self identityKeyForDisplayID:displayID],
      @"modeID" : mode != NULL ? [self modeIDForMode:mode] : @"",
      @"colorProfileID" : [self currentColorProfileIDForDisplayID:displayID],
      @"frame" : @{
        @"x" : @(frame.origin.x),
        @"y" : @(frame.origin.y),
        @"width" : @(frame.size.width),
        @"height" : @(frame.size.height),
      },
      @"nativeBrightness" : @([self nativeBrightnessForDisplayID:displayID didRead:nil]),
      @"softwareDimming" : @([self dimmingLevelForDisplayIDString:displayIDString]),
      @"ddc" : [self ddcStateForDisplayIDString:displayIDString supportsDdc:[self displaySupportsDdc:displayID]],
    };

    if (mode != NULL) {
      CGDisplayModeRelease(mode);
    }
  }

  return displayStates;
}

- (NSDictionary *)currentLayoutState
{
  return [self currentLayoutStateForDisplayIDStrings:nil];
}

- (NSUInteger)protectedLayoutDriftCount
{
  if (self.protectedLayout.count == 0) {
    return 0;
  }

  NSDictionary *currentLayout = [self currentLayoutState];
  NSUInteger driftCount = 0;
  NSMutableSet<NSString *> *matchedCurrentDisplayIDs = [NSMutableSet new];

  for (NSString *storedDisplayID in self.protectedLayout) {
    NSDictionary *protectedFrame = self.protectedLayout[storedDisplayID];

    if (![protectedFrame isKindOfClass:NSDictionary.class]) {
      driftCount++;
      continue;
    }

    NSString *resolvedDisplayID = [self resolveDisplayIDString:storedDisplayID storedState:protectedFrame];
    NSDictionary *currentFrame = currentLayout[resolvedDisplayID];

    if (![currentFrame isKindOfClass:NSDictionary.class]) {
      driftCount++;
      continue;
    }

    [matchedCurrentDisplayIDs addObject:resolvedDisplayID];

    if ([self frameDictionary:protectedFrame differsFromFrameDictionary:currentFrame]) {
      driftCount++;
    }
  }

  for (NSString *displayID in currentLayout) {
    if (![matchedCurrentDisplayIDs containsObject:displayID]) {
      driftCount++;
    }
  }

  return driftCount;
}

- (BOOL)frameDictionary:(NSDictionary *)left differsFromFrameDictionary:(NSDictionary *)right
{
  NSArray<NSString *> *keys = @[ @"x", @"y", @"width", @"height" ];

  for (NSString *key in keys) {
    double leftValue = [left[key] doubleValue];
    double rightValue = [right[key] doubleValue];

    if (fabs(leftValue - rightValue) > 1) {
      return YES;
    }
  }

  return NO;
}

- (NSString *)identityKeyForDisplayID:(CGDirectDisplayID)displayID
{
  NSString *displayUUID = [self displayUUIDStringForDisplayID:displayID];

  if (displayUUID.length > 0) {
    return displayUUID;
  }

  return [self legacyIdentityKeyForDisplayID:displayID];
}

- (NSString *)legacyIdentityKeyForDisplayID:(CGDirectDisplayID)displayID
{
  return [NSString stringWithFormat:@"%u:%u:%u",
                                    CGDisplayVendorNumber(displayID),
                                    CGDisplayModelNumber(displayID),
                                    CGDisplaySerialNumber(displayID)];
}

- (NSString *)resolveDisplayIDString:(NSString *)displayID storedState:(NSDictionary *)storedState
{
  if ([self displayIDStringIsActive:displayID]) {
    return displayID;
  }

  NSString *identityKey = storedState[@"identityKey"];

  if (![identityKey isKindOfClass:NSString.class] || identityKey.length == 0) {
    return displayID;
  }

  NSString *matchedDisplayID = [self activeDisplayIDStringForIdentityKey:identityKey];
  return matchedDisplayID.length > 0 ? matchedDisplayID : displayID;
}

- (BOOL)displayIDStringIsActive:(NSString *)displayID
{
  uint32_t displayCount = 0;
  CGError countError = CGGetActiveDisplayList(0, NULL, &displayCount);

  if (countError != kCGErrorSuccess || displayCount == 0) {
    return NO;
  }

  std::vector<CGDirectDisplayID> displayIDs(displayCount);
  CGError listError = CGGetActiveDisplayList(displayCount, displayIDs.data(), &displayCount);

  if (listError != kCGErrorSuccess) {
    return NO;
  }

  CGDirectDisplayID requestedDisplayID = (CGDirectDisplayID)displayID.integerValue;

  for (uint32_t index = 0; index < displayCount; index++) {
    if (displayIDs[index] == requestedDisplayID) {
      return YES;
    }
  }

  return NO;
}

- (NSString *)activeDisplayIDStringForIdentityKey:(NSString *)identityKey
{
  uint32_t displayCount = 0;
  CGError countError = CGGetActiveDisplayList(0, NULL, &displayCount);

  if (countError != kCGErrorSuccess || displayCount == 0) {
    return @"";
  }

  std::vector<CGDirectDisplayID> displayIDs(displayCount);
  CGError listError = CGGetActiveDisplayList(displayCount, displayIDs.data(), &displayCount);

  if (listError != kCGErrorSuccess) {
    return @"";
  }

  for (uint32_t index = 0; index < displayCount; index++) {
    CGDirectDisplayID displayID = displayIDs[index];
    NSString *currentIdentityKey = [self identityKeyForDisplayID:displayID];
    NSString *legacyIdentityKey = [self legacyIdentityKeyForDisplayID:displayID];

    if ([currentIdentityKey isEqualToString:identityKey] || [legacyIdentityKey isEqualToString:identityKey]) {
      return [NSString stringWithFormat:@"%u", displayID];
    }
  }

  return @"";
}

- (NSDictionary *)currentLayoutStateForDisplayIDStrings:(NSArray<NSString *> *)displayIDStrings
{
  uint32_t displayCount = 0;
  CGError countError = CGGetActiveDisplayList(0, NULL, &displayCount);

  if (countError != kCGErrorSuccess || displayCount == 0) {
    return @{};
  }

  NSSet<NSString *> *allowedDisplayIDs =
      displayIDStrings != nil ? [NSSet setWithArray:displayIDStrings] : nil;
  std::vector<CGDirectDisplayID> displayIDs(displayCount);
  CGError listError = CGGetActiveDisplayList(displayCount, displayIDs.data(), &displayCount);

  if (listError != kCGErrorSuccess) {
    return @{};
  }

  NSMutableDictionary<NSString *, NSDictionary *> *layout = [NSMutableDictionary new];

  for (uint32_t index = 0; index < displayCount; index++) {
    CGDirectDisplayID displayID = displayIDs[index];
    NSString *displayIDString = [NSString stringWithFormat:@"%u", displayID];

    if (allowedDisplayIDs != nil && ![allowedDisplayIDs containsObject:displayIDString]) {
      continue;
    }

    CGRect frame = CGDisplayBounds(displayID);
    layout[displayIDString] = @{
      @"identityKey" : [self identityKeyForDisplayID:displayID],
      @"x" : @(frame.origin.x),
      @"y" : @(frame.origin.y),
      @"width" : @(frame.size.width),
      @"height" : @(frame.size.height),
    };
  }

  return layout;
}

- (void)restoreLayoutState:(NSDictionary *)layout
{
  if (![layout isKindOfClass:NSDictionary.class]) {
    return;
  }

  for (NSString *displayID in layout) {
    NSDictionary *frame = layout[displayID];

    if (![frame isKindOfClass:NSDictionary.class]) {
      continue;
    }

    NSString *resolvedDisplayID = [self resolveDisplayIDString:displayID storedState:frame];
    [self applyDisplayOriginForDisplayID:(CGDirectDisplayID)resolvedDisplayID.integerValue
                                       x:[frame[@"x"] intValue]
                                       y:[frame[@"y"] intValue]];
  }
}

- (void)applySyncGroupDictionary:(NSDictionary *)group
{
  NSArray<NSString *> *displayIDs = group[@"displayIDs"];

  if (![displayIDs isKindOfClass:NSArray.class] || displayIDs.count == 0) {
    return;
  }

  if ([group[@"layoutProtection"] boolValue]) {
    [self restoreLayoutState:group[@"layout"]];
  }

  NSString *sourceDisplayID = displayIDs.firstObject;

  if ([group[@"brightnessSync"] boolValue]) {
    double sourceDimmingLevel = [self dimmingLevelForDisplayIDString:sourceDisplayID];
    double sourceDdcBrightness = [self ddcValueForDisplayIDString:sourceDisplayID controlCode:0x10 fallback:50];
    NSDictionary *layout = group[@"layout"];
    NSDictionary *sourceState = [layout isKindOfClass:NSDictionary.class] ? layout[sourceDisplayID] : nil;
    NSString *resolvedSourceDisplayID =
        [self resolveDisplayIDString:sourceDisplayID storedState:sourceState ?: @{}];
    CGDirectDisplayID sourceDirectDisplayID = (CGDirectDisplayID)resolvedSourceDisplayID.integerValue;
    BOOL sourceSupportsNativeBrightness = [self displaySupportsNativeBrightness:sourceDirectDisplayID];
    double sourceNativeBrightness = sourceSupportsNativeBrightness
        ? [self nativeBrightnessForDisplayID:sourceDirectDisplayID didRead:nil]
        : MIN(MAX(sourceDdcBrightness / 100, 0), 1);

    for (NSString *displayID in displayIDs) {
      if ([displayID isEqualToString:sourceDisplayID]) {
        continue;
      }

      NSDictionary *targetState = [layout isKindOfClass:NSDictionary.class] ? layout[displayID] : nil;
      NSString *resolvedDisplayID = [self resolveDisplayIDString:displayID storedState:targetState ?: @{}];
      self.dimmingLevels[resolvedDisplayID] = @(sourceDimmingLevel);
      CGDirectDisplayID directDisplayID = (CGDirectDisplayID)resolvedDisplayID.integerValue;
      [self syncDimmingWindowForDisplayID:directDisplayID level:sourceDimmingLevel];

      if ([self displaySupportsNativeBrightness:directDisplayID]) {
        [self setNativeBrightnessForDisplayID:directDisplayID
                                        level:sourceNativeBrightness
                                 errorMessage:nil];
      } else {
        [self sendDdcSetVcpForDisplayID:directDisplayID
                             controlCode:0x10
                                   value:(uint16_t)sourceDdcBrightness
                            errorMessage:nil];
        self.ddcValues[[self ddcKeyForDisplayIDString:resolvedDisplayID controlCode:0x10]] = @(sourceDdcBrightness);
      }
    }
  }

  if ([group[@"scaleSync"] boolValue]) {
    NSDictionary *layout = group[@"layout"];
    NSDictionary *sourceState = [layout isKindOfClass:NSDictionary.class] ? layout[sourceDisplayID] : nil;
    NSString *resolvedSourceDisplayID =
        [self resolveDisplayIDString:sourceDisplayID storedState:sourceState ?: @{}];
    NSDictionary *sourceModeState = [self currentModeStateForDisplayID:(CGDirectDisplayID)resolvedSourceDisplayID.integerValue];

    for (NSString *displayID in displayIDs) {
      if ([displayID isEqualToString:sourceDisplayID]) {
        continue;
      }

      NSDictionary *targetState = [layout isKindOfClass:NSDictionary.class] ? layout[displayID] : nil;
      NSString *resolvedDisplayID = [self resolveDisplayIDString:displayID storedState:targetState ?: @{}];
      [self applyClosestModeForDisplayID:(CGDirectDisplayID)resolvedDisplayID.integerValue sourceModeState:sourceModeState];
    }
  }

  [[NSUserDefaults standardUserDefaults] setObject:self.dimmingLevels forKey:RCTDisplayDimmingDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.ddcValues forKey:RCTDisplayDdcDefaultsKey];
}

- (NSDictionary *)currentModeStateForDisplayID:(CGDirectDisplayID)displayID
{
  CGDisplayModeRef mode = CGDisplayCopyDisplayMode(displayID);

  if (mode == NULL) {
    return @{};
  }

  NSDictionary *state = @{
    @"width" : @(CGDisplayModeGetWidth(mode)),
    @"height" : @(CGDisplayModeGetHeight(mode)),
    @"refreshRate" : @(CGDisplayModeGetRefreshRate(mode)),
    @"isHiDpi" : @(CGDisplayModeGetPixelWidth(mode) > CGDisplayModeGetWidth(mode)),
  };

  CGDisplayModeRelease(mode);
  return state;
}

- (void)applyClosestModeForDisplayID:(CGDirectDisplayID)displayID sourceModeState:(NSDictionary *)sourceModeState
{
  NSDictionary *options = @{(__bridge NSString *)kCGDisplayShowDuplicateLowResolutionModes : @YES};
  CFArrayRef copiedModes = CGDisplayCopyAllDisplayModes(displayID, (__bridge CFDictionaryRef)options);

  if (copiedModes == NULL || sourceModeState.count == 0) {
    return;
  }

  NSArray *modes = CFBridgingRelease(copiedModes);
  CGDisplayModeRef fallbackMode = NULL;

  for (id item in modes) {
    CGDisplayModeRef candidate = (__bridge CGDisplayModeRef)item;
    BOOL sameSize = CGDisplayModeGetWidth(candidate) == [sourceModeState[@"width"] unsignedIntegerValue] &&
        CGDisplayModeGetHeight(candidate) == [sourceModeState[@"height"] unsignedIntegerValue];
    BOOL sameRefresh =
        llround(CGDisplayModeGetRefreshRate(candidate)) == llround([sourceModeState[@"refreshRate"] doubleValue]);
    BOOL sameHiDpi =
        (CGDisplayModeGetPixelWidth(candidate) > CGDisplayModeGetWidth(candidate)) ==
        [sourceModeState[@"isHiDpi"] boolValue];

    if (sameSize && fallbackMode == NULL) {
      fallbackMode = candidate;
    }

    if (sameSize && sameRefresh && sameHiDpi) {
      CGDisplaySetDisplayMode(displayID, candidate, NULL);
      return;
    }
  }

  if (fallbackMode != NULL) {
    CGDisplaySetDisplayMode(displayID, fallbackMode, NULL);
  }
}

- (void)syncSoftwareDimmingFromDisplayIDString:(NSString *)sourceDisplayID level:(double)level
{
  for (NSDictionary *group in self.syncGroups.allValues) {
    if (![group[@"brightnessSync"] boolValue]) {
      continue;
    }

    NSArray<NSString *> *displayIDs = group[@"displayIDs"];

    if (![displayIDs containsObject:sourceDisplayID]) {
      continue;
    }

    for (NSString *displayID in displayIDs) {
      if ([displayID isEqualToString:sourceDisplayID]) {
        continue;
      }

      self.dimmingLevels[displayID] = @(level);
      [self syncDimmingWindowForDisplayID:(CGDirectDisplayID)displayID.integerValue level:level];
    }
  }

  [[NSUserDefaults standardUserDefaults] setObject:self.dimmingLevels forKey:RCTDisplayDimmingDefaultsKey];
}

- (void)syncDdcBrightnessFromDisplayIDString:(NSString *)sourceDisplayID value:(uint16_t)value
{
  for (NSDictionary *group in self.syncGroups.allValues) {
    if (![group[@"brightnessSync"] boolValue]) {
      continue;
    }

    NSArray<NSString *> *displayIDs = group[@"displayIDs"];

    if (![displayIDs containsObject:sourceDisplayID]) {
      continue;
    }

    for (NSString *displayID in displayIDs) {
      if ([displayID isEqualToString:sourceDisplayID]) {
        continue;
      }

      CGDirectDisplayID directDisplayID = (CGDirectDisplayID)displayID.integerValue;

      if ([self displaySupportsNativeBrightness:directDisplayID]) {
        [self setNativeBrightnessForDisplayID:directDisplayID level:(double)value / 100 errorMessage:nil];
      } else {
        BOOL didSend = [self sendDdcSetVcpForDisplayID:directDisplayID
                                           controlCode:0x10
                                                 value:value
                                          errorMessage:nil];

        if (!didSend) {
          continue;
        }

        self.ddcValues[[self ddcKeyForDisplayIDString:displayID controlCode:0x10]] = @(value);
      }
    }
  }

  [[NSUserDefaults standardUserDefaults] setObject:self.ddcValues forKey:RCTDisplayDdcDefaultsKey];
}

- (void)syncNativeBrightnessFromDisplayIDString:(NSString *)sourceDisplayID level:(double)level
{
  for (NSDictionary *group in self.syncGroups.allValues) {
    if (![group[@"brightnessSync"] boolValue]) {
      continue;
    }

    NSArray<NSString *> *displayIDs = group[@"displayIDs"];

    if (![displayIDs containsObject:sourceDisplayID]) {
      continue;
    }

    for (NSString *displayID in displayIDs) {
      if ([displayID isEqualToString:sourceDisplayID]) {
        continue;
      }

      CGDirectDisplayID directDisplayID = (CGDirectDisplayID)displayID.integerValue;

      if ([self displaySupportsNativeBrightness:directDisplayID]) {
        [self setNativeBrightnessForDisplayID:directDisplayID level:level errorMessage:nil];
      } else {
        uint16_t ddcValue = (uint16_t)MIN(MAX(level * 100, 0), 100);
        BOOL didSend = [self sendDdcSetVcpForDisplayID:directDisplayID
                                           controlCode:0x10
                                                 value:ddcValue
                                          errorMessage:nil];

        if (didSend) {
          self.ddcValues[[self ddcKeyForDisplayIDString:displayID controlCode:0x10]] = @(ddcValue);
        }
      }
    }
  }

  [[NSUserDefaults standardUserDefaults] setObject:self.ddcValues forKey:RCTDisplayDdcDefaultsKey];
}

- (void)applyDdcPresetState:(NSDictionary *)ddc displayIDString:(NSString *)displayIDString displayID:(CGDirectDisplayID)displayID
{
  NSDictionary<NSString *, NSNumber *> *controlCodes = @{
    @"brightness" : @(0x10),
    @"contrast" : @(0x12),
    @"volume" : @(0x62),
    @"inputSource" : @(0x60),
  };

  for (NSString *key in controlCodes) {
    NSNumber *value = ddc[key];

    if (![value isKindOfClass:NSNumber.class]) {
      continue;
    }

    uint8_t controlCode = controlCodes[key].unsignedCharValue;
    uint16_t controlValue = (uint16_t)MIN(MAX(value.doubleValue, 0), 65535);
    BOOL didSend = [self sendDdcSetVcpForDisplayID:displayID
                                       controlCode:controlCode
                                             value:controlValue
                                      errorMessage:nil];

    if (didSend) {
      self.ddcValues[[self ddcKeyForDisplayIDString:displayIDString controlCode:controlCode]] = @(controlValue);
    }
  }
}

- (BOOL)applyColorProfileForDisplayID:(CGDirectDisplayID)displayID
                             profileID:(NSString *)profileID
                       displayIDString:(NSString *)displayIDString
{
  NSString *statusKey = displayIDString.length > 0 ? displayIDString : [NSString stringWithFormat:@"%u", displayID];

  if (profileID.length == 0) {
    self.colorProfileStatus[statusKey] = @"Failed";
    self.colorProfileErrors[statusKey] = @"Color profile ID is empty";
    return NO;
  }

  CFUUIDRef displayUUID = CGDisplayCreateUUIDFromDisplayID(displayID);

  if (displayUUID == NULL) {
    self.colorProfileStatus[statusKey] = @"Unavailable";
    self.colorProfileErrors[statusKey] = @"Display UUID is unavailable";
    return NO;
  }

  id profileValue = (__bridge id)kCFNull;

  if (![profileID isEqualToString:RCTFactoryColorProfileID]) {
    profileValue = [self colorProfileURLForDisplayID:displayID profileID:profileID];
  }

  if (profileValue == nil) {
    CFRelease(displayUUID);
    self.colorProfileStatus[statusKey] = @"Failed";
    self.colorProfileErrors[statusKey] = @"Color profile URL not found";
    return NO;
  }

  NSDictionary *profileInfo = @{
    (__bridge NSString *)kColorSyncDeviceDefaultProfileID : profileValue,
  };

  BOOL didApply = ColorSyncDeviceSetCustomProfiles(
      kColorSyncDisplayDeviceClass, displayUUID, (__bridge CFDictionaryRef)profileInfo);
  CFRelease(displayUUID);

  if (didApply) {
    self.colorProfileStatus[statusKey] = [profileID isEqualToString:RCTFactoryColorProfileID] ? @"Reset" : @"Applied";
    [self.colorProfileErrors removeObjectForKey:statusKey];
  } else {
    self.colorProfileStatus[statusKey] = @"Failed";
    self.colorProfileErrors[statusKey] = @"ColorSync rejected profile change";
  }

  return didApply;
}

- (NSURL *)colorProfileURLForDisplayID:(CGDirectDisplayID)displayID profileID:(NSString *)profileID
{
  NSArray<NSDictionary *> *profiles = [self colorProfilesForDisplayID:displayID];

  for (NSDictionary *profile in profiles) {
    if (![profile[@"id"] isEqualToString:profileID]) {
      continue;
    }

    NSString *path = profile[@"path"];

    if (path.length == 0) {
      return nil;
    }

    return [NSURL fileURLWithPath:path];
  }

  return nil;
}

- (NSString *)currentColorProfileIDForDisplayID:(CGDirectDisplayID)displayID
{
  NSArray<NSDictionary *> *profiles = [self colorProfilesForDisplayID:displayID];

  for (NSDictionary *profile in profiles) {
    NSNumber *isCurrent = profile[@"isCurrent"];

    if (isCurrent.boolValue) {
      return profile[@"id"] ?: @"";
    }
  }

  return @"";
}

- (NSArray<NSDictionary *> *)presetSummaries
{
  NSMutableArray<NSDictionary *> *summaries = [NSMutableArray arrayWithCapacity:self.displayPresets.count];

  for (NSString *name in self.displayPresets) {
    NSDictionary *preset = self.displayPresets[name];
    NSDictionary *displays = preset[@"displays"];

    [summaries addObject:@{
      @"name" : preset[@"name"] ?: name,
      @"createdAt" : preset[@"createdAt"] ?: @"",
      @"displayCount" : @([displays isKindOfClass:NSDictionary.class] ? displays.count : 0),
    }];
  }

  [summaries sortUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
    NSString *leftDate = left[@"createdAt"];
    NSString *rightDate = right[@"createdAt"];
    return [rightDate compare:leftDate];
  }];

  return summaries;
}

- (NSArray<NSDictionary *> *)syncGroupSummaries
{
  NSMutableArray<NSDictionary *> *summaries = [NSMutableArray arrayWithCapacity:self.syncGroups.count];

  for (NSString *groupID in self.syncGroups) {
    NSDictionary *group = self.syncGroups[groupID];
    NSArray *displayIDs = group[@"displayIDs"];

    [summaries addObject:@{
      @"id" : group[@"id"] ?: groupID,
      @"name" : group[@"name"] ?: groupID,
      @"displayIDs" : [displayIDs isKindOfClass:NSArray.class] ? displayIDs : @[],
      @"brightnessSync" : @([group[@"brightnessSync"] boolValue]),
      @"scaleSync" : @([group[@"scaleSync"] boolValue]),
      @"layoutProtection" : @([group[@"layoutProtection"] boolValue]),
    }];
  }

  [summaries sortUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
    return [left[@"name"] compare:right[@"name"]];
  }];

  return summaries;
}

- (NSString *)normalizedPresetName:(NSString *)name
{
  NSString *trimmedName = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

  if (trimmedName.length > 0) {
    return trimmedName;
  }

  return [NSString stringWithFormat:@"Preset %lu", (unsigned long)self.displayPresets.count + 1];
}

- (NSString *)normalizedSyncGroupName:(NSString *)name
{
  NSString *trimmedName = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

  if (trimmedName.length > 0) {
    return trimmedName;
  }

  return [NSString stringWithFormat:@"Group %lu", (unsigned long)self.syncGroups.count + 1];
}

- (double)dimmingLevelForDisplayIDString:(NSString *)displayID
{
  NSNumber *level = self.dimmingLevels[displayID];

  if (level == nil) {
    return 0;
  }

  return MIN(MAX(level.doubleValue, 0), 0.8);
}

- (NSDictionary *)ddcStateForDisplayIDString:(NSString *)displayID supportsDdc:(BOOL)supportsDdc
{
  if (!supportsDdc) {
    self.ddcReadStatus[displayID] = @"Unavailable";
  } else if (self.ddcReadStatus[displayID] == nil) {
    self.ddcReadStatus[displayID] = @"Cached";
  }

  return @{
    @"brightness" : @([self ddcValueForDisplayIDString:displayID controlCode:0x10 fallback:50]),
    @"contrast" : @([self ddcValueForDisplayIDString:displayID controlCode:0x12 fallback:50]),
    @"volume" : @([self ddcValueForDisplayIDString:displayID controlCode:0x62 fallback:20]),
    @"inputSource" : @([self ddcValueForDisplayIDString:displayID controlCode:0x60 fallback:15]),
    @"readStatus" : self.ddcReadStatus[displayID] ?: @"Cached",
    @"lastError" : self.ddcErrors[displayID] ?: @"",
  };
}

- (void)refreshDdcValuesForActiveDisplays
{
  uint32_t displayCount = 0;
  CGError countError = CGGetActiveDisplayList(0, NULL, &displayCount);

  if (countError != kCGErrorSuccess || displayCount == 0) {
    return;
  }

  std::vector<CGDirectDisplayID> displayIDs(displayCount);
  CGError listError = CGGetActiveDisplayList(displayCount, displayIDs.data(), &displayCount);

  if (listError != kCGErrorSuccess) {
    return;
  }

  for (uint32_t index = 0; index < displayCount; index++) {
    CGDirectDisplayID displayID = displayIDs[index];

    if (![self displaySupportsDdc:displayID]) {
      continue;
    }

    [self refreshDdcValuesForDisplayID:displayID
                       displayIDString:[NSString stringWithFormat:@"%u", displayID]];
  }
}

- (void)refreshDdcValuesForDisplayID:(CGDirectDisplayID)displayID displayIDString:(NSString *)displayIDString
{
  NSArray<NSNumber *> *controlCodes = @[ @(0x10), @(0x12), @(0x62), @(0x60) ];
  BOOL didReadAny = NO;
  NSString *lastError = nil;

  for (NSNumber *controlCodeNumber in controlCodes) {
    uint8_t controlCode = controlCodeNumber.unsignedCharValue;
    uint16_t currentValue = 0;
    uint16_t maximumValue = 0;
    NSString *errorMessage = nil;
    BOOL didRead = [self readDdcVcpForDisplayID:displayID
                                    controlCode:controlCode
                                   currentValue:&currentValue
                                   maximumValue:&maximumValue
                                   errorMessage:&errorMessage];

    if (didRead) {
      didReadAny = YES;
      self.ddcValues[[self ddcKeyForDisplayIDString:displayIDString controlCode:controlCode]] = @(currentValue);
    } else if (errorMessage.length > 0) {
      lastError = errorMessage;
    }
  }

  if (didReadAny) {
    self.ddcReadStatus[displayIDString] = @"Live";
    [self.ddcErrors removeObjectForKey:displayIDString];
    [[NSUserDefaults standardUserDefaults] setObject:self.ddcValues forKey:RCTDisplayDdcDefaultsKey];
  } else {
    self.ddcReadStatus[displayIDString] = @"Cached";

    if (lastError.length > 0) {
      self.ddcErrors[displayIDString] = lastError;
    }
  }
}

- (double)ddcValueForDisplayIDString:(NSString *)displayID controlCode:(uint8_t)controlCode fallback:(double)fallback
{
  NSNumber *value = self.ddcValues[[self ddcKeyForDisplayIDString:displayID controlCode:controlCode]];

  if (value == nil) {
    return fallback;
  }

  return value.doubleValue;
}

- (NSString *)ddcKeyForDisplayIDString:(NSString *)displayID controlCode:(uint8_t)controlCode
{
  return [NSString stringWithFormat:@"%@-%u", displayID, controlCode];
}

- (BOOL)displaySupportsNativeBrightness:(CGDirectDisplayID)displayID
{
  BOOL didRead = NO;
  [self nativeBrightnessForDisplayID:displayID didRead:&didRead];

  return didRead;
}

- (double)nativeBrightnessForDisplayID:(CGDirectDisplayID)displayID didRead:(BOOL *)didRead
{
  io_service_t framebuffer = [self framebufferServiceForDisplayID:displayID];

  if (framebuffer == MACH_PORT_NULL) {
    if (didRead != nil) {
      *didRead = NO;
    }

    return 0;
  }

  float brightness = 0;
  IOReturn result = IODisplayGetFloatParameter(framebuffer, kNilOptions, CFSTR(kIODisplayBrightnessKey), &brightness);

  if (didRead != nil) {
    *didRead = result == kIOReturnSuccess;
  }

  if (result != kIOReturnSuccess) {
    return 0;
  }

  return MIN(MAX(brightness, 0), 1);
}

- (BOOL)setNativeBrightnessForDisplayID:(CGDirectDisplayID)displayID
                                  level:(double)level
                           errorMessage:(NSString **)errorMessage
{
  io_service_t framebuffer = [self framebufferServiceForDisplayID:displayID];

  if (framebuffer == MACH_PORT_NULL) {
    if (errorMessage != nil) {
      *errorMessage = @"Display framebuffer not found";
    }

    return NO;
  }

  float brightness = (float)MIN(MAX(level, 0), 1);
  IOReturn result = IODisplaySetFloatParameter(framebuffer, kNilOptions, CFSTR(kIODisplayBrightnessKey), brightness);

  if (result != kIOReturnSuccess) {
    if (errorMessage != nil) {
      *errorMessage = [NSString stringWithFormat:@"Native brightness failed: 0x%08x", result];
    }

    return NO;
  }

  return YES;
}

- (BOOL)displaySupportsDdc:(CGDirectDisplayID)displayID
{
  if (CGDisplayIsBuiltin(displayID)) {
    return NO;
  }

  io_service_t framebuffer = [self framebufferServiceForDisplayID:displayID];

  if (framebuffer == MACH_PORT_NULL) {
    return NO;
  }

  IOItemCount busCount = 0;
  IOReturn countResult = IOFBGetI2CInterfaceCount(framebuffer, &busCount);

  if (countResult != kIOReturnSuccess || busCount == 0) {
    return NO;
  }

  for (IOOptionBits bus = 0; bus < busCount; bus++) {
    io_service_t interface = MACH_PORT_NULL;
    IOReturn copyResult = IOFBCopyI2CInterfaceForBus(framebuffer, bus, &interface);

    if (copyResult != kIOReturnSuccess || interface == MACH_PORT_NULL) {
      continue;
    }

    IOI2CConnectRef connect = NULL;
    IOReturn openResult = IOI2CInterfaceOpen(interface, kNilOptions, &connect);

    if (openResult == kIOReturnSuccess && connect != NULL) {
      IOI2CInterfaceClose(connect, kNilOptions);
      IOObjectRelease(interface);
      return YES;
    }

    IOObjectRelease(interface);
  }

  return NO;
}

- (BOOL)readDdcVcpForDisplayID:(CGDirectDisplayID)displayID
                    controlCode:(uint8_t)controlCode
                   currentValue:(uint16_t *)currentValue
                   maximumValue:(uint16_t *)maximumValue
                   errorMessage:(NSString **)errorMessage
{
  if (CGDisplayIsBuiltin(displayID)) {
    if (errorMessage != nil) {
      *errorMessage = @"Built-in display does not expose DDC";
    }

    return NO;
  }

  io_service_t framebuffer = [self framebufferServiceForDisplayID:displayID];

  if (framebuffer == MACH_PORT_NULL) {
    if (errorMessage != nil) {
      *errorMessage = @"Display framebuffer not found";
    }

    return NO;
  }

  IOItemCount busCount = 0;
  IOReturn countResult = IOFBGetI2CInterfaceCount(framebuffer, &busCount);

  if (countResult != kIOReturnSuccess || busCount == 0) {
    if (errorMessage != nil) {
      *errorMessage = @"No DDC I2C bus found";
    }

    return NO;
  }

  NSString *lastError = @"DDC read failed";

  for (IOOptionBits bus = 0; bus < busCount; bus++) {
    io_service_t interface = MACH_PORT_NULL;
    IOReturn copyResult = IOFBCopyI2CInterfaceForBus(framebuffer, bus, &interface);

    if (copyResult != kIOReturnSuccess || interface == MACH_PORT_NULL) {
      lastError = [NSString stringWithFormat:@"I2C bus %u unavailable", bus];
      continue;
    }

    IOI2CConnectRef connect = NULL;
    IOReturn openResult = IOI2CInterfaceOpen(interface, kNilOptions, &connect);

    if (openResult != kIOReturnSuccess || connect == NULL) {
      lastError = [NSString stringWithFormat:@"I2C bus %u open failed", bus];
      IOObjectRelease(interface);
      continue;
    }

    uint8_t packet[5] = {
        RCTDdcHostAddress,
        0x82,
        RCTDdcGetVcpFeatureCommand,
        controlCode,
        0,
    };
    uint8_t checksum = RCTDdcDestinationAddress;

    for (NSUInteger index = 0; index < sizeof(packet) - 1; index++) {
      checksum ^= packet[index];
    }

    packet[sizeof(packet) - 1] = checksum;

    uint8_t reply[16] = {};
    IOI2CRequest request = {};
    request.sendAddress = RCTDdcDestinationAddress;
    request.sendTransactionType = kIOI2CSimpleTransactionType;
    request.sendBuffer = (vm_address_t)packet;
    request.sendBytes = sizeof(packet);
    request.replyAddress = RCTDdcReplyAddress;
    request.replyTransactionType = kIOI2CDDCciReplyTransactionType;
    request.replyBuffer = (vm_address_t)reply;
    request.replyBytes = sizeof(reply);

    IOReturn sendResult = IOI2CSendRequest(connect, kNilOptions, &request);
    IOI2CInterfaceClose(connect, kNilOptions);
    IOObjectRelease(interface);

    if (sendResult == kIOReturnSuccess && request.result == kIOReturnSuccess &&
        [self parseDdcVcpReply:reply
                        length:request.replyBytes
                   controlCode:controlCode
                  currentValue:currentValue
                  maximumValue:maximumValue]) {
      return YES;
    }

    lastError = [NSString stringWithFormat:@"DDC read failed on bus %u", bus];
  }

  if (errorMessage != nil) {
    *errorMessage = lastError;
  }

  return NO;
}

- (BOOL)parseDdcVcpReply:(uint8_t *)reply
                  length:(uint32_t)length
             controlCode:(uint8_t)controlCode
            currentValue:(uint16_t *)currentValue
            maximumValue:(uint16_t *)maximumValue
{
  if (reply == NULL || length < 8) {
    return NO;
  }

  for (uint32_t index = 0; index + 7 < length; index++) {
    BOOL isVcpReply = reply[index] == 0x02;
    BOOL resultOk = reply[index + 1] == 0x00;
    BOOL controlMatches = reply[index + 2] == controlCode;

    if (!isVcpReply || !resultOk || !controlMatches) {
      continue;
    }

    if (maximumValue != nil) {
      *maximumValue = ((uint16_t)reply[index + 4] << 8) | reply[index + 5];
    }

    if (currentValue != nil) {
      *currentValue = ((uint16_t)reply[index + 6] << 8) | reply[index + 7];
    }

    return YES;
  }

  return NO;
}

- (BOOL)sendDdcSetVcpForDisplayID:(CGDirectDisplayID)displayID
                       controlCode:(uint8_t)controlCode
                             value:(uint16_t)value
                      errorMessage:(NSString **)errorMessage
{
  if (CGDisplayIsBuiltin(displayID)) {
    if (errorMessage != nil) {
      *errorMessage = @"Built-in display does not expose DDC";
    }

    return NO;
  }

  io_service_t framebuffer = [self framebufferServiceForDisplayID:displayID];

  if (framebuffer == MACH_PORT_NULL) {
    if (errorMessage != nil) {
      *errorMessage = @"Display framebuffer not found";
    }

    return NO;
  }

  IOItemCount busCount = 0;
  IOReturn countResult = IOFBGetI2CInterfaceCount(framebuffer, &busCount);

  if (countResult != kIOReturnSuccess || busCount == 0) {
    if (errorMessage != nil) {
      *errorMessage = @"No DDC I2C bus found";
    }

    return NO;
  }

  NSString *lastError = @"DDC command failed";

  for (IOOptionBits bus = 0; bus < busCount; bus++) {
    io_service_t interface = MACH_PORT_NULL;
    IOReturn copyResult = IOFBCopyI2CInterfaceForBus(framebuffer, bus, &interface);

    if (copyResult != kIOReturnSuccess || interface == MACH_PORT_NULL) {
      lastError = [NSString stringWithFormat:@"I2C bus %u unavailable", bus];
      continue;
    }

    IOI2CConnectRef connect = NULL;
    IOReturn openResult = IOI2CInterfaceOpen(interface, kNilOptions, &connect);

    if (openResult != kIOReturnSuccess || connect == NULL) {
      lastError = [NSString stringWithFormat:@"I2C bus %u open failed", bus];
      IOObjectRelease(interface);
      continue;
    }

    uint8_t packet[7] = {
        RCTDdcHostAddress,
        0x84,
        RCTDdcSetVcpControlCommand,
        controlCode,
        (uint8_t)(value >> 8),
        (uint8_t)(value & 0xFF),
        0,
    };
    uint8_t checksum = RCTDdcDestinationAddress;

    for (NSUInteger index = 0; index < sizeof(packet) - 1; index++) {
      checksum ^= packet[index];
    }

    packet[sizeof(packet) - 1] = checksum;

    IOI2CRequest request = {};
    request.sendAddress = RCTDdcDestinationAddress;
    request.sendTransactionType = kIOI2CSimpleTransactionType;
    request.sendBuffer = (vm_address_t)packet;
    request.sendBytes = sizeof(packet);
    request.replyTransactionType = kIOI2CNoTransactionType;

    IOReturn sendResult = IOI2CSendRequest(connect, kNilOptions, &request);
    IOI2CInterfaceClose(connect, kNilOptions);
    IOObjectRelease(interface);

    if (sendResult == kIOReturnSuccess && request.result == kIOReturnSuccess) {
      return YES;
    }

    lastError = [NSString stringWithFormat:@"DDC send failed on bus %u", bus];
  }

  if (errorMessage != nil) {
    *errorMessage = lastError;
  }

  return NO;
}

- (io_service_t)framebufferServiceForDisplayID:(CGDirectDisplayID)displayID
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  return CGDisplayIOServicePort(displayID);
#pragma clang diagnostic pop
}

- (void)syncXdrUpscaleWindowForDisplayID:(CGDirectDisplayID)displayID enabled:(BOOL)enabled
{
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self syncXdrUpscaleWindowForDisplayID:displayID enabled:enabled];
    });
    return;
  }

  NSString *displayIDString = [NSString stringWithFormat:@"%u", displayID];
  NSWindow *window = self.xdrUpscaleWindows[displayIDString];

  if (!enabled) {
    [window orderOut:nil];
    [self.xdrUpscaleWindows removeObjectForKey:displayIDString];
    return;
  }

  NSScreen *screen = [self screenForDisplayID:displayID];

  if (screen == nil) {
    [window orderOut:nil];
    [self.xdrUpscaleWindows removeObjectForKey:displayIDString];
    return;
  }

  if (window == nil) {
    window = [[NSWindow alloc] initWithContentRect:screen.frame
                                        styleMask:NSWindowStyleMaskBorderless
                                          backing:NSBackingStoreBuffered
                                            defer:NO
                                           screen:screen];
    window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
        NSWindowCollectionBehaviorFullScreenAuxiliary |
        NSWindowCollectionBehaviorStationary |
        NSWindowCollectionBehaviorIgnoresCycle;
    window.ignoresMouseEvents = YES;
    window.level = NSFloatingWindowLevel;
    window.opaque = NO;
    window.releasedWhenClosed = NO;
    window.backgroundColor = NSColor.clearColor;
    window.contentView = [NSView new];
    self.xdrUpscaleWindows[displayIDString] = window;
  }

  CGFloat potentialHeadroom = MAX(screen.maximumPotentialExtendedDynamicRangeColorComponentValue, 1);
  CGFloat boostComponent = MIN(potentialHeadroom, 2);
  CGFloat components[] = {boostComponent, boostComponent, boostComponent, 0.16};
  NSColor *boostColor = [NSColor colorWithColorSpace:[NSColorSpace extendedSRGBColorSpace]
                                         components:components
                                              count:4];

  [window setFrame:screen.frame display:YES];
  window.contentView.wantsLayer = YES;
  window.contentView.layer.backgroundColor =
      (boostColor ?: [NSColor colorWithCalibratedWhite:1 alpha:0.16]).CGColor;
  [window orderFrontRegardless];
}

- (void)syncDimmingWindowForDisplayID:(CGDirectDisplayID)displayID level:(double)level
{
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self syncDimmingWindowForDisplayID:displayID level:level];
    });
    return;
  }

  NSString *displayIDString = [NSString stringWithFormat:@"%u", displayID];
  NSWindow *window = self.dimmingWindows[displayIDString];

  if (level <= 0) {
    [window orderOut:nil];
    [self.dimmingWindows removeObjectForKey:displayIDString];
    return;
  }

  NSScreen *screen = [self screenForDisplayID:displayID];

  if (screen == nil) {
    [window orderOut:nil];
    [self.dimmingWindows removeObjectForKey:displayIDString];
    return;
  }

  if (window == nil) {
    window = [[NSWindow alloc] initWithContentRect:screen.frame
                                        styleMask:NSWindowStyleMaskBorderless
                                          backing:NSBackingStoreBuffered
                                            defer:NO
                                           screen:screen];
    window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
        NSWindowCollectionBehaviorFullScreenAuxiliary |
        NSWindowCollectionBehaviorStationary |
        NSWindowCollectionBehaviorIgnoresCycle;
    window.ignoresMouseEvents = YES;
    window.level = NSFloatingWindowLevel;
    window.opaque = NO;
    window.releasedWhenClosed = NO;
    window.backgroundColor = NSColor.clearColor;
    window.contentView = [NSView new];
    self.dimmingWindows[displayIDString] = window;
  }

  [window setFrame:screen.frame display:YES];
  window.contentView.wantsLayer = YES;
  window.contentView.layer.backgroundColor =
      [NSColor colorWithCalibratedWhite:0 alpha:level].CGColor;
  [window orderFrontRegardless];
}

@end
