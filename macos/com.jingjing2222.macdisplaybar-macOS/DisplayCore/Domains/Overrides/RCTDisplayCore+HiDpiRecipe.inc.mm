- (NSArray<NSDictionary *> *)generatedHiDpiCustomResolutionRequestsWithWidth:(NSUInteger)width
                                                                      height:(NSUInteger)height
                                                                 refreshRate:(double)refreshRate
{
  if (width == 0 || height == 0) {
    return @[];
  }

  return @[
    @{
      @"id" : [NSString stringWithFormat:@"generated-hidpi:%lu:%lu:%.3f",
                                         (unsigned long)width,
                                         (unsigned long)height,
                                         refreshRate],
      @"width" : @(width),
      @"height" : @(height),
      @"refreshRate" : @(MAX(refreshRate, 0)),
      @"isHiDpi" : @YES,
      @"status" : @"Generated HiDPI recipe",
    }
  ];
}


- (NSArray<NSData *> *)scaleResolutionsForCustomResolutions:(NSArray<NSDictionary *> *)customResolutions
{
  NSMutableArray<NSData *> *scaleResolutions = [NSMutableArray new];
  NSMutableSet<NSData *> *seenResolutions = [NSMutableSet new];
  NSDictionary *hiDpiSeedResolution = nil;
  NSUInteger hiDpiSeedArea = 0;

  for (NSDictionary *resolution in customResolutions) {
    NSUInteger width = [resolution[@"width"] unsignedIntegerValue];
    NSUInteger height = [resolution[@"height"] unsignedIntegerValue];

    if (width == 0 || height == 0) {
      continue;
    }

    if ([resolution[@"isHiDpi"] boolValue]) {
      NSUInteger area = width * height;

      if (hiDpiSeedResolution == nil || area > hiDpiSeedArea) {
        hiDpiSeedResolution = resolution;
        hiDpiSeedArea = area;
      }
      continue;
    }

    NSData *data = MDBScaleResolutionData(width, height);

    if ([seenResolutions containsObject:data]) {
      continue;
    }

    [seenResolutions addObject:data];
    [scaleResolutions addObject:data];
  }

  if (hiDpiSeedResolution != nil) {
    MDBAppendOneKeyHiDpiScaleResolutionFamily(scaleResolutions,
                                              seenResolutions,
                                              [hiDpiSeedResolution[@"width"] unsignedIntegerValue],
                                              [hiDpiSeedResolution[@"height"] unsignedIntegerValue]);
  }

  return scaleResolutions;
}


- (BOOL)exposedGeneratedHiDpiRecipeExistsForDisplayID:(CGDirectDisplayID)displayID
                                                width:(NSUInteger)width
                                               height:(NSUInteger)height
{
  NSDictionary *options = @{(__bridge NSString *)kCGDisplayShowDuplicateLowResolutionModes : @YES};
  CFArrayRef copiedModes = CGDisplayCopyAllDisplayModes(displayID, (__bridge CFDictionaryRef)options);

  if (copiedModes == NULL) {
    return NO;
  }

  NSArray *modes = CFBridgingRelease(copiedModes);
  NSMutableSet<NSString *> *hiDpiResolutionKeys = [NSMutableSet new];

  for (id item in modes) {
    CGDisplayModeRef candidate = (__bridge CGDisplayModeRef)item;

    if (CGDisplayModeGetPixelWidth(candidate) <= CGDisplayModeGetWidth(candidate)) {
      continue;
    }

    [hiDpiResolutionKeys addObject:MDBIntegerPairKey(CGDisplayModeGetWidth(candidate), CGDisplayModeGetHeight(candidate))];
  }

  return MDBOneKeyHiDpiRecipeIsExposed(hiDpiResolutionKeys, width, height);
}


- (BOOL)installedOneKeyHiDpiRecipeExistsForDisplayID:(CGDirectDisplayID)displayID
                                               width:(NSUInteger)width
                                              height:(NSUInteger)height
{
  NSString *vendorDirectoryName = [NSString stringWithFormat:@"DisplayVendorID-%x", CGDisplayVendorNumber(displayID)];
  NSString *productFileName = [NSString stringWithFormat:@"DisplayProductID-%x", CGDisplayModelNumber(displayID)];
  NSURL *overrideURL = [[[NSURL fileURLWithPath:RCTDisplayOverrideInstallDirectory isDirectory:YES]
      URLByAppendingPathComponent:vendorDirectoryName
                      isDirectory:YES] URLByAppendingPathComponent:productFileName];
  NSData *plistData = [NSData dataWithContentsOfURL:overrideURL];

  if (plistData.length == 0) {
    return NO;
  }

  NSError *error = nil;
  NSDictionary *manifest = [NSPropertyListSerialization propertyListWithData:plistData
                                                                     options:NSPropertyListImmutable
                                                                      format:nil
                                                                       error:&error];

  if (![manifest isKindOfClass:NSDictionary.class] || error != nil) {
    return NO;
  }

  if ([manifest[@"DisplayVendorID"] unsignedIntValue] != CGDisplayVendorNumber(displayID) ||
      [manifest[@"DisplayProductID"] unsignedIntValue] != CGDisplayModelNumber(displayID)) {
    return NO;
  }

  NSArray *installedScaleResolutions = manifest[@"scale-resolutions"];

  if (![installedScaleResolutions isKindOfClass:NSArray.class]) {
    return NO;
  }

  NSMutableArray<NSData *> *expectedScaleResolutions = [NSMutableArray new];
  NSMutableSet<NSData *> *expectedSet = [NSMutableSet new];
  MDBAppendOneKeyHiDpiScaleResolutionFamily(expectedScaleResolutions, expectedSet, width, height);
  NSSet *installedSet = [NSSet setWithArray:installedScaleResolutions];

  for (NSData *expectedResolution in expectedScaleResolutions) {
    if (![installedSet containsObject:expectedResolution]) {
      return NO;
    }
  }

  return YES;
}


- (BOOL)isSub4KHiDpiUnlockTargetWithWidth:(NSUInteger)width height:(NSUInteger)height
{
  return width < RCTDisplay4KWidth || height < RCTDisplay4KHeight;
}


- (NSString *)hiDpiUnlockTargetClassWithWidth:(NSUInteger)width height:(NSUInteger)height
{
  return [self isSub4KHiDpiUnlockTargetWithWidth:width height:height] ? @"sub4k" : @"4k-or-above";
}
