- (BOOL)generatedHiDpiInstallTargetIsAllowedForDisplayID:(CGDirectDisplayID)displayID
                                                   width:(NSUInteger)width
                                                  height:(NSUInteger)height
                                             refreshRate:(double)refreshRate
{
  NSDictionary *options = @{(__bridge NSString *)kCGDisplayShowDuplicateLowResolutionModes : @YES};
  CFArrayRef copiedModes = CGDisplayCopyAllDisplayModes(displayID, (__bridge CFDictionaryRef)options);

  if (copiedModes == NULL) {
    return NO;
  }

  NSArray *modes = CFBridgingRelease(copiedModes);
  NSUInteger maxStandardWidth = 0;
  NSUInteger maxStandardHeight = 0;
  NSUInteger maxStandardArea = 0;
  BOOL targetStandardModeExists = NO;
  BOOL targetIsMaxStandardResolution = NO;

  for (id item in modes) {
    CGDisplayModeRef mode = (__bridge CGDisplayModeRef)item;
    NSUInteger modeWidth = CGDisplayModeGetWidth(mode);
    NSUInteger modeHeight = CGDisplayModeGetHeight(mode);
    BOOL modeIsHiDpi = CGDisplayModeGetPixelWidth(mode) > modeWidth;

    if (modeIsHiDpi) {
      continue;
    }

    NSUInteger area = modeWidth * modeHeight;
    if (area > maxStandardArea) {
      maxStandardArea = area;
      maxStandardWidth = modeWidth;
      maxStandardHeight = modeHeight;
    }

    targetStandardModeExists = targetStandardModeExists ||
        (modeWidth == width &&
         modeHeight == height &&
         fabs(CGDisplayModeGetRefreshRate(mode) - refreshRate) < 0.5);
  }

  targetIsMaxStandardResolution = width == maxStandardWidth && height == maxStandardHeight;

  return targetStandardModeExists &&
      targetIsMaxStandardResolution &&
      [self isSub4KHiDpiUnlockTargetWithWidth:maxStandardWidth height:maxStandardHeight] &&
      [self isSub4KHiDpiUnlockTargetWithWidth:width height:height];
}


- (BOOL)applyDisplayModeForDisplayID:(CGDirectDisplayID)displayID
                               modeID:(NSString *)modeID
                      displayIDString:(NSString *)displayIDString
{
  NSDictionary *privateDisplayMode = [self privateDisplayModeComponentsFromModeID:modeID];

  if (privateDisplayMode != nil) {
    NSUInteger modeNumber = [privateDisplayMode[@"modeNumber"] unsignedIntegerValue];
    NSUInteger width = [privateDisplayMode[@"width"] unsignedIntegerValue];
    NSUInteger height = [privateDisplayMode[@"height"] unsignedIntegerValue];
    double refreshRate = [privateDisplayMode[@"refreshRate"] doubleValue];
    double density = [privateDisplayMode[@"density"] doubleValue];
    RCTCGSConfigureDisplayModeFn configureMode =
        (RCTCGSConfigureDisplayModeFn)[self privateDisplaySymbolNamed:"CGSConfigureDisplayMode"];

    if (configureMode == NULL) {
      self.modeStatus[displayIDString] = @"Unavailable";
      self.modeErrors[displayIDString] = @"Private display mode API unavailable";
      NSLog(@"[macDisplayBar] Private CGS display mode apply unavailable: displayID=%@ modeID=%@ modeNumber=%lu",
            displayIDString,
            modeID,
            (unsigned long)modeNumber);
      return NO;
    }

    if (![self privateDisplayModeExistsForDisplayID:displayID
                                        modeNumber:modeNumber
                                             width:width
                                            height:height
                                       refreshRate:refreshRate
                                           density:density
                                   displayIDString:displayIDString]) {
      self.modeStatus[displayIDString] = @"Not found";
      self.modeErrors[displayIDString] = @"Private display mode no longer available";
      return NO;
    }

    CGDisplayConfigRef config = NULL;
    CGError beginError = CGBeginDisplayConfiguration(&config);

    if (beginError != kCGErrorSuccess || config == NULL) {
      self.modeStatus[displayIDString] = @"Failed";
      self.modeErrors[displayIDString] = [NSString stringWithFormat:@"Private display mode configuration failed: %d", beginError];
      return NO;
    }

    CGError configureError = configureMode(config, displayID, (int)modeNumber);

    if (configureError != kCGErrorSuccess) {
      CGCancelDisplayConfiguration(config);
      self.modeStatus[displayIDString] = @"Failed";
      self.modeErrors[displayIDString] = [NSString stringWithFormat:@"Private display mode configure failed: %d", configureError];
      NSLog(@"[macDisplayBar] Private CGS display mode configure failed: displayID=%@ modeID=%@ modeNumber=%lu result=%d",
            displayIDString,
            modeID,
            (unsigned long)modeNumber,
            configureError);
      return NO;
    }

    CGError result = CGCompleteDisplayConfiguration(config, kCGConfigurePermanently);

    if (result == kCGErrorSuccess) {
      self.modeStatus[displayIDString] = @"Applied";
      [self.modeErrors removeObjectForKey:displayIDString];
      NSLog(@"[macDisplayBar] Private CGS display mode applied: displayID=%@ modeID=%@ modeNumber=%lu width=%lu height=%lu refreshRate=%.3f density=%.3f",
            displayIDString,
            modeID,
            (unsigned long)modeNumber,
            (unsigned long)width,
            (unsigned long)height,
            refreshRate,
            density);
      return YES;
    }

    self.modeStatus[displayIDString] = @"Failed";
    self.modeErrors[displayIDString] = [NSString stringWithFormat:@"Private display mode apply failed: %d", result];
    NSLog(@"[macDisplayBar] Private CGS display mode apply failed: displayID=%@ modeID=%@ modeNumber=%lu result=%d",
          displayIDString,
          modeID,
          (unsigned long)modeNumber,
          result);
    return NO;
  }

  NSDictionary *generatedHiDpiMode = [self generatedHiDpiModeComponentsFromModeID:modeID];

  if (generatedHiDpiMode != nil) {
    NSUInteger width = [generatedHiDpiMode[@"width"] unsignedIntegerValue];
    NSUInteger height = [generatedHiDpiMode[@"height"] unsignedIntegerValue];
    double refreshRate = [generatedHiDpiMode[@"refreshRate"] doubleValue];
    CGError applyError = kCGErrorSuccess;

    NSLog(@"[macDisplayBar] Generated HiDPI install/apply start: displayID=%@ modeID=%@ width=%lu height=%lu refreshRate=%.3f",
          displayIDString,
          modeID,
          (unsigned long)width,
          (unsigned long)height,
          refreshRate);

    if (![self generatedHiDpiInstallTargetIsAllowedForDisplayID:displayID
                                                          width:width
                                                         height:height
                                                    refreshRate:refreshRate]) {
      self.modeStatus[displayIDString] = @"HiDPI install unavailable";
      self.modeErrors[displayIDString] = @"Generated HiDPI target is not available for this display";
      NSLog(@"[macDisplayBar] Generated HiDPI install rejected by target policy: displayID=%@ modeID=%@ width=%lu height=%lu refreshRate=%.3f",
            displayIDString,
            modeID,
            (unsigned long)width,
            (unsigned long)height,
            refreshRate);
      return NO;
    }

    BOOL didApplyMode = [self applyAvailableHiDpiModeForDisplayID:displayID
                                                             width:width
                                                            height:height
                                                       refreshRate:refreshRate
                                                             error:&applyError];

    if (didApplyMode) {
      self.modeStatus[displayIDString] = @"Applied";
      [self.modeErrors removeObjectForKey:displayIDString];
      NSLog(@"[macDisplayBar] Generated HiDPI exact mode applied: displayID=%@ modeID=%@ width=%lu height=%lu refreshRate=%.3f",
            displayIDString,
            modeID,
            (unsigned long)width,
            (unsigned long)height,
            refreshRate);
      return YES;
    }

    BOOL recipeIsExposed = [self exposedGeneratedHiDpiRecipeExistsForDisplayID:displayID width:width height:height];
    BOOL installedOneKeyRecipe = [self installedOneKeyHiDpiRecipeExistsForDisplayID:displayID width:width height:height];

    if (recipeIsExposed && installedOneKeyRecipe) {
      NSString *fallbackError = nil;
      BOOL didCreateFallback = [self createVirtualHiDpiFallbackForDisplayIDString:displayIDString
                                                                            width:width
                                                                           height:height
                                                                      refreshRate:refreshRate
                                                                     statusReason:@"recipe-exposed-exact-unavailable"
                                                                     errorMessage:&fallbackError];

      if (didCreateFallback) {
        self.modeStatus[displayIDString] = [fallbackError isEqualToString:@"Virtual HiDPI fallback creating"]
            ? @"HiDPI virtual fallback creating"
            : @"HiDPI virtual fallback mirrored";
        [self.modeErrors removeObjectForKey:displayIDString];
        NSLog(@"[macDisplayBar] Generated HiDPI virtual fallback accepted because exact requested mode is unavailable: displayID=%@ modeID=%@ width=%lu height=%lu refreshRate=%.3f status=%@ applyError=%d",
              displayIDString,
              modeID,
              (unsigned long)width,
              (unsigned long)height,
              refreshRate,
              self.modeStatus[displayIDString],
              applyError);
        return YES;
      }

      self.modeStatus[displayIDString] = @"HiDPI settings installed - exact mode unavailable";
      [self.modeErrors removeObjectForKey:displayIDString];
      NSLog(@"[macDisplayBar] Generated HiDPI one-key recipe already installed and exposed; exact requested refresh is not exposed by macOS: displayID=%@ modeID=%@ width=%lu height=%lu refreshRate=%.3f applyError=%d",
            displayIDString,
            modeID,
            (unsigned long)width,
            (unsigned long)height,
            refreshRate,
            applyError);
      return NO;
    }

    if (recipeIsExposed && !installedOneKeyRecipe) {
      NSLog(@"[macDisplayBar] Generated HiDPI recipe is exposed but installed override is not one-key complete; rewriting recipe: displayID=%@ modeID=%@ width=%lu height=%lu refreshRate=%.3f applyError=%d",
            displayIDString,
            modeID,
            (unsigned long)width,
            (unsigned long)height,
            refreshRate,
            applyError);
    }

    NSArray<NSDictionary *> *generatedCustomResolutions =
        [self generatedHiDpiCustomResolutionRequestsWithWidth:width
                                                       height:height
                                                  refreshRate:refreshRate];
    NSString *bundlePath = [self writeOverrideBundleForDisplayIDString:displayIDString
                                                           includeEdid:NO
                                                     customResolutions:generatedCustomResolutions];
    NSString *installError = nil;
    BOOL didInstallBundle = NO;
    BOOL didMutateInstall = NO;
    NSString *lifecycleKey = [self overrideLifecycleKeyForDisplayIDString:displayIDString];
    BOOL hadManagedInstall = self.overrideInstalledHashes[lifecycleKey].length > 0;

    NSLog(@"[macDisplayBar] Generated HiDPI override bundle prepared: displayID=%@ modeID=%@ bundlePath=%@ customResolutionCount=%lu",
          displayIDString,
          modeID,
          bundlePath.length > 0 ? bundlePath : @"",
          (unsigned long)generatedCustomResolutions.count);

    if (bundlePath.length > 0) {
      self.overrideBundlePaths[displayIDString] = bundlePath;
      didInstallBundle = [self installOverrideBundleAtPath:bundlePath
                                           displayIDString:lifecycleKey
                                                 didMutate:&didMutateInstall
                                              errorMessage:&installError];
      NSLog(@"[macDisplayBar] Generated HiDPI override install result: displayID=%@ modeID=%@ didInstall=%@ error=%@",
            displayIDString,
            modeID,
            didInstallBundle ? @"YES" : @"NO",
            installError ?: @"");
      self.overrideBundleStatus[displayIDString] = didInstallBundle ? @"Installed" : @"Install failed";
      if (didInstallBundle) {
        if (didMutateInstall || hadManagedInstall || self.overrideInstalledHashes[lifecycleKey].length > 0) {
          NSURL *targetFileURL = [self overrideTargetFileURLForDisplayIDString:displayIDString];

          if (targetFileURL.path.length > 0) {
            self.overrideInstalledPaths[lifecycleKey] = targetFileURL.path;
            self.overrideInstalledHashes[lifecycleKey] = MDBSHA256FileHash(targetFileURL.path);
          }
        } else {
          self.overrideBundleStatus[displayIDString] = @"Installed externally";
        }

        if (didMutateInstall) {
          self.overridePendingReboot[lifecycleKey] = @YES;
          self.overridePendingReinitialize[lifecycleKey] = @YES;
          self.overrideInstallTimes[lifecycleKey] = @([[NSDate date] timeIntervalSince1970]);
        }
        [self.overrideLastErrors removeObjectForKey:lifecycleKey];
      } else if (installError.length > 0) {
        self.overrideLastErrors[lifecycleKey] = installError;
      } else {
        self.overrideLastErrors[lifecycleKey] = @"Display override install failed";
      }
      [self persistOverrideLifecycleStateForDisplayID:lifecycleKey];
      [self recordAdvancedOperation:didInstallBundle ? @"Generated HiDPI settings installed"
                                                     : @"Generated HiDPI settings install failed"
                         displayID:displayIDString];

      if (!didApplyMode && didInstallBundle) {
        for (NSUInteger attempt = 0; attempt < 3 && !didApplyMode; attempt++) {
          if (attempt > 0) {
            [NSThread sleepForTimeInterval:0.25];
          }

          NSLog(@"[macDisplayBar] Generated HiDPI exact apply retry: displayID=%@ modeID=%@ attempt=%lu",
                displayIDString,
                modeID,
                (unsigned long)(attempt + 1));
          didApplyMode = [self applyAvailableHiDpiModeForDisplayID:displayID
                                                             width:width
                                                            height:height
                                                       refreshRate:refreshRate
                                                             error:&applyError];
        }
      }
    }

    if (didApplyMode) {
      self.modeStatus[displayIDString] = @"Applied";
      [self.modeErrors removeObjectForKey:displayIDString];
      NSLog(@"[macDisplayBar] Generated HiDPI exact mode applied after install: displayID=%@ modeID=%@ width=%lu height=%lu refreshRate=%.3f",
            displayIDString,
            modeID,
            (unsigned long)width,
            (unsigned long)height,
            refreshRate);
      return YES;
    }

    if (didInstallBundle) {
      BOOL recipeExposedAfterInstall = [self exposedGeneratedHiDpiRecipeExistsForDisplayID:displayID
                                                                                    width:width
                                                                                   height:height];
      if (!recipeExposedAfterInstall) {
        self.modeStatus[displayIDString] = @"HiDPI settings installed - PC Restart required";
        [self.modeErrors removeObjectForKey:displayIDString];
        NSLog(@"[macDisplayBar] Generated HiDPI install completed but recipe is not exposed yet; PC restart required before virtual fallback: displayID=%@ modeID=%@ width=%lu height=%lu refreshRate=%.3f applyError=%d",
              displayIDString,
              modeID,
              (unsigned long)width,
              (unsigned long)height,
              refreshRate,
              applyError);
        return YES;
      }

      NSString *fallbackError = nil;
      BOOL didCreateFallback = [self createVirtualHiDpiFallbackForDisplayIDString:displayIDString
                                                                            width:width
                                                                           height:height
                                                                      refreshRate:refreshRate
                                                                     statusReason:@"install-completed-exact-unavailable"
                                                                     errorMessage:&fallbackError];

      if (didCreateFallback) {
        self.modeStatus[displayIDString] = [fallbackError isEqualToString:@"Virtual HiDPI fallback creating"]
            ? @"HiDPI virtual fallback creating"
            : @"HiDPI virtual fallback mirrored";
        [self.modeErrors removeObjectForKey:displayIDString];
      } else {
        self.modeStatus[displayIDString] =
            recipeExposedAfterInstall ? @"HiDPI settings installed - exact mode unavailable"
                                      : @"HiDPI settings installed - PC Restart required";
        [self.modeErrors removeObjectForKey:displayIDString];
      }

      NSLog(@"[macDisplayBar] Generated HiDPI install completed without exact requested refresh: displayID=%@ modeID=%@ width=%lu height=%lu refreshRate=%.3f recipeExposed=%@ applyError=%d",
            displayIDString,
            modeID,
            (unsigned long)width,
            (unsigned long)height,
            refreshRate,
	            recipeExposedAfterInstall ? @"YES" : @"NO",
	            applyError);
	      return YES;
	    }

    if (bundlePath.length > 0) {
      self.modeStatus[displayIDString] = @"Failed";
      self.modeErrors[displayIDString] = installError ?: @"HiDPI settings install failed";
      return NO;
    }

    self.modeStatus[displayIDString] = @"Failed";
    self.modeErrors[displayIDString] =
        [NSString stringWithFormat:@"HiDPI mode apply failed: %d", applyError];
    return NO;
  }

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


- (BOOL)applyAvailableHiDpiModeForDisplayID:(CGDirectDisplayID)displayID
                                       width:(NSUInteger)width
                                      height:(NSUInteger)height
                                 refreshRate:(double)refreshRate
                                       error:(CGError *)error
{
  NSDictionary *options = @{(__bridge NSString *)kCGDisplayShowDuplicateLowResolutionModes : @YES};
  CFArrayRef copiedModes = CGDisplayCopyAllDisplayModes(displayID, (__bridge CFDictionaryRef)options);

  if (copiedModes == NULL) {
    if (error != NULL) {
      *error = kCGErrorFailure;
    }
    return NO;
  }

  NSArray *modes = CFBridgingRelease(copiedModes);
  CGDisplayModeRef hiDpiMode = NULL;
  NSUInteger sameSizeCount = 0;
  NSUInteger sameSizeSameRefreshCount = 0;
  NSUInteger sameSizeHiDpiCount = 0;
  NSMutableArray<NSString *> *sameSizeModeDescriptions = [NSMutableArray new];
  NSMutableArray<NSString *> *nearNativeHiDpiDescriptions = [NSMutableArray new];

  for (id item in modes) {
    CGDisplayModeRef candidate = (__bridge CGDisplayModeRef)item;
    BOOL sameSize = CGDisplayModeGetWidth(candidate) == width && CGDisplayModeGetHeight(candidate) == height;
    BOOL sameRefresh = refreshRate <= 0 || fabs(CGDisplayModeGetRefreshRate(candidate) - refreshRate) < 0.5;
    BOOL isHiDpi = CGDisplayModeGetPixelWidth(candidate) > CGDisplayModeGetWidth(candidate);
    double targetAspectRatio = height > 0 ? (double)width / (double)height : 0;
    double candidateAspectRatio = CGDisplayModeGetHeight(candidate) > 0
        ? (double)CGDisplayModeGetWidth(candidate) / (double)CGDisplayModeGetHeight(candidate)
        : 0;
    BOOL nearNativeHiDpi =
        isHiDpi &&
        !sameSize &&
        CGDisplayModeGetWidth(candidate) < width &&
        CGDisplayModeGetWidth(candidate) >= (size_t)llround((double)width * 0.97) &&
        fabs(candidateAspectRatio - targetAspectRatio) < 0.02;

    if (sameSize) {
      sameSizeCount++;

      if (sameRefresh) {
        sameSizeSameRefreshCount++;
      }

      if (isHiDpi) {
        sameSizeHiDpiCount++;
      }

      if (sameSizeModeDescriptions.count < 8) {
        [sameSizeModeDescriptions addObject:[NSString stringWithFormat:@"%zux%zu->%zux%zu@%.3f %@",
                                             CGDisplayModeGetWidth(candidate),
                                             CGDisplayModeGetHeight(candidate),
                                             CGDisplayModeGetPixelWidth(candidate),
                                             CGDisplayModeGetPixelHeight(candidate),
                                             CGDisplayModeGetRefreshRate(candidate),
                                             isHiDpi ? @"HiDPI" : @"1x"]];
      }
    }

    if (nearNativeHiDpi && nearNativeHiDpiDescriptions.count < 8) {
      [nearNativeHiDpiDescriptions addObject:[NSString stringWithFormat:@"%zux%zu->%zux%zu@%.3f HiDPI",
                                             CGDisplayModeGetWidth(candidate),
                                             CGDisplayModeGetHeight(candidate),
                                             CGDisplayModeGetPixelWidth(candidate),
                                             CGDisplayModeGetPixelHeight(candidate),
                                             CGDisplayModeGetRefreshRate(candidate)]];
    }

    if (!sameSize || !sameRefresh) {
      continue;
    }

    if (isHiDpi) {
      hiDpiMode = candidate;
      break;
    }
  }

  if (hiDpiMode == NULL) {
    NSLog(@"[macDisplayBar] Generated HiDPI exact mode not found: displayID=%u width=%lu height=%lu refreshRate=%.3f modeCount=%lu sameSize=%lu sameSizeSameRefresh=%lu sameSizeHiDPI=%lu sameSizeModes=%@ nearNativeHiDPI=%@",
          displayID,
          (unsigned long)width,
          (unsigned long)height,
          refreshRate,
          (unsigned long)modes.count,
          (unsigned long)sameSizeCount,
          (unsigned long)sameSizeSameRefreshCount,
          (unsigned long)sameSizeHiDpiCount,
          [sameSizeModeDescriptions componentsJoinedByString:@" | "],
          [nearNativeHiDpiDescriptions componentsJoinedByString:@" | "]);
    if (error != NULL) {
      *error = kCGErrorIllegalArgument;
    }
    return NO;
  }

  CGError result = CGDisplaySetDisplayMode(displayID, hiDpiMode, NULL);

  if (error != NULL) {
    *error = result;
  }

  if (result != kCGErrorSuccess) {
    return NO;
  }

  return YES;
}

