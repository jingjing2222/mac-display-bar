#import "RCTDisplayCore.h"

#import <AppKit/AppKit.h>
#import <ColorSync/ColorSync.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreImage/CoreImage.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#import <IOKit/IOKitLib.h>
#import <dispatch/dispatch.h>

#import "Utils/FileHashUtils.h"
#import "Utils/KeyUtils.h"
#import "Utils/NumberUtils.h"
#import "Utils/ScaleResolutionUtils.h"
#import "Utils/StringUtils.h"
#import "Utils/SystemUtils.h"

extern "C" {
#import <IOKit/i2c/IOI2CInterface.h>
}

#include <vector>
#include <dlfcn.h>
#include <math.h>
#include <objc/message.h>
#include <sys/utsname.h>

#ifndef RCTDISPLAY_ENABLE_PRIVATE_CGS_MODES
#define RCTDISPLAY_ENABLE_PRIVATE_CGS_MODES 1
#endif

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
static NSString *const RCTDisplayOverrideInstalledPathsDefaultsKey = @"displayOverrideInstalledPaths";
static NSString *const RCTDisplayOverrideBackupPathsDefaultsKey = @"displayOverrideBackupPaths";
static NSString *const RCTDisplayOverrideInstalledHashesDefaultsKey = @"displayOverrideInstalledHashes";
static NSString *const RCTDisplayOverrideBackupHashesDefaultsKey = @"displayOverrideBackupHashes";
static NSString *const RCTDisplayOverridePendingRebootDefaultsKey = @"displayOverridePendingReboot";
static NSString *const RCTDisplayOverridePendingReinitializeDefaultsKey = @"displayOverridePendingReinitialize";
static NSString *const RCTDisplayOverrideLastErrorsDefaultsKey = @"displayOverrideLastErrors";
static NSString *const RCTDisplayOverrideInstallTimesDefaultsKey = @"displayOverrideInstallTimes";
static NSString *const RCTDisplayNativePanelResolutionOverridesDefaultsKey = @"displayNativePanelResolutionOverrides";
static NSString *const RCTDisplayFlexibleScalingDefaultsKey = @"displayFlexibleScaling";
static NSString *const RCTDisplayVirtualDisplaysDefaultsKey = @"displayVirtualDisplays";
static NSString *const RCTDisplayPipWindowsDefaultsKey = @"displayPipWindows";
static NSString *const RCTDisplaySettingsDefaultsKey = @"displaySettings";
static NSString *const RCTGeneratedHiDpiModeIDPrefix = @"generated-hidpi";
static NSString *const RCTPrivateDisplayModeIDPrefix = @"cgs";
static NSString *const RCTDisplayOverrideInstallDirectory =
    @"/Library/Displays/Contents/Resources/Overrides";
static NSString *const RCTDisplayPrivilegedInstallWillBeginNotification =
    @"RCTDisplayPrivilegedInstallWillBeginNotification";
static NSString *const RCTDisplayPrivilegedInstallDidEndNotification =
    @"RCTDisplayPrivilegedInstallDidEndNotification";
static const NSUInteger RCTDisplay4KWidth = 3840;
static const NSUInteger RCTDisplay4KHeight = 2160;
static const int RCTCGSMaxDisplayModeCount = 1024;
static const uint8_t RCTDdcDestinationAddress = 0x6E;
static const uint8_t RCTDdcReplyAddress = 0x6F;
static const uint8_t RCTDdcHostAddress = 0x51;
static const uint8_t RCTDdcGetVcpFeatureCommand = 0x01;
static const uint8_t RCTDdcSetVcpControlCommand = 0x03;
static const unsigned int RCTVirtualDisplayVendorID = 0x4d42;
static const unsigned int RCTVirtualDisplayProductID = 0x5644;
static const unsigned int RCTVirtualDisplayPixelsPerInch = 220;
static NSString *const RCTFactoryColorProfileID = @"__factory__";

typedef struct {
  CFUUIDRef displayUUID;
  NSMutableArray<NSDictionary *> *__unsafe_unretained profiles;
} RCTColorProfileContext;

typedef struct {
  uint32_t modeNumber;
  uint32_t flags;
  uint32_t width;
  uint32_t height;
  uint32_t depth;
  uint8_t unknown[170];
  uint16_t freq;
  uint8_t moreUnknown[16];
  float density;
} RCTCGSDisplayMode;

typedef void (*RCTCGSGetCurrentDisplayModeFn)(CGDirectDisplayID display, int *modeNumber);
typedef CGError (*RCTCGSConfigureDisplayModeFn)(CGDisplayConfigRef config,
                                                CGDirectDisplayID display,
                                                int modeNumber);
typedef void (*RCTCGSGetNumberOfDisplayModesFn)(CGDirectDisplayID display, int *modeCount);
typedef void (*RCTCGSGetDisplayModeDescriptionOfLengthFn)(CGDirectDisplayID display,
                                                          int index,
                                                          RCTCGSDisplayMode *mode,
                                                          int length);

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

static id RCTObjCAllocInit(Class cls)
{
  if (cls == Nil) {
    return nil;
  }

  id allocated = ((id (*)(Class, SEL))objc_msgSend)(cls, @selector(alloc));
  return ((id (*)(id, SEL))objc_msgSend)(allocated, @selector(init));
}

static SEL RCTDisplayPrivateSelector(NSString *selectorName)
{
  return NSSelectorFromString(selectorName);
}

static void RCTObjCSetUnsignedInt(id object, SEL selector, unsigned int value)
{
  if (object != nil && [object respondsToSelector:selector]) {
    ((void (*)(id, SEL, unsigned int))objc_msgSend)(object, selector, value);
  }
}

static void RCTObjCSetObject(id object, SEL selector, id value)
{
  if (object != nil && [object respondsToSelector:selector]) {
    ((void (*)(id, SEL, id))objc_msgSend)(object, selector, value);
  }
}

static void RCTObjCSetCGSize(id object, SEL selector, CGSize value)
{
  if (object != nil && [object respondsToSelector:selector]) {
    ((void (*)(id, SEL, CGSize))objc_msgSend)(object, selector, value);
  }
}

static void RCTObjCSetCGPoint(id object, SEL selector, CGPoint value)
{
  if (object != nil && [object respondsToSelector:selector]) {
    ((void (*)(id, SEL, CGPoint))objc_msgSend)(object, selector, value);
  }
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
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *overrideInstalledPaths;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *overrideBackupPaths;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *overrideInstalledHashes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *overrideBackupHashes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *overridePendingReboot;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *overridePendingReinitialize;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *overrideLastErrors;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *overrideInstallTimes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *nativePanelResolutionOverrides;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *flexibleScalingEnabled;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *virtualDisplayRecords;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *virtualDisplays;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *virtualDisplayActivationAttempts;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *pipWindowRecords;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSWindow *> *pipWindows;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSTimer *> *pipCaptureTimers;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSImageView *> *pipImageViews;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *pipCloseObservers;
@property (nonatomic, strong) CIContext *pipFilterContext;
@property (nonatomic, strong) dispatch_queue_t pipCaptureQueue;
@property (nonatomic, strong) NSMutableSet<NSString *> *pipCaptureInFlight;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *settings;

- (void)saveCustomResolutionIfNeededForDisplayID:(NSString *)displayID
                                           width:(double)width
                                          height:(double)height
                                     refreshRate:(double)refreshRate
                                         isHiDpi:(BOOL)isHiDpi;
- (BOOL)exposedGeneratedHiDpiRecipeExistsForDisplayID:(CGDirectDisplayID)displayID
                                                width:(NSUInteger)width
                                               height:(NSUInteger)height;
- (void)restoreManagedVirtualDisplays;
- (NSString *)visibleDisplayIDForVirtualDisplay:(id)virtualDisplay;
- (void)scheduleVirtualDisplayActivationRetryForID:(NSString *)virtualDisplayID wantsMirror:(BOOL)wantsMirror;
- (void)retryVirtualDisplayActivationForID:(NSString *)virtualDisplayID
                               wantsMirror:(BOOL)wantsMirror
                                   attempt:(NSUInteger)attempt;
- (BOOL)activeDisplayListContainsDisplayID:(CGDirectDisplayID)displayID;
- (BOOL)configureDisplayID:(CGDirectDisplayID)displayID
           mirrorOfDisplay:(CGDirectDisplayID)sourceDisplayID
              errorMessage:(NSString **)errorMessage;
- (NSDictionary *)recordByApplyingVirtualMirrorForID:(NSString *)virtualDisplayID
                                              record:(NSDictionary *)record
                                        errorMessage:(NSString **)errorMessage;
- (NSDictionary *)recordByApplyingVirtualMirrorForID:(NSString *)virtualDisplayID
                                              record:(NSDictionary *)record
                                           restoring:(BOOL)restoring
                                        errorMessage:(NSString **)errorMessage;
- (NSString *)resolvedVirtualMirrorTargetDisplayIDForRecord:(NSDictionary *)record
                                                  restoring:(BOOL)restoring
                                               errorMessage:(NSString **)errorMessage;
- (NSString *)resolvedVirtualTargetDisplayIDForRecord:(NSDictionary *)record;
- (BOOL)createVirtualHiDpiFallbackForDisplayIDString:(NSString *)targetDisplayID
                                               width:(NSUInteger)width
                                              height:(NSUInteger)height
                                         refreshRate:(double)refreshRate
                                        statusReason:(NSString *)statusReason
                                        errorMessage:(NSString **)errorMessage;
- (NSArray<NSDictionary *> *)virtualDisplaySummaries;
- (NSDictionary *)pipWindowRecordWithID:(NSString *)pipWindowID
                              displayID:(NSString *)displayID
                                   name:(NSString *)name
                                  width:(double)width
                                 height:(double)height
                                    fps:(double)fps
                                 filter:(NSString *)filter
                                 status:(NSString *)status
                              lastError:(NSString *)lastError;
- (NSArray<NSDictionary *> *)pipWindowSummaries;
- (void)capturePipFrameForID:(NSString *)pipWindowID;
- (CGImageRef)newPipImageFromImage:(CGImageRef)imageRef filter:(NSString *)filter CF_RETURNS_RETAINED;
- (NSString *)normalizedPipFilter:(NSString *)filter;
- (NSDictionary *)detectedNativePanelResolutionForDisplayID:(CGDirectDisplayID)displayID;
- (NSDictionary *)nativePanelResolutionForDisplayID:(CGDirectDisplayID)displayID displayIDString:(NSString *)displayIDString;
- (BOOL)nativePanelResolutionOverrideExistsForDisplayIDString:(NSString *)displayID;
- (BOOL)flexibleScalingEnabledForDisplayIDString:(NSString *)displayID;
- (NSString *)customResolutionStorageKeyForDisplayIDString:(NSString *)displayID;
- (NSArray<NSDictionary *> *)customResolutionRequestsForDisplayIDString:(NSString *)displayID;
- (NSArray<NSDictionary *> *)generatedHiDpiCustomResolutionRequestsWithWidth:(NSUInteger)width
                                                                      height:(NSUInteger)height
                                                                 refreshRate:(double)refreshRate;
- (NSString *)writeOverrideBundleForDisplayIDString:(NSString *)displayID
                                        includeEdid:(BOOL)includeEdid
                                  customResolutions:(NSArray<NSDictionary *> *)customResolutions;
- (void)persistNativePanelResolutionState;
- (NSString *)overrideLifecycleKeyForDisplayIDString:(NSString *)displayID;
- (NSURL *)overrideTargetFileURLForLifecycleKey:(NSString *)lifecycleKey;

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
    NSDictionary *storedOverrideInstalledPaths =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayOverrideInstalledPathsDefaultsKey];
    NSDictionary *storedOverrideBackupPaths =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayOverrideBackupPathsDefaultsKey];
    NSDictionary *storedOverrideInstalledHashes =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayOverrideInstalledHashesDefaultsKey];
    NSDictionary *storedOverrideBackupHashes =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayOverrideBackupHashesDefaultsKey];
    NSDictionary *storedOverridePendingReboot =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayOverridePendingRebootDefaultsKey];
    NSDictionary *storedOverridePendingReinitialize =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayOverridePendingReinitializeDefaultsKey];
    NSDictionary *storedOverrideLastErrors =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayOverrideLastErrorsDefaultsKey];
    NSDictionary *storedOverrideInstallTimes =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayOverrideInstallTimesDefaultsKey];
    NSDictionary *storedNativePanelResolutionOverrides =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayNativePanelResolutionOverridesDefaultsKey];
    NSDictionary *storedFlexibleScaling =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayFlexibleScalingDefaultsKey];
    NSDictionary *storedVirtualDisplays =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:RCTDisplayVirtualDisplaysDefaultsKey];
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
    self.overrideInstalledPaths =
        storedOverrideInstalledPaths != nil ? [storedOverrideInstalledPaths mutableCopy] : [NSMutableDictionary new];
    self.overrideBackupPaths =
        storedOverrideBackupPaths != nil ? [storedOverrideBackupPaths mutableCopy] : [NSMutableDictionary new];
    self.overrideInstalledHashes =
        storedOverrideInstalledHashes != nil ? [storedOverrideInstalledHashes mutableCopy] : [NSMutableDictionary new];
    self.overrideBackupHashes =
        storedOverrideBackupHashes != nil ? [storedOverrideBackupHashes mutableCopy] : [NSMutableDictionary new];
    self.overridePendingReboot =
        storedOverridePendingReboot != nil ? [storedOverridePendingReboot mutableCopy] : [NSMutableDictionary new];
    self.overridePendingReinitialize =
        storedOverridePendingReinitialize != nil ? [storedOverridePendingReinitialize mutableCopy] : [NSMutableDictionary new];
    self.overrideLastErrors =
        storedOverrideLastErrors != nil ? [storedOverrideLastErrors mutableCopy] : [NSMutableDictionary new];
    self.overrideInstallTimes =
        storedOverrideInstallTimes != nil ? [storedOverrideInstallTimes mutableCopy] : [NSMutableDictionary new];
    self.nativePanelResolutionOverrides =
        storedNativePanelResolutionOverrides != nil ? [storedNativePanelResolutionOverrides mutableCopy] : [NSMutableDictionary new];
    self.flexibleScalingEnabled =
        storedFlexibleScaling != nil ? [storedFlexibleScaling mutableCopy] : [NSMutableDictionary new];
    self.virtualDisplayRecords =
        storedVirtualDisplays != nil ? [storedVirtualDisplays mutableCopy] : [NSMutableDictionary new];
    self.virtualDisplays = [NSMutableDictionary new];
    self.virtualDisplayActivationAttempts = [NSMutableDictionary new];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:RCTDisplayPipWindowsDefaultsKey];
    self.pipWindowRecords = [NSMutableDictionary new];
    self.pipWindows = [NSMutableDictionary new];
    self.pipCaptureTimers = [NSMutableDictionary new];
    self.pipImageViews = [NSMutableDictionary new];
    self.pipCloseObservers = [NSMutableDictionary new];
    self.pipFilterContext = [CIContext contextWithOptions:nil];
    self.pipCaptureQueue = dispatch_queue_create("com.jingjing2222.macdisplaybar.pip-capture", DISPATCH_QUEUE_SERIAL);
    self.pipCaptureInFlight = [NSMutableSet new];
    self.settings = [[self normalizedSettingsFromDictionary:storedSettings] mutableCopy];
    [self clearRebootPendingStatesAfterSystemBoot];
    [self restoreManagedVirtualDisplays];
    CGDisplayRegisterReconfigurationCallback(RCTDisplayReconfigurationCallback, (__bridge void *)self);
  }

  return self;
}

- (void)dealloc
{
  for (NSTimer *timer in self.pipCaptureTimers.allValues) {
    [timer invalidate];
  }
  for (id observer in self.pipCloseObservers.allValues) {
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
  }
  CGDisplayRemoveReconfigurationCallback(RCTDisplayReconfigurationCallback, (__bridge void *)self);
}

#include "Sections/RCTDisplayCore+Actions.inc.mm"
#include "Sections/RCTDisplayCore+VirtualDisplays.inc.mm"
#include "Sections/RCTDisplayCore+PictureInPicture.inc.mm"
#include "Sections/RCTDisplayCore+Snapshot.inc.mm"
#include "Sections/RCTDisplayCore+Overrides.inc.mm"
#include "Sections/RCTDisplayCore+Modes.inc.mm"
#include "Sections/RCTDisplayCore+AutomationLayout.inc.mm"
#include "Sections/RCTDisplayCore+HardwareControls.inc.mm"

@end
