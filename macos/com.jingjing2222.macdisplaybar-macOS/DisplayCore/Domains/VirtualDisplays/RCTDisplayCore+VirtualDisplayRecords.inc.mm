- (NSDictionary *)virtualDisplayRecordWithID:(NSString *)virtualDisplayID
                             targetDisplayID:(NSString *)targetDisplayID
                                   displayID:(NSString *)displayID
                      mirrorTargetDisplayID:(NSString *)mirrorTargetDisplayID
                      mirrorSourceDisplayID:(NSString *)mirrorSourceDisplayID
                                   mirrorMode:(NSString *)mirrorMode
                                 mirrorStatus:(NSString *)mirrorStatus
                                        name:(NSString *)name
                                serialNumber:(NSNumber *)serialNumber
                                       width:(double)width
                                      height:(double)height
                                 refreshRate:(double)refreshRate
                                     isHiDpi:(BOOL)isHiDpi
                                      status:(NSString *)status
                                   lastError:(NSString *)lastError
{
  return @{
    @"id" : virtualDisplayID ?: @"",
    @"targetDisplayID" : targetDisplayID ?: @"",
    @"targetIdentityKey" : [self displayIDStringIsActive:targetDisplayID ?: @""]
        ? [self identityKeyForDisplayID:(CGDirectDisplayID)targetDisplayID.integerValue]
        : @"",
    @"displayID" : displayID ?: @"",
    @"mirrorTargetDisplayID" : mirrorTargetDisplayID ?: @"",
    @"mirrorSourceDisplayID" : mirrorSourceDisplayID ?: @"",
    @"mirrorMode" : mirrorMode ?: @"none",
    @"mirrorStatus" : mirrorStatus ?: @"Not mirrored",
    @"mirrorUpdatedAt" : @0,
    @"name" : name ?: @"macDisplayBar Virtual Display",
    @"serialNumber" : @(serialNumber.unsignedIntValue),
    @"width" : @(MAX(width, 1)),
    @"height" : @(MAX(height, 1)),
    @"refreshRate" : @(refreshRate > 0 ? refreshRate : 60),
    @"isHiDpi" : @(isHiDpi),
    @"status" : status ?: @"Unknown",
    @"lastError" : lastError ?: @"",
  };
}


- (NSString *)visibleDisplayIDForVirtualDisplay:(id)virtualDisplay
{
  SEL displayIDSelector = RCTDisplayPrivateSelector(@"displayID");

  if (virtualDisplay == nil || ![virtualDisplay respondsToSelector:displayIDSelector]) {
    return @"";
  }

  NSUInteger maxAttempts = [NSThread isMainThread] ? 1 : 10;

  for (NSUInteger attempt = 0; attempt < maxAttempts; attempt++) {
    if (attempt > 0) {
      [NSThread sleepForTimeInterval:0.1];
    }

    unsigned int directDisplayID = ((unsigned int (*)(id, SEL))objc_msgSend)(virtualDisplay, displayIDSelector);

    if (directDisplayID != 0 && [self activeDisplayListContainsDisplayID:directDisplayID]) {
      return [NSString stringWithFormat:@"%u", directDisplayID];
    }
  }

  return @"";
}


- (NSArray<NSDictionary *> *)virtualDisplaySummaries
{
  if (![NSThread isMainThread]) {
    __block NSArray<NSDictionary *> *summaries = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
      summaries = [self virtualDisplaySummaries];
    });
    return summaries ?: @[];
  }

  NSMutableArray<NSDictionary *> *summaries = [NSMutableArray arrayWithCapacity:self.virtualDisplayRecords.count];

  for (NSString *virtualDisplayID in self.virtualDisplayRecords) {
    NSDictionary *record = self.virtualDisplayRecords[virtualDisplayID];

    if ([record isKindOfClass:NSDictionary.class]) {
      NSMutableDictionary *summary = [record mutableCopy];
      NSString *resolvedTargetDisplayID = [self resolvedVirtualTargetDisplayIDForRecord:record];

      if (resolvedTargetDisplayID.length > 0) {
        summary[@"targetDisplayID"] = resolvedTargetDisplayID;
      }

      [summaries addObject:summary];
    }
  }

  [summaries sortUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
    return [left[@"name"] compare:right[@"name"]];
  }];

  return summaries;
}


- (void)persistVirtualDisplayRecords
{
  [[NSUserDefaults standardUserDefaults] setObject:self.virtualDisplayRecords
                                            forKey:RCTDisplayVirtualDisplaysDefaultsKey];
}

