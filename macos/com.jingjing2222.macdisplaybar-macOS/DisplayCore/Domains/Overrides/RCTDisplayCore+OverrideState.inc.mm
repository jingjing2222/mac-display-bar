- (NSString *)customResolutionStorageKeyForDisplayIDString:(NSString *)displayID
{
  NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayID];
  return lifecycleKey.length > 0 ? lifecycleKey : displayID;
}


- (NSArray<NSDictionary *> *)customResolutionRequestsForDisplayIDString:(NSString *)displayID
{
  NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayID];
  NSArray<NSDictionary *> *lifecycleRequests = self.customResolutionRequests[lifecycleKey];

  if (lifecycleRequests.count > 0) {
    return lifecycleRequests;
  }

  return self.customResolutionRequests[displayID] ?: @[];
}


- (NSDictionary *)advancedStateForDisplayID:(CGDirectDisplayID)displayID displayIDString:(NSString *)displayIDString
{
  NSData *edidData = [self edidDataForDisplayID:displayID];
  NSArray *customResolutions = [self customResolutionRequestsForDisplayIDString:displayIDString];
  NSNumber *rotationRequest = self.rotationRequests[displayIDString] ?: @(CGDisplayRotation(displayID));
  NSDictionary *detectedPanelResolution = [self detectedNativePanelResolutionForDisplayID:displayID];
  NSDictionary *panelResolution = [self nativePanelResolutionForDisplayID:displayID displayIDString:displayIDString];
  NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayIDString];
  NSDictionary *panelOverride = self.nativePanelResolutionOverrides[lifecycleKey] ?:
      self.nativePanelResolutionOverrides[displayIDString] ?: @{};
  BOOL hasPanelOverride = [self nativePanelResolutionOverrideExistsForDisplayIDString:displayIDString];
  BOOL flexibleScalingEnabled = [self flexibleScalingEnabledForDisplayIDString:displayIDString];
  NSUInteger detectedPanelWidth = [detectedPanelResolution[@"width"] unsignedIntegerValue];
  NSUInteger detectedPanelHeight = [detectedPanelResolution[@"height"] unsignedIntegerValue];
  NSUInteger panelWidth = [panelResolution[@"width"] unsignedIntegerValue];
  NSUInteger panelHeight = [panelResolution[@"height"] unsignedIntegerValue];
  NSUInteger overridePanelWidth = hasPanelOverride ? [panelOverride[@"width"] unsignedIntegerValue] : 0;
  NSUInteger overridePanelHeight = hasPanelOverride ? [panelOverride[@"height"] unsignedIntegerValue] : 0;
  BOOL overrideInstalled = self.overrideInstalledPaths[lifecycleKey].length > 0;
  BOOL overridePendingReboot = [self.overridePendingReboot[lifecycleKey] boolValue];
  BOOL overridePendingReinitialize = [self.overridePendingReinitialize[lifecycleKey] boolValue];
  NSString *nativePanelResolutionStatus = hasPanelOverride
      ? [NSString stringWithFormat:@"Override %lux%lu (detected %lux%lu)",
                                   (unsigned long)overridePanelWidth,
                                   (unsigned long)overridePanelHeight,
                                   (unsigned long)detectedPanelWidth,
                                   (unsigned long)detectedPanelHeight]
      : [NSString stringWithFormat:@"Detected %lux%lu",
                                   (unsigned long)detectedPanelWidth,
                                   (unsigned long)detectedPanelHeight];

  if (hasPanelOverride) {
    if (!overrideInstalled) {
      nativePanelResolutionStatus =
          [nativePanelResolutionStatus stringByAppendingString:@" - install required"];
    } else if (overridePendingReboot) {
      nativePanelResolutionStatus =
          [nativePanelResolutionStatus stringByAppendingString:@" - PC Restart required"];
    } else if (overridePendingReinitialize) {
      nativePanelResolutionStatus =
          [nativePanelResolutionStatus stringByAppendingString:@" - reload required"];
    }
  }

  NSString *flexibleScalingStatus = @"Disabled";

  if (flexibleScalingEnabled) {
    if (!overrideInstalled) {
      flexibleScalingStatus = @"Enabled - install required";
    } else if (overridePendingReboot) {
      flexibleScalingStatus = @"Enabled - PC Restart required";
    } else if (overridePendingReinitialize) {
      flexibleScalingStatus = @"Enabled - reload required";
    } else {
      flexibleScalingStatus = @"Enabled";
    }
  }

  return @{
    @"supportsEdidExport" : @(edidData.length > 0),
    @"edidBytes" : @(edidData.length),
    @"edidExportPath" : self.edidExportPaths[displayIDString] ?: @"",
    @"edidOverridePath" : self.edidOverridePaths[displayIDString] ?: @"",
    @"edidOverrideStatus" : self.edidOverrideStatus[displayIDString] ?: @"No override",
    @"overrideBundlePath" : self.overrideBundlePaths[displayIDString] ?: @"",
    @"overrideBundleStatus" : self.overrideBundleStatus[displayIDString] ?: @"No bundle",
    @"overrideInstalledPath" : self.overrideInstalledPaths[lifecycleKey] ?: @"",
    @"overrideBackupPath" : self.overrideBackupPaths[lifecycleKey] ?: @"",
    @"overrideInstalledHash" : self.overrideInstalledHashes[lifecycleKey] ?: @"",
    @"overrideBackupHash" : self.overrideBackupHashes[lifecycleKey] ?: @"",
    @"overridePendingReboot" : @(overridePendingReboot),
    @"overridePendingReinitialize" : @(overridePendingReinitialize),
    @"overrideLastError" : self.overrideLastErrors[lifecycleKey] ?: @"",
    @"nativePanelWidth" : @(panelWidth),
    @"nativePanelHeight" : @(panelHeight),
    @"nativePanelOverrideWidth" : @(overridePanelWidth),
    @"nativePanelOverrideHeight" : @(overridePanelHeight),
    @"nativePanelResolutionStatus" : nativePanelResolutionStatus,
    @"flexibleScalingEnabled" : @(flexibleScalingEnabled),
    @"flexibleScalingStatus" : flexibleScalingStatus,
    @"rotationRequest" : rotationRequest,
    @"rotationStatus" : self.rotationStatus[displayIDString] ?: @"Current",
    @"softConnectionState" : self.softConnectionStates[displayIDString] ?: @"connected",
    @"xdrUpscaleState" : self.xdrUpscaleStates[displayIDString] ?: @"disabled",
    @"lastOperation" : self.advancedOperations[displayIDString] ?: @"",
    @"lastOperationAt" : self.advancedOperationDates[displayIDString] ?: @"",
    @"customResolutions" : customResolutions,
  };
}


- (BOOL)overridePayloadExistsForDisplayIDString:(NSString *)displayID
{
  NSArray *customResolutions = [self customResolutionRequestsForDisplayIDString:displayID];
  NSString *edidOverridePath = self.edidOverridePaths[displayID] ?: @"";
  return customResolutions.count > 0 || edidOverridePath.length > 0 ||
      [self flexibleScalingEnabledForDisplayIDString:displayID] ||
      [self nativePanelResolutionOverrideExistsForDisplayIDString:displayID];
}


- (NSURL *)overrideTargetFileURLForDisplayIDString:(NSString *)displayID
{
  if ([displayID hasPrefix:@"/"]) {
    NSLog(@"[macDisplayBar] Display override target rejected: displayID=%@ reason=absolute displayID not allowed",
          displayID);
    return nil;
  }

  CGDirectDisplayID directDisplayID = (CGDirectDisplayID)displayID.integerValue;
  uint32_t vendorID = CGDisplayVendorNumber(directDisplayID);
  uint32_t productID = CGDisplayModelNumber(directDisplayID);

  if (vendorID == 0 && productID == 0) {
    return nil;
  }

  NSString *vendorDirectoryName = [NSString stringWithFormat:@"DisplayVendorID-%x", vendorID];
  NSString *productFileName = [NSString stringWithFormat:@"DisplayProductID-%x", productID];
  return [[[NSURL fileURLWithPath:RCTDisplayOverrideInstallDirectory isDirectory:YES]
      URLByAppendingPathComponent:vendorDirectoryName
		                      isDirectory:YES] URLByAppendingPathComponent:productFileName];
}


- (NSURL *)overrideTargetFileURLForLifecycleKey:(NSString *)lifecycleKey
{
  if (![lifecycleKey hasPrefix:@"/"]) {
    return [self overrideTargetFileURLForDisplayIDString:lifecycleKey];
  }

  NSString *overrideDirectory = [RCTDisplayOverrideInstallDirectory stringByStandardizingPath];
  NSString *targetPath = [lifecycleKey stringByStandardizingPath];
  NSString *requiredPrefix = [overrideDirectory hasSuffix:@"/"]
      ? overrideDirectory
      : [overrideDirectory stringByAppendingString:@"/"];

  if (![targetPath hasPrefix:requiredPrefix]) {
    NSLog(@"[macDisplayBar] Display override lifecycle target rejected: target=%@ reason=outside display override directory",
          targetPath);
    return nil;
  }

  return [NSURL fileURLWithPath:targetPath];
}


- (NSString *)overrideLifecycleKeyForDisplayIDString:(NSString *)displayID
{
  NSURL *targetURL = [self overrideTargetFileURLForDisplayIDString:displayID];
  return targetURL.path.length > 0 ? targetURL.path : displayID;
}


- (NSString *)backupPathForOverrideTargetURL:(NSURL *)targetURL displayIDString:(NSString *)displayID
{
  NSString *safeDisplayID = MDBSafeFileNameComponent(displayID, @"display");
  NSString *backupFileName =
      [NSString stringWithFormat:@"%@-%@-%@.backup",
                                 targetURL.lastPathComponent ?: @"DisplayProductID",
                                 safeDisplayID,
                                 [[NSUUID UUID] UUIDString]];
  NSURL *baseDirectoryURL =
      [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject
          URLByAppendingPathComponent:@"MacDisplayBar/Overrides/Backups"
                          isDirectory:YES];
  NSURL *backupURL = [baseDirectoryURL URLByAppendingPathComponent:backupFileName];
  NSError *directoryError = nil;

  [[NSFileManager defaultManager] createDirectoryAtURL:baseDirectoryURL
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:&directoryError];

  return directoryError == nil ? backupURL.path : @"";
}


- (void)clearRebootPendingStatesAfterSystemBoot
{
  NSTimeInterval bootTime = MDBSystemBootTime();

  if (bootTime <= 0) {
    return;
  }

  for (NSString *displayID in self.overrideInstallTimes.allKeys) {
    NSNumber *installTime = self.overrideInstallTimes[displayID];

    if (installTime.doubleValue > 0 && installTime.doubleValue < bootTime) {
      [self.overridePendingReboot removeObjectForKey:displayID];
      [self.overridePendingReinitialize removeObjectForKey:displayID];
    }
  }
}


- (void)persistOverrideLifecycleStateForDisplayID:(NSString *)displayID
{
  (void)displayID;
  [[NSUserDefaults standardUserDefaults] setObject:self.overrideBundlePaths
                                            forKey:RCTDisplayOverrideBundlePathsDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.overrideBundleStatus
                                            forKey:RCTDisplayOverrideBundleStatusDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.overrideInstalledPaths
                                            forKey:RCTDisplayOverrideInstalledPathsDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.overrideBackupPaths
                                            forKey:RCTDisplayOverrideBackupPathsDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.overrideInstalledHashes
                                            forKey:RCTDisplayOverrideInstalledHashesDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.overrideBackupHashes
                                            forKey:RCTDisplayOverrideBackupHashesDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.overridePendingReboot
                                            forKey:RCTDisplayOverridePendingRebootDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.overridePendingReinitialize
                                            forKey:RCTDisplayOverridePendingReinitializeDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.overrideLastErrors
                                            forKey:RCTDisplayOverrideLastErrorsDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.overrideInstallTimes
                                            forKey:RCTDisplayOverrideInstallTimesDefaultsKey];
}


- (void)persistNativePanelResolutionState
{
  [[NSUserDefaults standardUserDefaults] setObject:self.nativePanelResolutionOverrides
                                            forKey:RCTDisplayNativePanelResolutionOverridesDefaultsKey];
  [[NSUserDefaults standardUserDefaults] setObject:self.flexibleScalingEnabled
                                            forKey:RCTDisplayFlexibleScalingDefaultsKey];
}

