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
  double clampedLevel = MDBClampDouble(level, 0, 1);
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
  double clampedLevel = MDBClampDouble(level, 0, 0.8);
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
    if (resolvedDisplayID.length == 0) {
      continue;
    }

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
      double clampedLevel = MDBClampDouble(dimmingLevel.doubleValue, 0, 0.8);
      self.dimmingLevels[resolvedDisplayID] = @(clampedLevel);
      [self syncDimmingWindowForDisplayID:directDisplayID level:clampedLevel];
    }

    if ([nativeBrightness isKindOfClass:NSNumber.class]) {
      [self setNativeBrightnessForDisplayID:directDisplayID
                                      level:MDBClampDouble(nativeBrightness.doubleValue, 0, 1)
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
  [self saveCustomResolutionIfNeededForDisplayID:displayID
                                           width:width
                                          height:height
                                     refreshRate:refreshRate
                                         isHiDpi:isHiDpi];

  return [self stubbedSnapshot];
}

- (NSDictionary *)removeCustomResolution:(NSString *)displayID requestID:(NSString *)requestID
{
  NSString *storageKey = [self customResolutionStorageKeyForDisplayIDString:displayID];
  NSMutableArray<NSDictionary *> *requests =
      [[self customResolutionRequestsForDisplayIDString:displayID] mutableCopy] ?: [NSMutableArray new];
  NSIndexSet *matchingIndexes = [requests indexesOfObjectsPassingTest:^BOOL(NSDictionary *request, NSUInteger index, BOOL *stop) {
    return [request[@"id"] isEqualToString:requestID];
  }];
  [requests removeObjectsAtIndexes:matchingIndexes];
  self.customResolutionRequests[storageKey] = requests;
  if (![storageKey isEqualToString:displayID]) {
    [self.customResolutionRequests removeObjectForKey:displayID];
  }
  [self recordAdvancedOperation:@"Custom resolution request removed" displayID:displayID];
  [[NSUserDefaults standardUserDefaults] setObject:self.customResolutionRequests
                                            forKey:RCTDisplayCustomResolutionsDefaultsKey];

  NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayID];
  NSString *bundlePath = [self writeOverrideBundleForDisplayIDString:displayID];

  if (bundlePath.length > 0) {
    self.overrideBundlePaths[displayID] = bundlePath;
    self.overrideBundleStatus[displayID] = @"Bundle written";
    [self.overrideLastErrors removeObjectForKey:lifecycleKey];
  } else if (![self overridePayloadExistsForDisplayIDString:displayID]) {
    [self.overrideBundlePaths removeObjectForKey:displayID];
    self.overrideBundleStatus[displayID] = @"No payload";
    [self.overrideLastErrors removeObjectForKey:lifecycleKey];
  } else {
    self.overrideBundleStatus[displayID] = @"Bundle write failed";
    self.overrideLastErrors[lifecycleKey] = @"Display override bundle write failed";
  }

  if (self.overrideInstalledPaths[lifecycleKey].length > 0 || self.overrideBackupPaths[lifecycleKey].length > 0) {
    if ([self overridePayloadExistsForDisplayIDString:displayID]) {
      return [self installDisplayOverride:displayID];
    }

    return [self removeDisplayOverride:displayID];
  }

  [self persistOverrideLifecycleStateForDisplayID:lifecycleKey];
  return [self stubbedSnapshot];
}

- (void)saveCustomResolutionIfNeededForDisplayID:(NSString *)displayID
                                           width:(double)width
                                          height:(double)height
                                     refreshRate:(double)refreshRate
                                         isHiDpi:(BOOL)isHiDpi
{
  double normalizedWidth = MAX(width, 1);
  double normalizedHeight = MAX(height, 1);
  double normalizedRefreshRate = MAX(refreshRate, 0);
  NSString *storageKey = [self customResolutionStorageKeyForDisplayIDString:displayID];
  NSMutableArray<NSDictionary *> *requests =
      [[self customResolutionRequestsForDisplayIDString:displayID] mutableCopy] ?: [NSMutableArray new];

  for (NSDictionary *request in requests) {
    BOOL sameWidth = llround([request[@"width"] doubleValue]) == llround(normalizedWidth);
    BOOL sameHeight = llround([request[@"height"] doubleValue]) == llround(normalizedHeight);
    BOOL sameRefreshRate = llround([request[@"refreshRate"] doubleValue]) == llround(normalizedRefreshRate);
    BOOL sameScale = [request[@"isHiDpi"] boolValue] == isHiDpi;

    if (sameWidth && sameHeight && sameRefreshRate && sameScale) {
      return;
    }
  }

  NSDictionary *request = @{
    @"id" : [[NSUUID UUID] UUIDString],
    @"width" : @(normalizedWidth),
    @"height" : @(normalizedHeight),
    @"refreshRate" : @(normalizedRefreshRate),
    @"isHiDpi" : @(isHiDpi),
    @"status" : @"Queued for override",
  };
  [requests addObject:request];
  self.customResolutionRequests[storageKey] = requests;
  if (![storageKey isEqualToString:displayID]) {
    [self.customResolutionRequests removeObjectForKey:displayID];
  }
  [self recordAdvancedOperation:@"Custom resolution request saved" displayID:displayID];
  [[NSUserDefaults standardUserDefaults] setObject:self.customResolutionRequests
                                            forKey:RCTDisplayCustomResolutionsDefaultsKey];
}

- (NSDictionary *)queueEdidOverride:(NSString *)displayID
{
  NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayID];
  NSString *edidPath = [self exportEdidFileForDisplayIDString:displayID];

  if (edidPath.length > 0) {
    self.edidOverridePaths[displayID] = edidPath;
    NSString *bundlePath = [self writeOverrideBundleForDisplayIDString:displayID];
    self.edidOverrideStatus[displayID] = bundlePath.length > 0 ? @"Override prepared" : @"Override prepare failed";

    if (bundlePath.length > 0) {
      self.overrideBundlePaths[displayID] = bundlePath;
      self.overrideBundleStatus[displayID] = @"Bundle written";
      [self.overrideLastErrors removeObjectForKey:lifecycleKey];
    } else {
      self.overrideBundleStatus[displayID] = @"Bundle write failed";
      self.overrideLastErrors[lifecycleKey] = @"Display override bundle write failed";
    }

    [self recordAdvancedOperation:(bundlePath.length > 0 ? @"EDID override prepared" : @"EDID override prepare failed")
                        displayID:displayID];
    [[NSUserDefaults standardUserDefaults] setObject:self.edidOverridePaths forKey:RCTDisplayEdidOverridePathsDefaultsKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.edidOverrideStatus forKey:RCTDisplayEdidOverrideStatusDefaultsKey];
    [self persistOverrideLifecycleStateForDisplayID:lifecycleKey];
    return [self stubbedSnapshot];
  } else {
    self.edidOverrideStatus[displayID] = @"EDID unavailable";
    [self recordAdvancedOperation:@"EDID override unavailable" displayID:displayID];
  }

  return [self stubbedSnapshot];
}

- (NSDictionary *)clearEdidOverride:(NSString *)displayID
{
  [self.edidOverridePaths removeObjectForKey:displayID];
  [[NSUserDefaults standardUserDefaults] setObject:self.edidOverridePaths forKey:RCTDisplayEdidOverridePathsDefaultsKey];

  if ([self overridePayloadExistsForDisplayIDString:displayID]) {
    [self installDisplayOverride:displayID];
  } else {
    [self removeDisplayOverride:displayID];
  }
  BOOL didClearOverride = [self.overrideBundleStatus[displayID] isEqualToString:@"Installed"] ||
      [self.overrideBundleStatus[displayID] isEqualToString:@"Removed"] ||
      [self.overrideBundleStatus[displayID] isEqualToString:@"Restored backup"] ||
      [self.overrideBundleStatus[displayID] isEqualToString:@"No override"];
  self.edidOverrideStatus[displayID] = didClearOverride ? @"Override cleared" : @"Override clear failed";
  [self recordAdvancedOperation:(didClearOverride ? @"EDID override cleared" : @"EDID override clear failed")
                      displayID:displayID];
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

- (NSDictionary *)installDisplayOverride:(NSString *)displayID
{
  NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayID];

  if (![self overridePayloadExistsForDisplayIDString:displayID]) {
    self.overrideBundleStatus[displayID] = @"No payload";
    self.overrideLastErrors[lifecycleKey] = @"Display override has no EDID or custom resolution payload";
    [self persistOverrideLifecycleStateForDisplayID:lifecycleKey];
    [self recordAdvancedOperation:@"Display override install skipped" displayID:displayID];
    return [self stubbedSnapshot];
  }

  NSString *bundlePath = [self writeOverrideBundleForDisplayIDString:displayID];
  NSString *installError = nil;
  BOOL didInstallBundle = NO;
  BOOL didMutateInstall = NO;
  BOOL hadManagedInstall = self.overrideInstalledHashes[lifecycleKey].length > 0;

  if (bundlePath.length > 0) {
    self.overrideBundlePaths[displayID] = bundlePath;
    didInstallBundle = [self installOverrideBundleAtPath:bundlePath
                                         displayIDString:lifecycleKey
                                               didMutate:&didMutateInstall
                                            errorMessage:&installError];
  }

  self.overrideBundleStatus[displayID] = didInstallBundle ? @"Installed" : @"Install failed";

  if (didInstallBundle) {
    if (didMutateInstall || hadManagedInstall || self.overrideInstalledHashes[lifecycleKey].length > 0) {
      NSURL *targetFileURL = [self overrideTargetFileURLForDisplayIDString:displayID];

      if (targetFileURL.path.length > 0) {
        self.overrideInstalledPaths[lifecycleKey] = targetFileURL.path;
        self.overrideInstalledHashes[lifecycleKey] = MDBSHA256FileHash(targetFileURL.path);
      }
    } else {
      self.overrideBundleStatus[displayID] = @"Installed externally";
    }

    if (didMutateInstall) {
      self.overridePendingReboot[lifecycleKey] = @YES;
      self.overridePendingReinitialize[lifecycleKey] = @YES;
      self.overrideInstallTimes[lifecycleKey] = @([[NSDate date] timeIntervalSince1970]);
    }
    [self.overrideLastErrors removeObjectForKey:lifecycleKey];
  } else {
    self.overrideLastErrors[lifecycleKey] = installError ?: @"Display override install failed";
  }

  [self persistOverrideLifecycleStateForDisplayID:lifecycleKey];
  [self recordAdvancedOperation:(didInstallBundle ? @"Display override installed" : @"Display override install failed")
                      displayID:displayID];

  return [self stubbedSnapshot];
}

- (NSDictionary *)removeDisplayOverride:(NSString *)displayID
{
  NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayID];
  NSURL *targetFileURL = [self overrideTargetFileURLForDisplayIDString:displayID];
  BOOL hasTarget = targetFileURL.path.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:targetFileURL.path];
  BOOL hasBackup = self.overrideBackupPaths[lifecycleKey].length > 0;

  if (!hasTarget && !hasBackup) {
    self.overrideBundleStatus[displayID] = @"No override";
    [self.overrideInstalledPaths removeObjectForKey:lifecycleKey];
    [self.overrideInstalledHashes removeObjectForKey:lifecycleKey];
    [self.overrideBundlePaths removeObjectForKey:displayID];
    [self.overridePendingReboot removeObjectForKey:lifecycleKey];
    [self.overridePendingReinitialize removeObjectForKey:lifecycleKey];
    [self.overrideLastErrors removeObjectForKey:lifecycleKey];
    [self persistOverrideLifecycleStateForDisplayID:lifecycleKey];
    [self recordAdvancedOperation:@"Display override remove skipped" displayID:displayID];
    return [self stubbedSnapshot];
  }

  NSString *removeError = nil;
  BOOL didRemove = [self removeInstalledOverrideForDisplayIDString:lifecycleKey errorMessage:&removeError];

  if (didRemove) {
    self.overrideBundleStatus[displayID] = self.overrideBackupPaths[lifecycleKey].length > 0 ? @"Restored backup" : @"Removed";
    [self.overrideInstalledPaths removeObjectForKey:lifecycleKey];
    [self.overrideInstalledHashes removeObjectForKey:lifecycleKey];
    [self.overrideBundlePaths removeObjectForKey:displayID];
    [self.overrideBackupPaths removeObjectForKey:lifecycleKey];
    [self.overrideBackupHashes removeObjectForKey:lifecycleKey];
    self.overridePendingReboot[lifecycleKey] = @YES;
    self.overridePendingReinitialize[lifecycleKey] = @YES;
    self.overrideInstallTimes[lifecycleKey] = @([[NSDate date] timeIntervalSince1970]);
    [self.overrideLastErrors removeObjectForKey:lifecycleKey];
  } else {
    self.overrideBundleStatus[displayID] = @"Remove failed";
    self.overrideLastErrors[lifecycleKey] = removeError ?: @"Display override remove failed";
  }

  [self persistOverrideLifecycleStateForDisplayID:lifecycleKey];
  [self recordAdvancedOperation:(didRemove ? @"Display override removed" : @"Display override remove failed")
                      displayID:displayID];

  return [self stubbedSnapshot];
}

- (NSDictionary *)reinitializeDisplay:(NSString *)displayID
{
  NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayID];
  NSString *errorMessage = nil;
  BOOL didReinitialize = [self requestDisplayReinitializeForDisplayID:(CGDirectDisplayID)displayID.integerValue
                                                         errorMessage:&errorMessage];

  if (didReinitialize) {
    self.overridePendingReinitialize[lifecycleKey] = @NO;
    [self.overrideLastErrors removeObjectForKey:lifecycleKey];
  } else {
    self.overrideLastErrors[lifecycleKey] = errorMessage ?: @"Display reinitialize failed";
  }

  [self persistOverrideLifecycleStateForDisplayID:lifecycleKey];
  [self recordAdvancedOperation:(didReinitialize ? @"Display reinitialize requested" : @"Display reinitialize failed")
                      displayID:displayID];

  return [self stubbedSnapshot];
}

- (NSDictionary *)setNativePanelResolutionOverride:(NSString *)displayID width:(double)width height:(double)height
{
  NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayID];
  NSUInteger normalizedWidth = (NSUInteger)llround(MAX(width, 1));
  NSUInteger normalizedHeight = (NSUInteger)llround(MAX(height, 1));

  self.nativePanelResolutionOverrides[lifecycleKey] = @{
    @"width" : @(normalizedWidth),
    @"height" : @(normalizedHeight),
  };
  if (![lifecycleKey isEqualToString:displayID]) {
    [self.nativePanelResolutionOverrides removeObjectForKey:displayID];
  }
  [self persistNativePanelResolutionState];
  NSString *bundlePath = [self writeOverrideBundleForDisplayIDString:displayID];

  if (bundlePath.length > 0) {
    self.overrideBundlePaths[displayID] = bundlePath;
    self.overrideBundleStatus[displayID] =
        self.overrideInstalledPaths[lifecycleKey].length > 0 ? @"Bundle written" : @"Bundle written (install required)";
    [self.overrideLastErrors removeObjectForKey:lifecycleKey];
  }

  if (self.overrideInstalledPaths[lifecycleKey].length > 0 || self.overrideBackupPaths[lifecycleKey].length > 0) {
    return [self installDisplayOverride:displayID];
  }

  [self persistOverrideLifecycleStateForDisplayID:lifecycleKey];
  [self recordAdvancedOperation:@"Native panel resolution override saved" displayID:displayID];
  NSLog(@"[macDisplayBar] Native panel resolution override saved: displayID=%@ width=%lu height=%lu bundlePath=%@",
        displayID,
        (unsigned long)normalizedWidth,
        (unsigned long)normalizedHeight,
        bundlePath ?: @"");

  return [self stubbedSnapshot];
}

- (NSDictionary *)clearNativePanelResolutionOverride:(NSString *)displayID
{
  NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayID];
  [self.nativePanelResolutionOverrides removeObjectForKey:lifecycleKey];
  [self.nativePanelResolutionOverrides removeObjectForKey:displayID];
  [self persistNativePanelResolutionState];
  NSString *bundlePath = [self writeOverrideBundleForDisplayIDString:displayID];

  if (bundlePath.length > 0) {
    self.overrideBundlePaths[displayID] = bundlePath;
    self.overrideBundleStatus[displayID] =
        self.overrideInstalledPaths[lifecycleKey].length > 0 ? @"Bundle written" : @"Bundle written (install required)";
    [self.overrideLastErrors removeObjectForKey:lifecycleKey];
  } else if (![self overridePayloadExistsForDisplayIDString:displayID]) {
    [self.overrideBundlePaths removeObjectForKey:displayID];
    self.overrideBundleStatus[displayID] = @"No payload";
    [self.overrideLastErrors removeObjectForKey:lifecycleKey];
  }

  if (self.overrideInstalledPaths[lifecycleKey].length > 0 || self.overrideBackupPaths[lifecycleKey].length > 0) {
    if ([self overridePayloadExistsForDisplayIDString:displayID]) {
      return [self installDisplayOverride:displayID];
    }

    return [self removeDisplayOverride:displayID];
  }

  [self persistOverrideLifecycleStateForDisplayID:lifecycleKey];
  [self recordAdvancedOperation:@"Native panel resolution override cleared" displayID:displayID];
  NSLog(@"[macDisplayBar] Native panel resolution override cleared: displayID=%@ bundlePath=%@",
        displayID,
        bundlePath ?: @"");

  return [self stubbedSnapshot];
}

- (NSDictionary *)setFlexibleScalingEnabled:(NSString *)displayID enabled:(BOOL)enabled
{
  NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayID];
  self.flexibleScalingEnabled[lifecycleKey] = @(enabled);
  if (![lifecycleKey isEqualToString:displayID]) {
    [self.flexibleScalingEnabled removeObjectForKey:displayID];
  }
  [self persistNativePanelResolutionState];
  NSString *bundlePath = [self writeOverrideBundleForDisplayIDString:displayID];

  if (bundlePath.length > 0) {
    self.overrideBundlePaths[displayID] = bundlePath;
    self.overrideBundleStatus[displayID] =
        self.overrideInstalledPaths[lifecycleKey].length > 0 ? @"Bundle written" : @"Bundle written (install required)";
    [self.overrideLastErrors removeObjectForKey:lifecycleKey];
  } else if (![self overridePayloadExistsForDisplayIDString:displayID]) {
    [self.overrideBundlePaths removeObjectForKey:displayID];
    self.overrideBundleStatus[displayID] = @"No payload";
    [self.overrideLastErrors removeObjectForKey:lifecycleKey];
  }

  if (self.overrideInstalledPaths[lifecycleKey].length > 0 || self.overrideBackupPaths[lifecycleKey].length > 0) {
    if ([self overridePayloadExistsForDisplayIDString:displayID]) {
      return [self installDisplayOverride:displayID];
    }

    return [self removeDisplayOverride:displayID];
  }

  [self persistOverrideLifecycleStateForDisplayID:lifecycleKey];
  [self recordAdvancedOperation:(enabled ? @"Flexible scaling enabled" : @"Flexible scaling disabled")
                      displayID:displayID];
  NSLog(@"[macDisplayBar] Flexible scaling state changed: displayID=%@ enabled=%@ bundlePath=%@",
        displayID,
        enabled ? @"YES" : @"NO",
        bundlePath ?: @"");

  return [self stubbedSnapshot];
}

- (NSDictionary *)setDisplayRotation:(NSString *)displayID rotation:(double)rotation
{
  double normalizedRotation = MDBNearestDouble(rotation, @[ @0, @90, @180, @270 ]);
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

- (NSDictionary *)createVirtualDisplay:(NSString *)targetDisplayID
                                  width:(double)width
                                 height:(double)height
                            refreshRate:(double)refreshRate
                                isHiDpi:(BOOL)isHiDpi
{
  if (![NSThread isMainThread]) {
    __block NSDictionary *snapshot = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
      snapshot = [self createVirtualDisplay:targetDisplayID
                                      width:width
                                     height:height
                                refreshRate:refreshRate
                                    isHiDpi:isHiDpi];
    });
    return snapshot ?: [self stubbedSnapshot];
  }

  NSString *virtualDisplayID = [[NSUUID UUID] UUIDString];
  NSString *errorMessage = nil;
  NSNumber *serialNumber = @(arc4random());
  NSDictionary *record = [self createVirtualDisplayRecordWithID:virtualDisplayID
                                                 targetDisplayID:targetDisplayID ?: @""
                                                    serialNumber:serialNumber
                                                          width:width
                                                         height:height
                                                    refreshRate:refreshRate
                                                        isHiDpi:isHiDpi
                                                   errorMessage:&errorMessage];

  if (record.count > 0) {
    self.virtualDisplayRecords[virtualDisplayID] = record;
    [self recordAdvancedOperation:@"Virtual display created" displayID:record[@"displayID"] ?: @""];
    if ([record[@"status"] isEqualToString:@"Creating"]) {
      [self scheduleVirtualDisplayActivationRetryForID:virtualDisplayID wantsMirror:NO];
    }
  } else {
    double normalizedRefreshRate = refreshRate > 0 ? refreshRate : 60;
    self.virtualDisplayRecords[virtualDisplayID] = [self virtualDisplayRecordWithID:virtualDisplayID
                                                                    targetDisplayID:targetDisplayID ?: @""
		                                                                          displayID:@""
                                                              mirrorTargetDisplayID:@""
                                                              mirrorSourceDisplayID:@""
                                                                           mirrorMode:@"none"
                                                                         mirrorStatus:@"Not mirrored"
                                                                               name:@"macDisplayBar Virtual Display"
                                                                        serialNumber:serialNumber
		                                                                              width:MAX(width, 1)
		                                                                             height:MAX(height, 1)
                                                                        refreshRate:normalizedRefreshRate
                                                                            isHiDpi:isHiDpi
                                                                             status:@"Create failed"
                                                                          lastError:errorMessage ?: @"Virtual display unavailable"];
  }

  [self persistVirtualDisplayRecords];
  return [self stubbedSnapshot];
}

- (NSDictionary *)mirrorVirtualDisplayToTarget:(NSString *)virtualDisplayID
{
  if (![NSThread isMainThread]) {
    __block NSDictionary *snapshot = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
      snapshot = [self mirrorVirtualDisplayToTarget:virtualDisplayID];
    });
    return snapshot ?: [self stubbedSnapshot];
  }

  NSDictionary *record = self.virtualDisplayRecords[virtualDisplayID];

  if (![record isKindOfClass:NSDictionary.class]) {
    return [self stubbedSnapshot];
  }

  NSString *recordDisplayID = [record[@"displayID"] isKindOfClass:NSString.class] ? record[@"displayID"] : @"";
  if ([record[@"status"] isEqualToString:@"Creating"] || recordDisplayID.length == 0) {
    NSMutableDictionary *pendingRecord = [record mutableCopy];
    pendingRecord[@"mirrorTargetDisplayID"] = record[@"targetDisplayID"] ?: @"";
    pendingRecord[@"mirrorMode"] = @"target-mirrors-virtual";
    pendingRecord[@"mirrorStatus"] = @"Mirror pending";
    pendingRecord[@"lastError"] = @"";
    self.virtualDisplayRecords[virtualDisplayID] = pendingRecord;
    [self persistVirtualDisplayRecords];
    [self scheduleVirtualDisplayActivationRetryForID:virtualDisplayID wantsMirror:YES];
    NSLog(@"[macDisplayBar] Virtual display mirror queued pending activation: id=%@ target=%@",
          virtualDisplayID,
          pendingRecord[@"mirrorTargetDisplayID"] ?: @"");
    return [self stubbedSnapshot];
  }

  NSString *errorMessage = nil;
  NSDictionary *updatedRecord = [self recordByApplyingVirtualMirrorForID:virtualDisplayID
                                                                  record:record
                                                            errorMessage:&errorMessage];
  self.virtualDisplayRecords[virtualDisplayID] = updatedRecord;
  [self persistVirtualDisplayRecords];
  return [self stubbedSnapshot];
}

- (NSDictionary *)stopVirtualDisplayMirroring:(NSString *)virtualDisplayID
{
  if (![NSThread isMainThread]) {
    __block NSDictionary *snapshot = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
      snapshot = [self stopVirtualDisplayMirroring:virtualDisplayID];
    });
    return snapshot ?: [self stubbedSnapshot];
  }

  NSDictionary *record = self.virtualDisplayRecords[virtualDisplayID];

  if (![record isKindOfClass:NSDictionary.class]) {
    return [self stubbedSnapshot];
  }

  NSString *targetDisplayID = [record[@"mirrorTargetDisplayID"] isKindOfClass:NSString.class]
      ? record[@"mirrorTargetDisplayID"]
      : record[@"targetDisplayID"];
  NSString *sourceDisplayID = [record[@"mirrorSourceDisplayID"] isKindOfClass:NSString.class]
      ? record[@"mirrorSourceDisplayID"]
      : @"";
  NSString *liveSourceDisplayID = [self visibleDisplayIDForVirtualDisplay:self.virtualDisplays[virtualDisplayID]];
  NSString *errorMessage = nil;
  BOOL targetMirrorsThisVirtual = targetDisplayID.length > 0 &&
      sourceDisplayID.length > 0 &&
      liveSourceDisplayID.length > 0 &&
      [liveSourceDisplayID isEqualToString:sourceDisplayID] &&
      CGDisplayMirrorsDisplay((CGDirectDisplayID)targetDisplayID.integerValue) == (CGDirectDisplayID)sourceDisplayID.integerValue;
  BOOL didStop = targetDisplayID.length == 0 ||
      sourceDisplayID.length == 0 ||
      !targetMirrorsThisVirtual ||
      [self configureDisplayID:(CGDirectDisplayID)targetDisplayID.integerValue
               mirrorOfDisplay:kCGNullDirectDisplay
                  errorMessage:&errorMessage];

  NSMutableDictionary *updatedRecord = [record mutableCopy];
  if (didStop) {
    updatedRecord[@"mirrorTargetDisplayID"] = @"";
    updatedRecord[@"mirrorSourceDisplayID"] = @"";
    updatedRecord[@"mirrorMode"] = @"none";
  }
  updatedRecord[@"mirrorStatus"] = didStop ? @"Not mirrored" : @"Mirror stop failed";
  updatedRecord[@"lastError"] = didStop ? @"" : (errorMessage ?: @"Virtual display mirror stop failed");
  self.virtualDisplayRecords[virtualDisplayID] = updatedRecord;
  [self persistVirtualDisplayRecords];
  return [self stubbedSnapshot];
}

- (NSDictionary *)removeVirtualDisplay:(NSString *)virtualDisplayID
{
  if (![NSThread isMainThread]) {
    __block NSDictionary *snapshot = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
      snapshot = [self removeVirtualDisplay:virtualDisplayID];
    });
    return snapshot ?: [self stubbedSnapshot];
  }

  if (virtualDisplayID.length == 0) {
    return [self stubbedSnapshot];
  }

  id virtualDisplay = self.virtualDisplays[virtualDisplayID];
  NSDictionary *record = self.virtualDisplayRecords[virtualDisplayID] ?: @{};
  NSString *mirrorTargetDisplayID = [record[@"mirrorTargetDisplayID"] isKindOfClass:NSString.class]
      ? record[@"mirrorTargetDisplayID"]
      : @"";
  NSString *mirrorSourceDisplayID = [record[@"mirrorSourceDisplayID"] isKindOfClass:NSString.class]
      ? record[@"mirrorSourceDisplayID"]
      : @"";
  NSString *liveSourceDisplayID = [self visibleDisplayIDForVirtualDisplay:self.virtualDisplays[virtualDisplayID]];

  if (mirrorTargetDisplayID.length > 0) {
    BOOL targetMirrorsThisVirtual = mirrorSourceDisplayID.length > 0 &&
        liveSourceDisplayID.length > 0 &&
        [liveSourceDisplayID isEqualToString:mirrorSourceDisplayID] &&
        CGDisplayMirrorsDisplay((CGDirectDisplayID)mirrorTargetDisplayID.integerValue) == (CGDirectDisplayID)mirrorSourceDisplayID.integerValue;
    NSString *mirrorError = nil;
    BOOL didStopMirror = !targetMirrorsThisVirtual ||
        [self configureDisplayID:(CGDirectDisplayID)mirrorTargetDisplayID.integerValue
                 mirrorOfDisplay:kCGNullDirectDisplay
                    errorMessage:&mirrorError];

    if (!didStopMirror) {
      NSMutableDictionary *updatedRecord = [record mutableCopy];
      updatedRecord[@"mirrorStatus"] = @"Mirror stop failed";
      updatedRecord[@"lastError"] = mirrorError ?: @"Virtual display mirror stop failed";
      self.virtualDisplayRecords[virtualDisplayID] = updatedRecord;
      [self persistVirtualDisplayRecords];
      NSLog(@"[macDisplayBar] Virtual display remove aborted because mirror stop failed: id=%@ target=%@ error=%@",
            virtualDisplayID,
            mirrorTargetDisplayID,
            mirrorError ?: @"");
      return [self stubbedSnapshot];
    }
  }

  if (virtualDisplay != nil) {
    SEL invalidateSelector = RCTDisplayPrivateSelector(@"invalidate");
    if ([virtualDisplay respondsToSelector:invalidateSelector]) {
      ((void (*)(id, SEL))objc_msgSend)(virtualDisplay, invalidateSelector);
    }
    [self.virtualDisplays removeObjectForKey:virtualDisplayID];
    [self recordAdvancedOperation:@"Virtual display removed" displayID:record[@"displayID"] ?: @""];
  }

  [self.virtualDisplayRecords removeObjectForKey:virtualDisplayID];
  [self persistVirtualDisplayRecords];
  return [self stubbedSnapshot];
}

- (NSDictionary *)openDisplayPip:(NSString *)displayID
{
  if (![NSThread isMainThread]) {
    __block NSDictionary *snapshot = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
      snapshot = [self openDisplayPip:displayID];
    });
    return snapshot ?: [self stubbedSnapshot];
  }

  if (![self displayIDStringIsActive:displayID]) {
    NSLog(@"[macDisplayBar] PiP open rejected: displayID=%@ reason=invalid or inactive display",
          displayID ?: @"");
    return [self stubbedSnapshot];
  }

  for (NSString *existingPipID in self.pipWindowRecords.allKeys) {
    NSDictionary *existingRecord = self.pipWindowRecords[existingPipID];
    NSString *existingDisplayID = [existingRecord[@"displayID"] isKindOfClass:NSString.class]
        ? existingRecord[@"displayID"]
        : @"";

    if ([existingDisplayID isEqualToString:displayID]) {
      NSWindow *existingWindow = self.pipWindows[existingPipID];

      if (existingWindow != nil) {
        [existingWindow makeKeyAndOrderFront:nil];
        return [self stubbedSnapshot];
      }

      [self.pipWindowRecords removeObjectForKey:existingPipID];
      [self.pipImageViews removeObjectForKey:existingPipID];
      NSTimer *staleTimer = self.pipCaptureTimers[existingPipID];
      [staleTimer invalidate];
      [self.pipCaptureTimers removeObjectForKey:existingPipID];
      id staleObserver = self.pipCloseObservers[existingPipID];

      if (staleObserver != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:staleObserver];
        [self.pipCloseObservers removeObjectForKey:existingPipID];
      }
    }
  }

  CGDirectDisplayID directDisplayID = (CGDirectDisplayID)displayID.integerValue;
  CGRect displayBounds = CGDisplayBounds(directDisplayID);
  double sourceWidth = MAX(displayBounds.size.width, 1);
  double sourceHeight = MAX(displayBounds.size.height, 1);
  double pipWidth = MDBClampDouble(sourceWidth / 3.0, 360, 720);
  double pipHeight = MAX(pipWidth * sourceHeight / sourceWidth, 160);
  NSString *pipWindowID = [[NSUUID UUID] UUIDString];
  NSString *screenName = @"";
  NSScreen *sourceScreen = nil;
  NSScreen *pipScreen = nil;

  for (NSScreen *screen in NSScreen.screens) {
    NSNumber *screenNumber = screen.deviceDescription[@"NSScreenNumber"];

    if ([screenNumber isKindOfClass:NSNumber.class] && screenNumber.unsignedIntValue == directDisplayID) {
      screenName = screen.localizedName ?: @"";
      sourceScreen = screen;
    } else if (pipScreen == nil) {
      pipScreen = screen;
    }
  }

  if (pipScreen == nil) {
    pipScreen = sourceScreen ?: NSScreen.mainScreen ?: NSScreen.screens.firstObject;
  }

  NSString *displayName = [self displayNameForDisplayID:directDisplayID screenName:screenName];
  NSString *windowTitle = [NSString stringWithFormat:@"macDisplayBar PiP - %@", displayName];
  NSRect pipContainerFrame = pipScreen != nil
      ? pipScreen.frame
      : NSMakeRect(displayBounds.origin.x, displayBounds.origin.y, displayBounds.size.width, displayBounds.size.height);
  NSRect windowFrame = NSMakeRect(NSMidX(pipContainerFrame) - pipWidth / 2.0,
                                  NSMidY(pipContainerFrame) - pipHeight / 2.0,
                                  pipWidth,
                                  pipHeight);
  NSWindow *window = [[NSWindow alloc] initWithContentRect:windowFrame
                                                 styleMask:NSWindowStyleMaskTitled |
                                                           NSWindowStyleMaskClosable |
                                                           NSWindowStyleMaskResizable |
                                                           NSWindowStyleMaskMiniaturizable
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
  NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, pipWidth, pipHeight)];
  imageView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
  window.title = windowTitle;
  window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
      NSWindowCollectionBehaviorFullScreenAuxiliary;
  window.level = NSFloatingWindowLevel;
  window.contentView = imageView;
  [window makeKeyAndOrderFront:nil];

  self.pipWindows[pipWindowID] = window;
  self.pipImageViews[pipWindowID] = imageView;
  self.pipWindowRecords[pipWindowID] = [self pipWindowRecordWithID:pipWindowID
                                                         displayID:displayID
                                                              name:windowTitle
                                                             width:pipWidth
                                                            height:pipHeight
                                                               fps:2
                                                            filter:@"none"
                                                            status:@"Open"
                                                         lastError:@""];
  __weak RCTDisplayCore *weakSelf = self;
  id closeObserver = [[NSNotificationCenter defaultCenter]
      addObserverForName:NSWindowWillCloseNotification
                  object:window
                   queue:[NSOperationQueue mainQueue]
              usingBlock:^(__unused NSNotification *notification) {
                RCTDisplayCore *strongSelf = weakSelf;

                if (strongSelf == nil || strongSelf.pipWindows[pipWindowID] == nil) {
                  return;
                }

                NSTimer *closeTimer = strongSelf.pipCaptureTimers[pipWindowID];
                [closeTimer invalidate];
                [strongSelf.pipCaptureTimers removeObjectForKey:pipWindowID];
                [strongSelf.pipWindows removeObjectForKey:pipWindowID];
                [strongSelf.pipImageViews removeObjectForKey:pipWindowID];
                NSDictionary *closedRecord = strongSelf.pipWindowRecords[pipWindowID] ?: @{};
                NSString *closedDisplayID = [closedRecord[@"displayID"] isKindOfClass:NSString.class]
                    ? closedRecord[@"displayID"]
                    : @"";
                [strongSelf.pipWindowRecords removeObjectForKey:pipWindowID];
                id observer = strongSelf.pipCloseObservers[pipWindowID];

                if (observer != nil) {
                  [[NSNotificationCenter defaultCenter] removeObserver:observer];
                  [strongSelf.pipCloseObservers removeObjectForKey:pipWindowID];
                }

                [strongSelf recordAdvancedOperation:@"Picture in Picture closed" displayID:closedDisplayID];
                NSLog(@"[macDisplayBar] PiP window closed from window control: id=%@ displayID=%@",
                      pipWindowID ?: @"",
                      closedDisplayID);
              }];
  self.pipCloseObservers[pipWindowID] = closeObserver;
  NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *captureTimer) {
    RCTDisplayCore *strongSelf = weakSelf;

    if (strongSelf == nil) {
      [captureTimer invalidate];
      return;
    }

    [strongSelf capturePipFrameForID:pipWindowID];
  }];
  self.pipCaptureTimers[pipWindowID] = timer;
  [self capturePipFrameForID:pipWindowID];
  [self recordAdvancedOperation:@"Picture in Picture opened" displayID:displayID];
  NSLog(@"[macDisplayBar] PiP window opened: id=%@ displayID=%@ width=%.0f height=%.0f",
        pipWindowID,
        displayID,
        pipWidth,
        pipHeight);
  return [self stubbedSnapshot];
}

- (NSDictionary *)setPipWindowFilter:(NSString *)pipWindowID filter:(NSString *)filter
{
  if (![NSThread isMainThread]) {
    __block NSDictionary *snapshot = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
      snapshot = [self setPipWindowFilter:pipWindowID filter:filter];
    });
    return snapshot ?: [self stubbedSnapshot];
  }

  NSDictionary *record = self.pipWindowRecords[pipWindowID];

  if (![record isKindOfClass:NSDictionary.class]) {
    NSLog(@"[macDisplayBar] PiP filter update ignored: id=%@ reason=record missing",
          pipWindowID ?: @"");
    return [self stubbedSnapshot];
  }

  NSString *normalizedFilter = [self normalizedPipFilter:filter];
  NSMutableDictionary *updatedRecord = [record mutableCopy];
  updatedRecord[@"filter"] = normalizedFilter;
  self.pipWindowRecords[pipWindowID] = updatedRecord;
  [self capturePipFrameForID:pipWindowID];
  [self recordAdvancedOperation:@"Picture in Picture filter changed" displayID:record[@"displayID"] ?: @""];
  NSLog(@"[macDisplayBar] PiP filter updated: id=%@ filter=%@",
        pipWindowID ?: @"",
        normalizedFilter);
  return [self stubbedSnapshot];
}

- (NSDictionary *)closeDisplayPip:(NSString *)pipWindowID
{
  if (![NSThread isMainThread]) {
    __block NSDictionary *snapshot = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
      snapshot = [self closeDisplayPip:pipWindowID];
    });
    return snapshot ?: [self stubbedSnapshot];
  }

  NSTimer *timer = self.pipCaptureTimers[pipWindowID];
  [timer invalidate];
  [self.pipCaptureTimers removeObjectForKey:pipWindowID];
  id closeObserver = self.pipCloseObservers[pipWindowID];

  if (closeObserver != nil) {
    [[NSNotificationCenter defaultCenter] removeObserver:closeObserver];
    [self.pipCloseObservers removeObjectForKey:pipWindowID];
  }

  NSWindow *window = self.pipWindows[pipWindowID];
  [window close];
  NSDictionary *record = self.pipWindowRecords[pipWindowID] ?: @{};
  NSString *displayID = [record[@"displayID"] isKindOfClass:NSString.class] ? record[@"displayID"] : @"";
  [self.pipWindows removeObjectForKey:pipWindowID];
  [self.pipImageViews removeObjectForKey:pipWindowID];
  [self.pipWindowRecords removeObjectForKey:pipWindowID];
  [self recordAdvancedOperation:@"Picture in Picture closed" displayID:displayID];
  NSLog(@"[macDisplayBar] PiP window closed: id=%@ displayID=%@",
        pipWindowID ?: @"",
        displayID);
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
  uint8_t clampedControlCode = MDBClampUInt8(controlCode);
  uint16_t clampedValue = MDBClampUInt16(value);
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

  refreshInterval = MDBClampDouble(refreshInterval, 5, 300);

  return @{
    @"autoRefresh" : @(autoRefresh.boolValue),
    @"refreshIntervalSeconds" : @(refreshInterval),
    @"showAdvancedMetadata" : @(showAdvancedMetadata.boolValue),
  };
}
