- (NSString *)privateDisplayModeIDWithModeNumber:(NSUInteger)modeNumber
                                           width:(NSUInteger)width
                                          height:(NSUInteger)height
                                     refreshRate:(double)refreshRate
                                         density:(double)density
{
  return [NSString stringWithFormat:@"%@:%lu:%lu:%lu:%.3f:%.3f",
                                    RCTPrivateDisplayModeIDPrefix,
                                    (unsigned long)modeNumber,
                                    (unsigned long)width,
                                    (unsigned long)height,
                                    refreshRate,
                                    density];
}


- (void *)privateDisplaySymbolNamed:(const char *)symbolName
{
#if RCTDISPLAY_ENABLE_PRIVATE_CGS_MODES
  void *symbol = dlsym(RTLD_DEFAULT, symbolName);

  if (symbol != NULL) {
    return symbol;
  }

  static void *skyLightHandle = NULL;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    skyLightHandle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY | RTLD_LOCAL);
  });

  return skyLightHandle != NULL ? dlsym(skyLightHandle, symbolName) : NULL;
#else
  (void)symbolName;
  return NULL;
#endif
}


- (NSDictionary *)privateDisplayModeComponentsFromModeID:(NSString *)modeID
{
  NSArray<NSString *> *components = [modeID componentsSeparatedByString:@":"];

  if (components.count != 6 || ![components[0] isEqualToString:RCTPrivateDisplayModeIDPrefix]) {
    return nil;
  }

  NSUInteger modeNumber = (NSUInteger)components[1].integerValue;
  NSUInteger width = (NSUInteger)components[2].integerValue;
  NSUInteger height = (NSUInteger)components[3].integerValue;
  double refreshRate = components[4].doubleValue;
  double density = components[5].doubleValue;

  if (width == 0 || height == 0) {
    return nil;
  }

  return @{
    @"modeNumber" : @(modeNumber),
    @"width" : @(width),
    @"height" : @(height),
    @"refreshRate" : @(refreshRate),
    @"density" : @(density),
  };
}


- (BOOL)privateDisplayModeExistsForDisplayID:(CGDirectDisplayID)displayID
                                  modeNumber:(NSUInteger)modeNumber
                                       width:(NSUInteger)width
                                      height:(NSUInteger)height
                                 refreshRate:(double)refreshRate
                                     density:(double)density
                             displayIDString:(NSString *)displayIDString
{
  RCTCGSGetNumberOfDisplayModesFn getModeCount =
      (RCTCGSGetNumberOfDisplayModesFn)[self privateDisplaySymbolNamed:"CGSGetNumberOfDisplayModes"];
  RCTCGSGetDisplayModeDescriptionOfLengthFn getModeDescription =
      (RCTCGSGetDisplayModeDescriptionOfLengthFn)[self privateDisplaySymbolNamed:"CGSGetDisplayModeDescriptionOfLength"];

  if (getModeCount == NULL || getModeDescription == NULL) {
    return NO;
  }

  int modeCount = 0;
  getModeCount(displayID, &modeCount);

  if (modeCount <= 0 || modeCount > RCTCGSMaxDisplayModeCount) {
    NSLog(@"[macDisplayBar] Private CGS display mode validation skipped: displayID=%@ modeCount=%d",
          displayIDString,
          modeCount);
    return NO;
  }

  for (int index = 0; index < modeCount; index++) {
    RCTCGSDisplayMode mode = {};
    getModeDescription(displayID, index, &mode, (int)sizeof(RCTCGSDisplayMode));
    double candidateRefreshRate = mode.freq > 0 ? (double)mode.freq : 0;
    double candidateDensity = mode.density > 0 ? mode.density : 1;

    if (mode.modeNumber == modeNumber &&
        mode.width == width &&
        mode.height == height &&
        fabs(candidateRefreshRate - refreshRate) < 0.5 &&
        fabs(candidateDensity - density) < 0.01) {
      return YES;
    }
  }

  NSLog(@"[macDisplayBar] Private CGS display mode validation failed: displayID=%@ modeNumber=%lu width=%lu height=%lu refreshRate=%.3f density=%.3f modeCount=%d",
        displayIDString,
        (unsigned long)modeNumber,
        (unsigned long)width,
        (unsigned long)height,
        refreshRate,
        density,
        modeCount);
  return NO;
}


- (NSString *)modeSemanticKeyForWidth:(NSUInteger)width
                                height:(NSUInteger)height
                           refreshRate:(double)refreshRate
                               isHiDpi:(BOOL)isHiDpi
{
  return [NSString stringWithFormat:@"%lu:%lu:%.3f:%@",
                                    (unsigned long)width,
                                    (unsigned long)height,
                                    refreshRate,
                                    isHiDpi ? @"hidpi" : @"lodpi"];
}


- (NSArray<NSDictionary *> *)privateDisplayModeDictionariesForDisplayID:(CGDirectDisplayID)displayID
                                                          currentModeID:(NSString *)currentModeID
                                                   seenSemanticModeKeys:(NSMutableSet<NSString *> *)seenSemanticModeKeys
                                                        displayIDString:(NSString *)displayIDString
{
  RCTCGSGetNumberOfDisplayModesFn getModeCount =
      (RCTCGSGetNumberOfDisplayModesFn)[self privateDisplaySymbolNamed:"CGSGetNumberOfDisplayModes"];
  RCTCGSGetDisplayModeDescriptionOfLengthFn getModeDescription =
      (RCTCGSGetDisplayModeDescriptionOfLengthFn)[self privateDisplaySymbolNamed:"CGSGetDisplayModeDescriptionOfLength"];
  RCTCGSGetCurrentDisplayModeFn getCurrentMode =
      (RCTCGSGetCurrentDisplayModeFn)[self privateDisplaySymbolNamed:"CGSGetCurrentDisplayMode"];
  RCTCGSConfigureDisplayModeFn configureMode =
      (RCTCGSConfigureDisplayModeFn)[self privateDisplaySymbolNamed:"CGSConfigureDisplayMode"];

  if (getModeCount == NULL || getModeDescription == NULL || configureMode == NULL) {
    NSLog(@"[macDisplayBar] Private CGS display mode APIs unavailable: displayID=%@",
          displayIDString);
    return @[];
  }

  int modeCount = 0;
  getModeCount(displayID, &modeCount);

  if (modeCount <= 0) {
    NSLog(@"[macDisplayBar] Private CGS display mode list empty: displayID=%@ modeCount=%d",
          displayIDString,
          modeCount);
    return @[];
  }

  if (modeCount > RCTCGSMaxDisplayModeCount) {
    NSLog(@"[macDisplayBar] Private CGS display mode list rejected: displayID=%@ modeCount=%d max=%d",
          displayIDString,
          modeCount,
          RCTCGSMaxDisplayModeCount);
    return @[];
  }

  int currentModeNumber = -1;

  if (getCurrentMode != NULL) {
    getCurrentMode(displayID, &currentModeNumber);
  }

  NSMutableArray<NSDictionary *> *modeDictionaries = [NSMutableArray new];
  NSUInteger hiddenHiDpiCount = 0;
  NSUInteger duplicateCount = 0;

  for (int index = 0; index < modeCount; index++) {
    RCTCGSDisplayMode mode = {};
    getModeDescription(displayID, index, &mode, (int)sizeof(RCTCGSDisplayMode));

    NSUInteger width = mode.width;
    NSUInteger height = mode.height;
    double refreshRate = mode.freq > 0 ? (double)mode.freq : 0;
    double density = mode.density > 0 ? mode.density : 1;
    BOOL isHiDpi = density > 1.0;

    if (width == 0 || height == 0) {
      continue;
    }

    NSString *semanticKey = [self modeSemanticKeyForWidth:width
                                                   height:height
                                              refreshRate:refreshRate
                                                  isHiDpi:isHiDpi];

    if ([seenSemanticModeKeys containsObject:semanticKey]) {
      duplicateCount++;
      continue;
    }

    [seenSemanticModeKeys addObject:semanticKey];

    NSString *modeID = [self privateDisplayModeIDWithModeNumber:mode.modeNumber
                                                          width:width
                                                         height:height
                                                    refreshRate:refreshRate
                                                        density:density];
    [modeDictionaries addObject:@{
      @"id" : modeID,
      @"width" : @(width),
      @"height" : @(height),
      @"refreshRate" : @(refreshRate),
      @"isHiDpi" : @(isHiDpi),
      @"isCurrent" : @(mode.modeNumber == (uint32_t)currentModeNumber || [modeID isEqualToString:currentModeID]),
      @"isFavorite" : @([self modeIDIsFavorite:modeID displayIDString:displayIDString]),
      @"source" : @"cgs",
    }];

    if (isHiDpi) {
      hiddenHiDpiCount++;
    }
  }

  NSLog(@"[macDisplayBar] Private CGS display modes scanned: displayID=%@ modeCount=%d added=%lu hiddenHiDpi=%lu duplicate=%lu currentMode=%d",
        displayIDString,
        modeCount,
        (unsigned long)modeDictionaries.count,
        (unsigned long)hiddenHiDpiCount,
        (unsigned long)duplicateCount,
        currentModeNumber);

  return modeDictionaries;
}

