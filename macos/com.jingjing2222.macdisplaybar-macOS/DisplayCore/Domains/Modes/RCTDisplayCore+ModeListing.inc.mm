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
  NSMutableSet<NSString *> *seenHiDpiResolutionKeys = [NSMutableSet new];
  NSMutableSet<NSString *> *seenHiDpiRefreshKeys = [NSMutableSet new];
  NSMutableSet<NSString *> *seenSemanticModeKeys = [NSMutableSet new];
  NSMutableDictionary<NSString *, NSDictionary *> *bestStandardModeByResolution = [NSMutableDictionary new];
  NSMutableDictionary<NSString *, NSDictionary *> *standardModeByResolutionRefresh = [NSMutableDictionary new];
  NSString *displayIDString = [NSString stringWithFormat:@"%u", displayID];
  NSUInteger maxStandardWidth = 0;
  NSUInteger maxStandardHeight = 0;
  NSUInteger maxStandardArea = 0;

  for (id item in modes) {
    CGDisplayModeRef candidate = (__bridge CGDisplayModeRef)item;
    NSString *modeID = [self modeIDForMode:candidate];

    if ([seenModeIDs containsObject:modeID]) {
      continue;
    }

    [seenModeIDs addObject:modeID];
    NSMutableDictionary *modeDictionary = [[self dictionaryForMode:candidate currentModeID:currentModeID] mutableCopy];
    modeDictionary[@"isFavorite"] = @([self modeIDIsFavorite:modeID displayIDString:displayIDString]);
    modeDictionary[@"source"] = @"coregraphics";
    [modeDictionaries addObject:modeDictionary];

    NSString *resolutionKey = MDBIntegerPairKey([modeDictionary[@"width"] unsignedIntegerValue],
                                                [modeDictionary[@"height"] unsignedIntegerValue]);
    [seenSemanticModeKeys addObject:[self modeSemanticKeyForWidth:[modeDictionary[@"width"] unsignedIntegerValue]
                                                           height:[modeDictionary[@"height"] unsignedIntegerValue]
                                                      refreshRate:[modeDictionary[@"refreshRate"] doubleValue]
                                                          isHiDpi:[modeDictionary[@"isHiDpi"] boolValue]]];

    if ([modeDictionary[@"isHiDpi"] boolValue]) {
      [seenHiDpiResolutionKeys addObject:resolutionKey];
      [seenHiDpiRefreshKeys addObject:MDBIntegerPairRefreshKey([modeDictionary[@"width"] unsignedIntegerValue],
                                                               [modeDictionary[@"height"] unsignedIntegerValue],
                                                               [modeDictionary[@"refreshRate"] doubleValue])];
      continue;
    }

    NSDictionary *bestMode = bestStandardModeByResolution[resolutionKey];
    NSString *resolutionRefreshKey = MDBIntegerPairRefreshKey([modeDictionary[@"width"] unsignedIntegerValue],
                                                              [modeDictionary[@"height"] unsignedIntegerValue],
                                                              [modeDictionary[@"refreshRate"] doubleValue]);
    standardModeByResolutionRefresh[resolutionRefreshKey] = modeDictionary;

    if (bestMode == nil || [modeDictionary[@"refreshRate"] doubleValue] > [bestMode[@"refreshRate"] doubleValue]) {
      bestStandardModeByResolution[resolutionKey] = modeDictionary;
    }

    NSUInteger standardArea = [modeDictionary[@"width"] unsignedIntegerValue] * [modeDictionary[@"height"] unsignedIntegerValue];
    if (standardArea > maxStandardArea) {
      maxStandardArea = standardArea;
      maxStandardWidth = [modeDictionary[@"width"] unsignedIntegerValue];
      maxStandardHeight = [modeDictionary[@"height"] unsignedIntegerValue];
    }
  }

  NSArray<NSDictionary *> *privateModeDictionaries =
      [self privateDisplayModeDictionariesForDisplayID:displayID
                                        currentModeID:currentModeID
                                 seenSemanticModeKeys:seenSemanticModeKeys
                                      displayIDString:displayIDString];

  for (NSDictionary *privateModeDictionary in privateModeDictionaries) {
    NSString *modeID = privateModeDictionary[@"id"];

    if (modeID.length == 0 || [seenModeIDs containsObject:modeID]) {
      continue;
    }

    [seenModeIDs addObject:modeID];
    [modeDictionaries addObject:privateModeDictionary];

    NSString *resolutionKey = MDBIntegerPairKey([privateModeDictionary[@"width"] unsignedIntegerValue],
                                                [privateModeDictionary[@"height"] unsignedIntegerValue]);

    if ([privateModeDictionary[@"isHiDpi"] boolValue]) {
      [seenHiDpiResolutionKeys addObject:resolutionKey];
      [seenHiDpiRefreshKeys addObject:MDBIntegerPairRefreshKey([privateModeDictionary[@"width"] unsignedIntegerValue],
                                                               [privateModeDictionary[@"height"] unsignedIntegerValue],
                                                               [privateModeDictionary[@"refreshRate"] doubleValue])];
    } else {
      NSString *resolutionRefreshKey = MDBIntegerPairRefreshKey([privateModeDictionary[@"width"] unsignedIntegerValue],
                                                                [privateModeDictionary[@"height"] unsignedIntegerValue],
                                                                [privateModeDictionary[@"refreshRate"] doubleValue]);
      standardModeByResolutionRefresh[resolutionRefreshKey] = privateModeDictionary;
    }
  }

  NSUInteger generatedHiDpiRowsAdded = 0;
  NSUInteger generatedHiDpiRowsSkippedDuplicate = 0;
  NSUInteger generatedHiDpiRowsSkipped4KOrAbove = 0;
  NSUInteger generatedHiDpiRowsSkippedExact = 0;
  NSUInteger generatedHiDpiRowsRecipeInstalled = 0;
  NSUInteger generatedHiDpiRowsRecipeExposed = 0;
  NSUInteger generatedHiDpiRowsSkippedCgsOnly = 0;
  NSUInteger generatedHiDpiRowsSkippedNonTarget = 0;
  NSMutableArray<NSString *> *generatedTargetSummaries = [NSMutableArray new];
  BOOL displayIsSub4KUnlockTarget = maxStandardArea > 0 &&
      [self isSub4KHiDpiUnlockTargetWithWidth:maxStandardWidth height:maxStandardHeight];

  if (!displayIsSub4KUnlockTarget) {
    generatedHiDpiRowsSkipped4KOrAbove = standardModeByResolutionRefresh.count;
  }

  for (NSDictionary *mode in (displayIsSub4KUnlockTarget ? standardModeByResolutionRefresh.allValues : @[])) {
    NSUInteger width = [mode[@"width"] unsignedIntegerValue];
    NSUInteger height = [mode[@"height"] unsignedIntegerValue];
    double refreshRate = [mode[@"refreshRate"] doubleValue];
    NSString *source = [mode[@"source"] isKindOfClass:NSString.class] ? mode[@"source"] : @"";

    if (width != maxStandardWidth || height != maxStandardHeight) {
      generatedHiDpiRowsSkippedNonTarget++;
      continue;
    }

    if ([source isEqualToString:@"cgs"]) {
      generatedHiDpiRowsSkippedCgsOnly++;
      continue;
    }

    BOOL targetIsSub4K = [self isSub4KHiDpiUnlockTargetWithWidth:width height:height];

    if (!targetIsSub4K) {
      generatedHiDpiRowsSkipped4KOrAbove++;
      continue;
    }

    BOOL exactHiDpiExists =
        [seenHiDpiRefreshKeys containsObject:MDBIntegerPairRefreshKey(width, height, refreshRate)];
    BOOL recipeIsExposed = MDBOneKeyHiDpiRecipeIsExposed(seenHiDpiResolutionKeys, width, height);
    BOOL installedOneKeyRecipe = [self installedOneKeyHiDpiRecipeExistsForDisplayID:displayID
                                                                              width:width
                                                                             height:height];
    generatedHiDpiRowsRecipeInstalled += installedOneKeyRecipe ? 1 : 0;
    generatedHiDpiRowsRecipeExposed += recipeIsExposed ? 1 : 0;

    if (exactHiDpiExists) {
      generatedHiDpiRowsSkippedExact++;
      continue;
    }

    NSString *modeID = [self generatedHiDpiModeIDWithWidth:width
                                                    height:height
                                               refreshRate:refreshRate];
    if ([seenModeIDs containsObject:modeID]) {
      generatedHiDpiRowsSkippedDuplicate++;
    } else {
      [seenModeIDs addObject:modeID];
      [modeDictionaries addObject:@{
        @"id" : modeID,
        @"width" : @(width),
        @"height" : @(height),
        @"refreshRate" : @(refreshRate),
        @"isHiDpi" : @YES,
        @"isCurrent" : @NO,
        @"isFavorite" : @([self modeIDIsFavorite:modeID displayIDString:displayIDString]),
        @"source" : @"generated",
        @"requiresOverride" : @YES,
        @"requiresRestart" : @(installedOneKeyRecipe && !recipeIsExposed),
      }];
      generatedHiDpiRowsAdded++;
      [generatedTargetSummaries addObject:[NSString stringWithFormat:@"%lux%lu@%.3f/%@",
                                                                     (unsigned long)width,
                                                                     (unsigned long)height,
                                                                     refreshRate,
                                                                     [self hiDpiUnlockTargetClassWithWidth:width height:height]]];
    }
  }

  NSLog(@"[macDisplayBar] Generated HiDPI install row summary: displayID=%@ targetResolution=%@ targetClass=%@ standardResolutionCount=%lu hiDpiResolutionCount=%lu added=%lu skipped4kOrAbove=%lu skippedNonTarget=%lu skippedExact=%lu recipeInstalled=%lu recipeExposed=%lu skippedCgsOnly=%lu skippedDuplicate=%lu totalModeCount=%lu",
        displayIDString,
        generatedTargetSummaries.count > 0 ? [generatedTargetSummaries componentsJoinedByString:@","] : @"none",
        displayIsSub4KUnlockTarget ? @"sub4k" : @"4k-or-above",
        (unsigned long)bestStandardModeByResolution.count,
        (unsigned long)seenHiDpiResolutionKeys.count,
        (unsigned long)generatedHiDpiRowsAdded,
        (unsigned long)generatedHiDpiRowsSkipped4KOrAbove,
        (unsigned long)generatedHiDpiRowsSkippedNonTarget,
        (unsigned long)generatedHiDpiRowsSkippedExact,
        (unsigned long)generatedHiDpiRowsRecipeInstalled,
        (unsigned long)generatedHiDpiRowsRecipeExposed,
        (unsigned long)generatedHiDpiRowsSkippedCgsOnly,
        (unsigned long)generatedHiDpiRowsSkippedDuplicate,
        (unsigned long)modeDictionaries.count);

  [modeDictionaries sortUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
    NSNumber *leftFavorite = left[@"isFavorite"];
    NSNumber *rightFavorite = right[@"isFavorite"];
    NSNumber *leftWidth = left[@"width"];
    NSNumber *rightWidth = right[@"width"];
    NSNumber *leftHeight = left[@"height"];
    NSNumber *rightHeight = right[@"height"];
    NSNumber *leftRefreshRate = left[@"refreshRate"];
    NSNumber *rightRefreshRate = right[@"refreshRate"];
    NSNumber *leftHiDpi = left[@"isHiDpi"];
    NSNumber *rightHiDpi = right[@"isHiDpi"];

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

    if (leftHiDpi.boolValue != rightHiDpi.boolValue) {
      return leftHiDpi.boolValue ? NSOrderedAscending : NSOrderedDescending;
    }

    return NSOrderedSame;
  }];

  return modeDictionaries;
}

