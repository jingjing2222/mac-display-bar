- (NSDictionary *)createVirtualDisplayRecordWithID:(NSString *)virtualDisplayID
                                   targetDisplayID:(NSString *)targetDisplayID
                                      serialNumber:(NSNumber *)serialNumber
                                             width:(double)width
                                            height:(double)height
                                       refreshRate:(double)refreshRate
                                           isHiDpi:(BOOL)isHiDpi
                                      errorMessage:(NSString **)errorMessage
{
  Class descriptorClass = NSClassFromString(@"CGVirtualDisplayDescriptor");
  Class displayClass = NSClassFromString(@"CGVirtualDisplay");
  Class modeClass = NSClassFromString(@"CGVirtualDisplayMode");
  Class settingsClass = NSClassFromString(@"CGVirtualDisplaySettings");

  if (descriptorClass == Nil || displayClass == Nil || modeClass == Nil || settingsClass == Nil) {
    if (errorMessage != nil) {
      *errorMessage = @"CGVirtualDisplay API unavailable";
    }

    NSLog(@"[macDisplayBar] Virtual display unavailable: missing CGVirtualDisplay runtime classes");
    return @{};
  }

  NSUInteger logicalWidth = MAX((NSUInteger)llround(width), 1);
  NSUInteger logicalHeight = MAX((NSUInteger)llround(height), 1);
  double normalizedRefreshRate = refreshRate > 0 ? refreshRate : 60;
  NSUInteger backingScale = isHiDpi ? 2 : 1;
  NSUInteger backingWidth = logicalWidth * backingScale;
  NSUInteger backingHeight = logicalHeight * backingScale;
  NSString *name = [NSString stringWithFormat:@"macDisplayBar Virtual %lux%lu",
                                              (unsigned long)logicalWidth,
                                              (unsigned long)logicalHeight];
  SEL modeInitSelector = RCTDisplayPrivateSelector(@"initWithWidth:height:refreshRate:");
  SEL displayInitSelector = RCTDisplayPrivateSelector(@"initWithDescriptor:");

  if (![modeClass instancesRespondToSelector:modeInitSelector] ||
      ![displayClass instancesRespondToSelector:displayInitSelector]) {
    if (errorMessage != nil) {
      *errorMessage = @"CGVirtualDisplay API shape unsupported";
    }

    NSLog(@"[macDisplayBar] Virtual display unavailable: unsupported CGVirtualDisplay selector shape");
    return @{};
  }

  id descriptor = RCTObjCAllocInit(descriptorClass);
  id settings = RCTObjCAllocInit(settingsClass);
  id modeAllocation = ((id (*)(Class, SEL))objc_msgSend)(modeClass, @selector(alloc));
  id mode = ((id (*)(id, SEL, unsigned int, unsigned int, double))objc_msgSend)(
      modeAllocation,
      modeInitSelector,
      (unsigned int)logicalWidth,
      (unsigned int)logicalHeight,
      normalizedRefreshRate);

  if (descriptor == nil || settings == nil || mode == nil) {
    if (errorMessage != nil) {
      *errorMessage = @"Virtual display object allocation failed";
    }

    NSLog(@"[macDisplayBar] Virtual display allocation failed: width=%lu height=%lu refreshRate=%.3f HiDPI=%@",
          (unsigned long)logicalWidth,
          (unsigned long)logicalHeight,
          normalizedRefreshRate,
          isHiDpi ? @"YES" : @"NO");
    return @{};
  }

  RCTObjCSetUnsignedInt(descriptor, RCTDisplayPrivateSelector(@"setVendorID:"), RCTVirtualDisplayVendorID);
  RCTObjCSetUnsignedInt(descriptor, RCTDisplayPrivateSelector(@"setProductID:"), RCTVirtualDisplayProductID);
  RCTObjCSetUnsignedInt(descriptor, RCTDisplayPrivateSelector(@"setSerialNum:"), serialNumber.unsignedIntValue);
  RCTObjCSetObject(descriptor, @selector(setName:), name);
  RCTObjCSetUnsignedInt(descriptor, RCTDisplayPrivateSelector(@"setMaxPixelsWide:"), (unsigned int)backingWidth);
  RCTObjCSetUnsignedInt(descriptor, RCTDisplayPrivateSelector(@"setMaxPixelsHigh:"), (unsigned int)backingHeight);
  RCTObjCSetCGSize(descriptor,
                   RCTDisplayPrivateSelector(@"setSizeInMillimeters:"),
                   CGSizeMake(25.4 * backingWidth / RCTVirtualDisplayPixelsPerInch,
                              25.4 * backingHeight / RCTVirtualDisplayPixelsPerInch));
  RCTObjCSetCGPoint(descriptor, RCTDisplayPrivateSelector(@"setWhitePoint:"), CGPointMake(0.3125, 0.3291));
  RCTObjCSetCGPoint(descriptor, RCTDisplayPrivateSelector(@"setRedPrimary:"), CGPointMake(0.6797, 0.3203));
  RCTObjCSetCGPoint(descriptor, RCTDisplayPrivateSelector(@"setGreenPrimary:"), CGPointMake(0.2559, 0.6983));
  RCTObjCSetCGPoint(descriptor, RCTDisplayPrivateSelector(@"setBluePrimary:"), CGPointMake(0.1494, 0.0557));

  SEL setDispatchQueueSelector = RCTDisplayPrivateSelector(@"setDispatchQueue:");
  if ([descriptor respondsToSelector:setDispatchQueueSelector]) {
    RCTObjCSetObject(descriptor, setDispatchQueueSelector, dispatch_get_main_queue());
  } else {
    RCTObjCSetObject(descriptor, RCTDisplayPrivateSelector(@"setQueue:"), dispatch_get_main_queue());
  }
  SEL terminationHandlerSelector = RCTDisplayPrivateSelector(@"setTerminationHandler:");
  if ([descriptor respondsToSelector:terminationHandlerSelector]) {
    __weak RCTDisplayCore *weakSelf = self;
    NSString *capturedVirtualDisplayID = [virtualDisplayID copy];
    RCTObjCSetObject(descriptor, terminationHandlerSelector, [^{
      RCTDisplayCore *strongSelf = weakSelf;
      if (strongSelf == nil) {
        return;
      }

      dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *record = [strongSelf.virtualDisplayRecords[capturedVirtualDisplayID] mutableCopy];
        if (![record isKindOfClass:NSMutableDictionary.class]) {
          return;
        }

        record[@"status"] = @"Terminated";
        record[@"mirrorTargetDisplayID"] = @"";
        record[@"mirrorSourceDisplayID"] = @"";
        record[@"mirrorMode"] = @"none";
        record[@"mirrorStatus"] = @"Not mirrored";
        record[@"lastError"] = @"Virtual display terminated by system";
        [strongSelf.virtualDisplays removeObjectForKey:capturedVirtualDisplayID];
        strongSelf.virtualDisplayRecords[capturedVirtualDisplayID] = record;
        [strongSelf persistVirtualDisplayRecords];
      });
    } copy]);
  }

  RCTObjCSetUnsignedInt(settings, RCTDisplayPrivateSelector(@"setHiDPI:"), isHiDpi ? 1 : 0);
  RCTObjCSetObject(settings, RCTDisplayPrivateSelector(@"setModes:"), @[ mode ]);

  id displayAllocation = ((id (*)(Class, SEL))objc_msgSend)(displayClass, @selector(alloc));
  id virtualDisplay =
      ((id (*)(id, SEL, id))objc_msgSend)(displayAllocation, displayInitSelector, descriptor);

  SEL applySettingsSelector = RCTDisplayPrivateSelector(@"applySettings:");
  if (virtualDisplay == nil || ![virtualDisplay respondsToSelector:applySettingsSelector]) {
    if (errorMessage != nil) {
      *errorMessage = @"Virtual display creation failed";
    }

    NSLog(@"[macDisplayBar] Virtual display creation failed: width=%lu height=%lu refreshRate=%.3f HiDPI=%@",
          (unsigned long)logicalWidth,
          (unsigned long)logicalHeight,
          normalizedRefreshRate,
          isHiDpi ? @"YES" : @"NO");
    return @{};
  }

  BOOL didApply = ((BOOL (*)(id, SEL, id))objc_msgSend)(virtualDisplay, applySettingsSelector, settings);

  if (!didApply) {
    if (errorMessage != nil) {
      *errorMessage = @"Virtual display settings rejected";
    }

    NSLog(@"[macDisplayBar] Virtual display settings rejected: width=%lu height=%lu refreshRate=%.3f HiDPI=%@",
          (unsigned long)logicalWidth,
          (unsigned long)logicalHeight,
          normalizedRefreshRate,
          isHiDpi ? @"YES" : @"NO");
    return @{};
  }

  NSString *displayID = [self visibleDisplayIDForVirtualDisplay:virtualDisplay];

  self.virtualDisplays[virtualDisplayID] = virtualDisplay;

  if (displayID.length == 0) {
    NSLog(@"[macDisplayBar] Virtual display activation pending: id=%@ width=%lu height=%lu refreshRate=%.3f HiDPI=%@",
          virtualDisplayID,
          (unsigned long)logicalWidth,
          (unsigned long)logicalHeight,
          normalizedRefreshRate,
          isHiDpi ? @"YES" : @"NO");
    return [self virtualDisplayRecordWithID:virtualDisplayID
                            targetDisplayID:targetDisplayID ?: @""
                                   displayID:@""
                      mirrorTargetDisplayID:@""
                      mirrorSourceDisplayID:@""
                                   mirrorMode:@"none"
                                 mirrorStatus:@"Not mirrored"
                                       name:name
                               serialNumber:serialNumber
                                      width:logicalWidth
                                     height:logicalHeight
                                refreshRate:normalizedRefreshRate
                                    isHiDpi:isHiDpi
                                     status:@"Creating"
                                  lastError:@""];
  }

  NSLog(@"[macDisplayBar] Virtual display created: id=%@ displayID=%@ width=%lu height=%lu refreshRate=%.3f HiDPI=%@",
        virtualDisplayID,
        displayID,
        (unsigned long)logicalWidth,
        (unsigned long)logicalHeight,
        normalizedRefreshRate,
        isHiDpi ? @"YES" : @"NO");

  return [self virtualDisplayRecordWithID:virtualDisplayID
                          targetDisplayID:targetDisplayID ?: @""
                                 displayID:displayID
                    mirrorTargetDisplayID:@""
                    mirrorSourceDisplayID:@""
                                 mirrorMode:@"none"
                               mirrorStatus:@"Not mirrored"
                                     name:name
                             serialNumber:serialNumber
                                    width:logicalWidth
                                   height:logicalHeight
                              refreshRate:normalizedRefreshRate
                                  isHiDpi:isHiDpi
                                   status:@"Created"
                                lastError:@""];
}


- (BOOL)activeDisplayListContainsDisplayID:(CGDirectDisplayID)displayID
{
  if (displayID == 0) {
    return NO;
  }

  uint32_t displayCount = 0;
  CGError countError = CGGetActiveDisplayList(0, NULL, &displayCount);

  if (countError != kCGErrorSuccess || displayCount == 0) {
    return NO;
  }

  NSMutableData *displayIDData = [NSMutableData dataWithLength:sizeof(CGDirectDisplayID) * displayCount];
  CGDirectDisplayID *displayIDs = (CGDirectDisplayID *)displayIDData.mutableBytes;
  CGError listError = CGGetActiveDisplayList(displayCount, displayIDs, &displayCount);

  if (listError != kCGErrorSuccess) {
    return NO;
  }

  for (uint32_t index = 0; index < displayCount; index++) {
    if (displayIDs[index] == displayID) {
      return YES;
    }
  }

  return NO;
}

