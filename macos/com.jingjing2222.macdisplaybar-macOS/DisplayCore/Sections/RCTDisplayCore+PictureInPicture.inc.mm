- (NSDictionary *)pipWindowRecordWithID:(NSString *)pipWindowID
                              displayID:(NSString *)displayID
                                   name:(NSString *)name
                                 width:(double)width
                                height:(double)height
                                   fps:(double)fps
                                filter:(NSString *)filter
                                status:(NSString *)status
                             lastError:(NSString *)lastError
{
  NSString *normalizedFilter = [self normalizedPipFilter:filter];

  return @{
    @"id" : pipWindowID ?: @"",
    @"displayID" : displayID ?: @"",
    @"name" : name ?: @"macDisplayBar PiP",
    @"width" : @(MAX(width, 1)),
    @"height" : @(MAX(height, 1)),
    @"fps" : @(MAX(fps, 0)),
    @"filter" : normalizedFilter,
    @"status" : status ?: @"Unknown",
    @"lastError" : lastError ?: @"",
  };
}

- (NSArray<NSDictionary *> *)pipWindowSummaries
{
  if (![NSThread isMainThread]) {
    __block NSArray<NSDictionary *> *summaries = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
      summaries = [self pipWindowSummaries];
    });
    return summaries ?: @[];
  }

  NSMutableArray<NSDictionary *> *summaries = [NSMutableArray arrayWithCapacity:self.pipWindowRecords.count];

  for (NSString *pipWindowID in self.pipWindowRecords) {
    NSDictionary *record = self.pipWindowRecords[pipWindowID];

    if ([record isKindOfClass:NSDictionary.class]) {
      [summaries addObject:record];
    }
  }

  [summaries sortUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
    return [left[@"name"] compare:right[@"name"]];
  }];

  return summaries;
}

- (NSString *)normalizedPipFilter:(NSString *)filter
{
  if (![filter isKindOfClass:NSString.class] || filter.length == 0) {
    return @"none";
  }

  NSSet<NSString *> *allowedFilters = [NSSet setWithArray:@[
    @"none",
    @"mono",
    @"invert",
    @"warm",
    @"vibrant",
  ]];

  return [allowedFilters containsObject:filter] ? filter : @"none";
}

- (CGImageRef)newPipImageFromImage:(CGImageRef)imageRef filter:(NSString *)filter
{
  NSString *normalizedFilter = [self normalizedPipFilter:filter];

  if (imageRef == NULL || [normalizedFilter isEqualToString:@"none"]) {
    return imageRef == NULL ? NULL : CGImageRetain(imageRef);
  }

  CIImage *inputImage = [CIImage imageWithCGImage:imageRef];
  CIFilter *imageFilter = nil;

  if ([normalizedFilter isEqualToString:@"mono"]) {
    imageFilter = [CIFilter filterWithName:@"CIPhotoEffectMono"];
  } else if ([normalizedFilter isEqualToString:@"invert"]) {
    imageFilter = [CIFilter filterWithName:@"CIColorInvert"];
  } else if ([normalizedFilter isEqualToString:@"warm"]) {
    imageFilter = [CIFilter filterWithName:@"CISepiaTone"];
    [imageFilter setValue:@0.55 forKey:kCIInputIntensityKey];
  } else if ([normalizedFilter isEqualToString:@"vibrant"]) {
    imageFilter = [CIFilter filterWithName:@"CIVibrance"];
    [imageFilter setValue:@0.75 forKey:@"inputAmount"];
  }

  if (imageFilter == nil || inputImage == nil) {
    return CGImageRetain(imageRef);
  }

  [imageFilter setValue:inputImage forKey:kCIInputImageKey];
  CIImage *outputImage = imageFilter.outputImage ?: inputImage;
  CGRect outputExtent = outputImage.extent;

  if (CGRectIsEmpty(outputExtent)) {
    return CGImageRetain(imageRef);
  }

  return [self.pipFilterContext createCGImage:outputImage fromRect:outputExtent];
}

- (void)capturePipFrameForID:(NSString *)pipWindowID
{
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self capturePipFrameForID:pipWindowID];
    });
    return;
  }

  NSDictionary *record = self.pipWindowRecords[pipWindowID];
  NSImageView *imageView = self.pipImageViews[pipWindowID];

  if (![record isKindOfClass:NSDictionary.class] || imageView == nil) {
    return;
  }

  NSString *displayID = [record[@"displayID"] isKindOfClass:NSString.class] ? record[@"displayID"] : @"";

  if (![self displayIDStringIsActive:displayID]) {
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
    [self.pipWindows removeObjectForKey:pipWindowID];
    [self.pipImageViews removeObjectForKey:pipWindowID];
    [self.pipWindowRecords removeObjectForKey:pipWindowID];
    [self recordAdvancedOperation:@"Picture in Picture closed because display became unavailable" displayID:displayID];
    NSLog(@"[macDisplayBar] PiP window closed because source display is unavailable: id=%@ displayID=%@",
          pipWindowID ?: @"",
          displayID);
    return;
  }

  if ([self.pipCaptureInFlight containsObject:pipWindowID]) {
    return;
  }

  CGDirectDisplayID directDisplayID = (CGDirectDisplayID)displayID.integerValue;
  NSWindow *window = self.pipWindows[pipWindowID];
  BOOL windowWasOnCapturedDisplay = NO;
  CGWindowID windowNumber = 0;

  if (window != nil) {
    NSNumber *screenNumber = window.screen.deviceDescription[@"NSScreenNumber"];
    windowWasOnCapturedDisplay =
        [screenNumber isKindOfClass:NSNumber.class] && screenNumber.unsignedIntValue == directDisplayID;
    windowNumber = (CGWindowID)window.windowNumber;
  }

  NSString *filter = [record[@"filter"] isKindOfClass:NSString.class] ? record[@"filter"] : @"none";
  NSString *normalizedFilter = [self normalizedPipFilter:filter];
  NSString *capturedPipWindowID = [pipWindowID copy];
  NSString *capturedDisplayID = [displayID copy];
  [self.pipCaptureInFlight addObject:capturedPipWindowID];

  dispatch_async(self.pipCaptureQueue, ^{
    CGImageRef imageRef = NULL;

    if (windowWasOnCapturedDisplay) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      imageRef = CGWindowListCreateImage(CGDisplayBounds(directDisplayID),
                                         kCGWindowListOptionOnScreenBelowWindow,
                                         windowNumber,
                                         kCGWindowImageDefault);
#pragma clang diagnostic pop
    } else {
      imageRef = CGDisplayCreateImage(directDisplayID);
    }

    if (imageRef == NULL) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.pipCaptureInFlight removeObject:capturedPipWindowID];
        NSDictionary *currentRecord = self.pipWindowRecords[capturedPipWindowID];

        if (![currentRecord isKindOfClass:NSDictionary.class]) {
          return;
        }

        NSMutableDictionary *updatedRecord = [currentRecord mutableCopy];
        updatedRecord[@"status"] = @"Capture failed";
        updatedRecord[@"lastError"] = @"Display capture unavailable";
        self.pipWindowRecords[capturedPipWindowID] = updatedRecord;
      });
      return;
    }

    CGImageRef displayImageRef = [self newPipImageFromImage:imageRef filter:normalizedFilter];
    CGImageRelease(imageRef);

    dispatch_async(dispatch_get_main_queue(), ^{
      [self.pipCaptureInFlight removeObject:capturedPipWindowID];
      NSDictionary *currentRecord = self.pipWindowRecords[capturedPipWindowID];
      NSImageView *currentImageView = self.pipImageViews[capturedPipWindowID];

      if (![currentRecord isKindOfClass:NSDictionary.class] ||
          currentImageView == nil) {
        if (displayImageRef != NULL) {
          CGImageRelease(displayImageRef);
        }
        return;
      }

      NSString *currentDisplayID =
          [currentRecord[@"displayID"] isKindOfClass:NSString.class] ? currentRecord[@"displayID"] : @"";

      if (![currentDisplayID isEqualToString:capturedDisplayID]) {
        if (displayImageRef != NULL) {
          CGImageRelease(displayImageRef);
        }
        return;
      }

      NSString *currentFilter =
          [currentRecord[@"filter"] isKindOfClass:NSString.class] ? currentRecord[@"filter"] : @"none";
      NSString *normalizedCurrentFilter = [self normalizedPipFilter:currentFilter];

      if (![normalizedCurrentFilter isEqualToString:normalizedFilter]) {
        if (displayImageRef != NULL) {
          CGImageRelease(displayImageRef);
        }
        [self capturePipFrameForID:capturedPipWindowID];
        return;
      }

      if (displayImageRef == NULL) {
        NSMutableDictionary *updatedRecord = [currentRecord mutableCopy];
        updatedRecord[@"status"] = @"Capture failed";
        updatedRecord[@"lastError"] = @"Display filter unavailable";
        self.pipWindowRecords[capturedPipWindowID] = updatedRecord;
        return;
      }

      currentImageView.image = [[NSImage alloc] initWithCGImage:displayImageRef size:NSZeroSize];
      CGImageRelease(displayImageRef);
      NSMutableDictionary *updatedRecord = [currentRecord mutableCopy];
      updatedRecord[@"status"] = @"Open";
      updatedRecord[@"filter"] = normalizedCurrentFilter;
      updatedRecord[@"lastError"] = @"";
      self.pipWindowRecords[capturedPipWindowID] = updatedRecord;
    });
  });
}

