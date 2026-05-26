- (double)dimmingLevelForDisplayIDString:(NSString *)displayID
{
  NSNumber *level = self.dimmingLevels[displayID];

  if (level == nil) {
    return 0;
  }

  return MDBClampDouble(level.doubleValue, 0, 0.8);
}

- (NSDictionary *)ddcStateForDisplayIDString:(NSString *)displayID supportsDdc:(BOOL)supportsDdc
{
  if (!supportsDdc) {
    self.ddcReadStatus[displayID] = @"Unavailable";
  } else if (self.ddcReadStatus[displayID] == nil) {
    self.ddcReadStatus[displayID] = @"Cached";
  }

  return @{
    @"brightness" : @([self ddcValueForDisplayIDString:displayID controlCode:0x10 fallback:50]),
    @"contrast" : @([self ddcValueForDisplayIDString:displayID controlCode:0x12 fallback:50]),
    @"volume" : @([self ddcValueForDisplayIDString:displayID controlCode:0x62 fallback:20]),
    @"inputSource" : @([self ddcValueForDisplayIDString:displayID controlCode:0x60 fallback:15]),
    @"readStatus" : self.ddcReadStatus[displayID] ?: @"Cached",
    @"lastError" : self.ddcErrors[displayID] ?: @"",
  };
}

- (void)refreshDdcValuesForActiveDisplays
{
  uint32_t displayCount = 0;
  CGError countError = CGGetActiveDisplayList(0, NULL, &displayCount);

  if (countError != kCGErrorSuccess || displayCount == 0) {
    return;
  }

  std::vector<CGDirectDisplayID> displayIDs(displayCount);
  CGError listError = CGGetActiveDisplayList(displayCount, displayIDs.data(), &displayCount);

  if (listError != kCGErrorSuccess) {
    return;
  }

  for (uint32_t index = 0; index < displayCount; index++) {
    CGDirectDisplayID displayID = displayIDs[index];

    if (![self displaySupportsDdc:displayID]) {
      continue;
    }

    [self refreshDdcValuesForDisplayID:displayID
                       displayIDString:[NSString stringWithFormat:@"%u", displayID]];
  }
}

- (void)refreshDdcValuesForDisplayID:(CGDirectDisplayID)displayID displayIDString:(NSString *)displayIDString
{
  NSArray<NSNumber *> *controlCodes = @[ @(0x10), @(0x12), @(0x62), @(0x60) ];
  BOOL didReadAny = NO;
  NSString *lastError = nil;

  for (NSNumber *controlCodeNumber in controlCodes) {
    uint8_t controlCode = controlCodeNumber.unsignedCharValue;
    uint16_t currentValue = 0;
    uint16_t maximumValue = 0;
    NSString *errorMessage = nil;
    BOOL didRead = [self readDdcVcpForDisplayID:displayID
                                    controlCode:controlCode
                                   currentValue:&currentValue
                                   maximumValue:&maximumValue
                                   errorMessage:&errorMessage];

    if (didRead) {
      didReadAny = YES;
      self.ddcValues[[self ddcKeyForDisplayIDString:displayIDString controlCode:controlCode]] = @(currentValue);
    } else if (errorMessage.length > 0) {
      lastError = errorMessage;
    }
  }

  if (didReadAny) {
    self.ddcReadStatus[displayIDString] = @"Live";
    [self.ddcErrors removeObjectForKey:displayIDString];
    [[NSUserDefaults standardUserDefaults] setObject:self.ddcValues forKey:RCTDisplayDdcDefaultsKey];
  } else {
    self.ddcReadStatus[displayIDString] = @"Cached";

    if (lastError.length > 0) {
      self.ddcErrors[displayIDString] = lastError;
    }
  }
}

- (double)ddcValueForDisplayIDString:(NSString *)displayID controlCode:(uint8_t)controlCode fallback:(double)fallback
{
  NSNumber *value = self.ddcValues[[self ddcKeyForDisplayIDString:displayID controlCode:controlCode]];

  if (value == nil) {
    return fallback;
  }

  return value.doubleValue;
}

- (NSString *)ddcKeyForDisplayIDString:(NSString *)displayID controlCode:(uint8_t)controlCode
{
  return [NSString stringWithFormat:@"%@-%u", displayID, controlCode];
}

- (BOOL)displaySupportsNativeBrightness:(CGDirectDisplayID)displayID
{
  BOOL didRead = NO;
  [self nativeBrightnessForDisplayID:displayID didRead:&didRead];

  return didRead;
}

- (double)nativeBrightnessForDisplayID:(CGDirectDisplayID)displayID didRead:(BOOL *)didRead
{
  io_service_t framebuffer = [self framebufferServiceForDisplayID:displayID];

  if (framebuffer == MACH_PORT_NULL) {
    if (didRead != nil) {
      *didRead = NO;
    }

    return 0;
  }

  float brightness = 0;
  IOReturn result = IODisplayGetFloatParameter(framebuffer, kNilOptions, CFSTR(kIODisplayBrightnessKey), &brightness);

  if (didRead != nil) {
    *didRead = result == kIOReturnSuccess;
  }

  if (result != kIOReturnSuccess) {
    return 0;
  }

  return MDBClampDouble(brightness, 0, 1);
}

- (BOOL)setNativeBrightnessForDisplayID:(CGDirectDisplayID)displayID
                                  level:(double)level
                           errorMessage:(NSString **)errorMessage
{
  io_service_t framebuffer = [self framebufferServiceForDisplayID:displayID];

  if (framebuffer == MACH_PORT_NULL) {
    if (errorMessage != nil) {
      *errorMessage = @"Display framebuffer not found";
    }

    return NO;
  }

  float brightness = (float)MDBClampDouble(level, 0, 1);
  IOReturn result = IODisplaySetFloatParameter(framebuffer, kNilOptions, CFSTR(kIODisplayBrightnessKey), brightness);

  if (result != kIOReturnSuccess) {
    if (errorMessage != nil) {
      *errorMessage = [NSString stringWithFormat:@"Native brightness failed: 0x%08x", result];
    }

    return NO;
  }

  return YES;
}

- (BOOL)displaySupportsDdc:(CGDirectDisplayID)displayID
{
  if (CGDisplayIsBuiltin(displayID)) {
    return NO;
  }

  io_service_t framebuffer = [self framebufferServiceForDisplayID:displayID];

  if (framebuffer == MACH_PORT_NULL) {
    return NO;
  }

  IOItemCount busCount = 0;
  IOReturn countResult = IOFBGetI2CInterfaceCount(framebuffer, &busCount);

  if (countResult != kIOReturnSuccess || busCount == 0) {
    return NO;
  }

  for (IOOptionBits bus = 0; bus < busCount; bus++) {
    io_service_t interface = MACH_PORT_NULL;
    IOReturn copyResult = IOFBCopyI2CInterfaceForBus(framebuffer, bus, &interface);

    if (copyResult != kIOReturnSuccess || interface == MACH_PORT_NULL) {
      continue;
    }

    IOI2CConnectRef connect = NULL;
    IOReturn openResult = IOI2CInterfaceOpen(interface, kNilOptions, &connect);

    if (openResult == kIOReturnSuccess && connect != NULL) {
      IOI2CInterfaceClose(connect, kNilOptions);
      IOObjectRelease(interface);
      return YES;
    }

    IOObjectRelease(interface);
  }

  return NO;
}

- (BOOL)readDdcVcpForDisplayID:(CGDirectDisplayID)displayID
                    controlCode:(uint8_t)controlCode
                   currentValue:(uint16_t *)currentValue
                   maximumValue:(uint16_t *)maximumValue
                   errorMessage:(NSString **)errorMessage
{
  if (CGDisplayIsBuiltin(displayID)) {
    if (errorMessage != nil) {
      *errorMessage = @"Built-in display does not expose DDC";
    }

    return NO;
  }

  io_service_t framebuffer = [self framebufferServiceForDisplayID:displayID];

  if (framebuffer == MACH_PORT_NULL) {
    if (errorMessage != nil) {
      *errorMessage = @"Display framebuffer not found";
    }

    return NO;
  }

  IOItemCount busCount = 0;
  IOReturn countResult = IOFBGetI2CInterfaceCount(framebuffer, &busCount);

  if (countResult != kIOReturnSuccess || busCount == 0) {
    if (errorMessage != nil) {
      *errorMessage = @"No DDC I2C bus found";
    }

    return NO;
  }

  NSString *lastError = @"DDC read failed";

  for (IOOptionBits bus = 0; bus < busCount; bus++) {
    io_service_t interface = MACH_PORT_NULL;
    IOReturn copyResult = IOFBCopyI2CInterfaceForBus(framebuffer, bus, &interface);

    if (copyResult != kIOReturnSuccess || interface == MACH_PORT_NULL) {
      lastError = [NSString stringWithFormat:@"I2C bus %u unavailable", bus];
      continue;
    }

    IOI2CConnectRef connect = NULL;
    IOReturn openResult = IOI2CInterfaceOpen(interface, kNilOptions, &connect);

    if (openResult != kIOReturnSuccess || connect == NULL) {
      lastError = [NSString stringWithFormat:@"I2C bus %u open failed", bus];
      IOObjectRelease(interface);
      continue;
    }

    uint8_t packet[5] = {
        RCTDdcHostAddress,
        0x82,
        RCTDdcGetVcpFeatureCommand,
        controlCode,
        0,
    };
    uint8_t checksum = RCTDdcDestinationAddress;

    for (NSUInteger index = 0; index < sizeof(packet) - 1; index++) {
      checksum ^= packet[index];
    }

    packet[sizeof(packet) - 1] = checksum;

    uint8_t reply[16] = {};
    IOI2CRequest request = {};
    request.sendAddress = RCTDdcDestinationAddress;
    request.sendTransactionType = kIOI2CSimpleTransactionType;
    request.sendBuffer = (vm_address_t)packet;
    request.sendBytes = sizeof(packet);
    request.replyAddress = RCTDdcReplyAddress;
    request.replyTransactionType = kIOI2CDDCciReplyTransactionType;
    request.replyBuffer = (vm_address_t)reply;
    request.replyBytes = sizeof(reply);

    IOReturn sendResult = IOI2CSendRequest(connect, kNilOptions, &request);
    IOI2CInterfaceClose(connect, kNilOptions);
    IOObjectRelease(interface);

    if (sendResult == kIOReturnSuccess && request.result == kIOReturnSuccess &&
        [self parseDdcVcpReply:reply
                        length:request.replyBytes
                   controlCode:controlCode
                  currentValue:currentValue
                  maximumValue:maximumValue]) {
      return YES;
    }

    lastError = [NSString stringWithFormat:@"DDC read failed on bus %u", bus];
  }

  if (errorMessage != nil) {
    *errorMessage = lastError;
  }

  return NO;
}

- (BOOL)parseDdcVcpReply:(uint8_t *)reply
                  length:(uint32_t)length
             controlCode:(uint8_t)controlCode
            currentValue:(uint16_t *)currentValue
            maximumValue:(uint16_t *)maximumValue
{
  if (reply == NULL || length < 8) {
    return NO;
  }

  for (uint32_t index = 0; index + 7 < length; index++) {
    BOOL isVcpReply = reply[index] == 0x02;
    BOOL resultOk = reply[index + 1] == 0x00;
    BOOL controlMatches = reply[index + 2] == controlCode;

    if (!isVcpReply || !resultOk || !controlMatches) {
      continue;
    }

    if (maximumValue != nil) {
      *maximumValue = ((uint16_t)reply[index + 4] << 8) | reply[index + 5];
    }

    if (currentValue != nil) {
      *currentValue = ((uint16_t)reply[index + 6] << 8) | reply[index + 7];
    }

    return YES;
  }

  return NO;
}

- (BOOL)sendDdcSetVcpForDisplayID:(CGDirectDisplayID)displayID
                       controlCode:(uint8_t)controlCode
                             value:(uint16_t)value
                      errorMessage:(NSString **)errorMessage
{
  if (CGDisplayIsBuiltin(displayID)) {
    if (errorMessage != nil) {
      *errorMessage = @"Built-in display does not expose DDC";
    }

    return NO;
  }

  io_service_t framebuffer = [self framebufferServiceForDisplayID:displayID];

  if (framebuffer == MACH_PORT_NULL) {
    if (errorMessage != nil) {
      *errorMessage = @"Display framebuffer not found";
    }

    return NO;
  }

  IOItemCount busCount = 0;
  IOReturn countResult = IOFBGetI2CInterfaceCount(framebuffer, &busCount);

  if (countResult != kIOReturnSuccess || busCount == 0) {
    if (errorMessage != nil) {
      *errorMessage = @"No DDC I2C bus found";
    }

    return NO;
  }

  NSString *lastError = @"DDC command failed";

  for (IOOptionBits bus = 0; bus < busCount; bus++) {
    io_service_t interface = MACH_PORT_NULL;
    IOReturn copyResult = IOFBCopyI2CInterfaceForBus(framebuffer, bus, &interface);

    if (copyResult != kIOReturnSuccess || interface == MACH_PORT_NULL) {
      lastError = [NSString stringWithFormat:@"I2C bus %u unavailable", bus];
      continue;
    }

    IOI2CConnectRef connect = NULL;
    IOReturn openResult = IOI2CInterfaceOpen(interface, kNilOptions, &connect);

    if (openResult != kIOReturnSuccess || connect == NULL) {
      lastError = [NSString stringWithFormat:@"I2C bus %u open failed", bus];
      IOObjectRelease(interface);
      continue;
    }

    uint8_t packet[7] = {
        RCTDdcHostAddress,
        0x84,
        RCTDdcSetVcpControlCommand,
        controlCode,
        (uint8_t)(value >> 8),
        (uint8_t)(value & 0xFF),
        0,
    };
    uint8_t checksum = RCTDdcDestinationAddress;

    for (NSUInteger index = 0; index < sizeof(packet) - 1; index++) {
      checksum ^= packet[index];
    }

    packet[sizeof(packet) - 1] = checksum;

    IOI2CRequest request = {};
    request.sendAddress = RCTDdcDestinationAddress;
    request.sendTransactionType = kIOI2CSimpleTransactionType;
    request.sendBuffer = (vm_address_t)packet;
    request.sendBytes = sizeof(packet);
    request.replyTransactionType = kIOI2CNoTransactionType;

    IOReturn sendResult = IOI2CSendRequest(connect, kNilOptions, &request);
    IOI2CInterfaceClose(connect, kNilOptions);
    IOObjectRelease(interface);

    if (sendResult == kIOReturnSuccess && request.result == kIOReturnSuccess) {
      return YES;
    }

    lastError = [NSString stringWithFormat:@"DDC send failed on bus %u", bus];
  }

  if (errorMessage != nil) {
    *errorMessage = lastError;
  }

  return NO;
}

- (io_service_t)framebufferServiceForDisplayID:(CGDirectDisplayID)displayID
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  return CGDisplayIOServicePort(displayID);
#pragma clang diagnostic pop
}

- (void)syncXdrUpscaleWindowForDisplayID:(CGDirectDisplayID)displayID enabled:(BOOL)enabled
{
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self syncXdrUpscaleWindowForDisplayID:displayID enabled:enabled];
    });
    return;
  }

  NSString *displayIDString = [NSString stringWithFormat:@"%u", displayID];
  NSWindow *window = self.xdrUpscaleWindows[displayIDString];

  if (!enabled) {
    [window orderOut:nil];
    [self.xdrUpscaleWindows removeObjectForKey:displayIDString];
    return;
  }

  NSScreen *screen = [self screenForDisplayID:displayID];

  if (screen == nil) {
    [window orderOut:nil];
    [self.xdrUpscaleWindows removeObjectForKey:displayIDString];
    return;
  }

  if (window == nil) {
    window = [[NSWindow alloc] initWithContentRect:screen.frame
                                        styleMask:NSWindowStyleMaskBorderless
                                          backing:NSBackingStoreBuffered
                                            defer:NO
                                           screen:screen];
    window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
        NSWindowCollectionBehaviorFullScreenAuxiliary |
        NSWindowCollectionBehaviorStationary |
        NSWindowCollectionBehaviorIgnoresCycle;
    window.ignoresMouseEvents = YES;
    window.level = NSFloatingWindowLevel;
    window.opaque = NO;
    window.releasedWhenClosed = NO;
    window.backgroundColor = NSColor.clearColor;
    window.contentView = [NSView new];
    self.xdrUpscaleWindows[displayIDString] = window;
  }

  CGFloat potentialHeadroom = MAX(screen.maximumPotentialExtendedDynamicRangeColorComponentValue, 1);
  CGFloat boostComponent = MIN(potentialHeadroom, 2);
  CGFloat components[] = {boostComponent, boostComponent, boostComponent, 0.16};
  NSColor *boostColor = [NSColor colorWithColorSpace:[NSColorSpace extendedSRGBColorSpace]
                                         components:components
                                              count:4];

  [window setFrame:screen.frame display:YES];
  window.contentView.wantsLayer = YES;
  window.contentView.layer.backgroundColor =
      (boostColor ?: [NSColor colorWithCalibratedWhite:1 alpha:0.16]).CGColor;
  [window orderFrontRegardless];
}

- (void)syncDimmingWindowForDisplayID:(CGDirectDisplayID)displayID level:(double)level
{
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self syncDimmingWindowForDisplayID:displayID level:level];
    });
    return;
  }

  NSString *displayIDString = [NSString stringWithFormat:@"%u", displayID];
  NSWindow *window = self.dimmingWindows[displayIDString];

  if (level <= 0) {
    [window orderOut:nil];
    [self.dimmingWindows removeObjectForKey:displayIDString];
    return;
  }

  NSScreen *screen = [self screenForDisplayID:displayID];

  if (screen == nil) {
    [window orderOut:nil];
    [self.dimmingWindows removeObjectForKey:displayIDString];
    return;
  }

  if (window == nil) {
    window = [[NSWindow alloc] initWithContentRect:screen.frame
                                        styleMask:NSWindowStyleMaskBorderless
                                          backing:NSBackingStoreBuffered
                                            defer:NO
                                           screen:screen];
    window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
        NSWindowCollectionBehaviorFullScreenAuxiliary |
        NSWindowCollectionBehaviorStationary |
        NSWindowCollectionBehaviorIgnoresCycle;
    window.ignoresMouseEvents = YES;
    window.level = NSFloatingWindowLevel;
    window.opaque = NO;
    window.releasedWhenClosed = NO;
    window.backgroundColor = NSColor.clearColor;
    window.contentView = [NSView new];
    self.dimmingWindows[displayIDString] = window;
  }

  [window setFrame:screen.frame display:YES];
  window.contentView.wantsLayer = YES;
  window.contentView.layer.backgroundColor =
      [NSColor colorWithCalibratedWhite:0 alpha:level].CGColor;
  [window orderFrontRegardless];
}

