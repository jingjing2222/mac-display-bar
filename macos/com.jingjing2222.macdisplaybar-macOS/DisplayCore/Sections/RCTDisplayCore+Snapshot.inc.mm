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
    @"virtualDisplays" : [self virtualDisplaySummaries],
    @"pipWindows" : [self pipWindowSummaries],
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
  NSMutableDictionary *currentMode = [@{
    @"id" : currentModeID,
    @"width" : @(width),
    @"height" : @(height),
    @"refreshRate" : @(refreshRate),
    @"isHiDpi" : @(isHiDpi),
    @"isCurrent" : @YES,
    @"isFavorite" : @([self modeIDIsFavorite:currentModeID displayIDString:displayIDString]),
    @"source" : @"coregraphics",
  } mutableCopy];
  NSArray *availableModes = [self availableModeDictionariesForDisplayID:displayID currentModeID:currentModeID];

  for (NSDictionary *availableMode in availableModes) {
    if ([availableMode[@"isCurrent"] boolValue]) {
      currentMode = [availableMode mutableCopy];
      currentMode[@"isCurrent"] = @YES;
      currentMode[@"isFavorite"] = @([self modeIDIsFavorite:currentMode[@"id"] displayIDString:displayIDString]);
      break;
    }
  }

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
    @"currentMode" : currentMode,
    @"availableModes" : availableModes,
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

- (NSDictionary *)detectedNativePanelResolutionForDisplayID:(CGDirectDisplayID)displayID
{
  NSDictionary *options = @{(__bridge NSString *)kCGDisplayShowDuplicateLowResolutionModes : @YES};
  CFArrayRef copiedModes = CGDisplayCopyAllDisplayModes(displayID, (__bridge CFDictionaryRef)options);
  NSUInteger maxStandardWidth = 0;
  NSUInteger maxStandardHeight = 0;
  NSUInteger maxStandardArea = 0;

  if (copiedModes != NULL) {
    NSArray *modes = CFBridgingRelease(copiedModes);

    for (id item in modes) {
      CGDisplayModeRef candidate = (__bridge CGDisplayModeRef)item;

      if (CGDisplayModeGetPixelWidth(candidate) > CGDisplayModeGetWidth(candidate)) {
        continue;
      }

      NSUInteger width = CGDisplayModeGetWidth(candidate);
      NSUInteger height = CGDisplayModeGetHeight(candidate);
      NSUInteger area = width * height;

      if (area > maxStandardArea) {
        maxStandardArea = area;
        maxStandardWidth = width;
        maxStandardHeight = height;
      }
    }
  }

  if (maxStandardWidth == 0 || maxStandardHeight == 0) {
    maxStandardWidth = CGDisplayPixelsWide(displayID);
    maxStandardHeight = CGDisplayPixelsHigh(displayID);
  }

  return @{
    @"width" : @(MAX(maxStandardWidth, 1)),
    @"height" : @(MAX(maxStandardHeight, 1)),
  };
}

- (NSDictionary *)nativePanelResolutionForDisplayID:(CGDirectDisplayID)displayID displayIDString:(NSString *)displayIDString
{
  NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayIDString];
  NSDictionary *override = self.nativePanelResolutionOverrides[lifecycleKey] ?:
      self.nativePanelResolutionOverrides[displayIDString] ?: @{};
  NSUInteger overrideWidth = [override[@"width"] unsignedIntegerValue];
  NSUInteger overrideHeight = [override[@"height"] unsignedIntegerValue];

  if (overrideWidth > 0 && overrideHeight > 0) {
    return @{
      @"width" : @(overrideWidth),
      @"height" : @(overrideHeight),
    };
  }

  return [self detectedNativePanelResolutionForDisplayID:displayID];
}

- (BOOL)nativePanelResolutionOverrideExistsForDisplayIDString:(NSString *)displayID
{
  NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayID];
  NSDictionary *override = self.nativePanelResolutionOverrides[lifecycleKey] ?:
      self.nativePanelResolutionOverrides[displayID] ?: @{};
  return [override[@"width"] unsignedIntegerValue] > 0 && [override[@"height"] unsignedIntegerValue] > 0;
}

- (BOOL)flexibleScalingEnabledForDisplayIDString:(NSString *)displayID
{
  NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayID];
  NSNumber *enabled = self.flexibleScalingEnabled[lifecycleKey] ?: self.flexibleScalingEnabled[displayID];
  return enabled.boolValue;
}
