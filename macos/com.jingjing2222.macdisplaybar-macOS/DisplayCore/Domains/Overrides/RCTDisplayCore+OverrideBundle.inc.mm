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
  return [self writeOverrideBundleForDisplayIDString:displayID includeEdid:YES];
}


- (NSString *)writeOverrideBundleForDisplayIDString:(NSString *)displayID includeEdid:(BOOL)includeEdid
{
  return [self writeOverrideBundleForDisplayIDString:displayID
                                         includeEdid:includeEdid
                                   customResolutions:[self customResolutionRequestsForDisplayIDString:displayID]];
}


- (NSString *)writeOverrideBundleForDisplayIDString:(NSString *)displayID
                                        includeEdid:(BOOL)includeEdid
                                  customResolutions:(NSArray<NSDictionary *> *)customResolutions
{
  CGDirectDisplayID directDisplayID = (CGDirectDisplayID)displayID.integerValue;

  if (directDisplayID == 0 || ![self activeDisplayListContainsDisplayID:directDisplayID]) {
    NSLog(@"[macDisplayBar] Display override bundle skipped: displayID=%@ reason=invalid or inactive display",
          displayID);
    return @"";
  }

  uint32_t vendorID = CGDisplayVendorNumber(directDisplayID);
  uint32_t productID = CGDisplayModelNumber(directDisplayID);

  if (vendorID == 0 && productID == 0) {
    NSLog(@"[macDisplayBar] Display override bundle skipped: displayID=%@ reason=missing vendor/product identity",
          displayID);
    return @"";
  }

  NSString *edidOverridePath = self.edidOverridePaths[displayID] ?: @"";
  NSString *vendorDirectoryName = [NSString stringWithFormat:@"DisplayVendorID-%x", vendorID];
  NSString *productFileName = [NSString stringWithFormat:@"DisplayProductID-%x", productID];
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
    @"DisplayVendorID" : @(vendorID),
    @"DisplayProductID" : @(productID),
    @"target-default-ppmm" : @10.0699301,
  } mutableCopy];
  NSMutableArray<NSData *> *scaleResolutions = [[self scaleResolutionsForCustomResolutions:customResolutions] mutableCopy];
  NSMutableSet<NSData *> *seenScaleResolutions = [NSMutableSet setWithArray:scaleResolutions];
  BOOL flexibleScalingEnabled = [self flexibleScalingEnabledForDisplayIDString:displayID];
  BOOL hasPanelResolutionOverride = [self nativePanelResolutionOverrideExistsForDisplayIDString:displayID];
  NSDictionary *nativePanelResolution = [self nativePanelResolutionForDisplayID:directDisplayID displayIDString:displayID];
  NSUInteger nativePanelWidth = [nativePanelResolution[@"width"] unsignedIntegerValue];
  NSUInteger nativePanelHeight = [nativePanelResolution[@"height"] unsignedIntegerValue];
  BOOL hasPayload = NO;

  if ((flexibleScalingEnabled || hasPanelResolutionOverride) && nativePanelWidth > 0 && nativePanelHeight > 0) {
    MDBAppendOneKeyHiDpiScaleResolutionFamily(scaleResolutions,
                                              seenScaleResolutions,
                                              nativePanelWidth,
                                              nativePanelHeight);
  }

  if (scaleResolutions.count > 0) {
    manifest[@"scale-resolutions"] = scaleResolutions;
    hasPayload = YES;
  }

  if (includeEdid && edidOverridePath.length > 0) {
    NSData *edidOverrideData = [NSData dataWithContentsOfFile:edidOverridePath];

    if (edidOverrideData.length > 0) {
      manifest[@"IODisplayEDID"] = edidOverrideData;
      hasPayload = YES;
    } else {
      NSLog(@"[macDisplayBar] Display override EDID payload unavailable: displayID=%@ path=%@",
            displayID,
            edidOverridePath);
    }
  }

  NSLog(@"[macDisplayBar] Display override bundle prepared: displayID=%@ customResolutionCount=%lu scaleResolutionCount=%lu edidOverride=%@ flexibleScaling=%@ nativePanel=%lux%lu nativePanelOverride=%@",
        displayID,
        (unsigned long)customResolutions.count,
        (unsigned long)scaleResolutions.count,
        manifest[@"IODisplayEDID"] != nil ? @"YES" : @"NO",
        flexibleScalingEnabled ? @"YES" : @"NO",
        (unsigned long)nativePanelWidth,
        (unsigned long)nativePanelHeight,
        hasPanelResolutionOverride ? @"YES" : @"NO");

  if (!hasPayload) {
    NSLog(@"[macDisplayBar] Display override bundle skipped: displayID=%@ reason=no payload", displayID);
    return @"";
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

