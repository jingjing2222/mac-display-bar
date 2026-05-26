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
    NSString *currentModeID = mode != NULL ? [self modeIDForMode:mode] : @"";

    for (NSDictionary *availableMode in [self availableModeDictionariesForDisplayID:displayID currentModeID:currentModeID]) {
      if ([availableMode[@"isCurrent"] boolValue]) {
        currentModeID = availableMode[@"id"] ?: currentModeID;
        break;
      }
    }

    displayStates[displayIDString] = @{
      @"identityKey" : [self identityKeyForDisplayID:displayID],
      @"modeID" : currentModeID,
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
  NSString *identityKey = storedState[@"identityKey"];

  if ([identityKey isKindOfClass:NSString.class] && identityKey.length > 0) {
    NSString *matchedDisplayID = [self activeDisplayIDStringForIdentityKey:identityKey];
    return matchedDisplayID.length > 0 ? matchedDisplayID : @"";
  }

  if ([self displayIDStringIsActive:displayID]) {
    return displayID;
  }

  return displayID;
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
    if (resolvedDisplayID.length == 0) {
      continue;
    }

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
    if (resolvedSourceDisplayID.length == 0) {
      return;
    }

    CGDirectDisplayID sourceDirectDisplayID = (CGDirectDisplayID)resolvedSourceDisplayID.integerValue;
    BOOL sourceSupportsNativeBrightness = [self displaySupportsNativeBrightness:sourceDirectDisplayID];
    double sourceNativeBrightness = sourceSupportsNativeBrightness
        ? [self nativeBrightnessForDisplayID:sourceDirectDisplayID didRead:nil]
        : MDBClampDouble(sourceDdcBrightness / 100, 0, 1);

    for (NSString *displayID in displayIDs) {
      if ([displayID isEqualToString:sourceDisplayID]) {
        continue;
      }

      NSDictionary *targetState = [layout isKindOfClass:NSDictionary.class] ? layout[displayID] : nil;
      NSString *resolvedDisplayID = [self resolveDisplayIDString:displayID storedState:targetState ?: @{}];
      if (resolvedDisplayID.length == 0) {
        continue;
      }

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
    if (resolvedSourceDisplayID.length == 0) {
      return;
    }

    NSDictionary *sourceModeState = [self currentModeStateForDisplayID:(CGDirectDisplayID)resolvedSourceDisplayID.integerValue];

    for (NSString *displayID in displayIDs) {
      if ([displayID isEqualToString:sourceDisplayID]) {
        continue;
      }

      NSDictionary *targetState = [layout isKindOfClass:NSDictionary.class] ? layout[displayID] : nil;
      NSString *resolvedDisplayID = [self resolveDisplayIDString:displayID storedState:targetState ?: @{}];
      if (resolvedDisplayID.length == 0) {
        continue;
      }

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
        uint16_t ddcValue = (uint16_t)MDBClampDouble(level * 100, 0, 100);
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
    uint16_t controlValue = MDBClampUInt16(value.doubleValue);
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
  return MDBTrimmedStringOrFallback(name, ^{
    return [NSString stringWithFormat:@"Preset %lu", (unsigned long)self.displayPresets.count + 1];
  });
}

- (NSString *)normalizedSyncGroupName:(NSString *)name
{
  return MDBTrimmedStringOrFallback(name, ^{
    return [NSString stringWithFormat:@"Group %lu", (unsigned long)self.syncGroups.count + 1];
  });
}
