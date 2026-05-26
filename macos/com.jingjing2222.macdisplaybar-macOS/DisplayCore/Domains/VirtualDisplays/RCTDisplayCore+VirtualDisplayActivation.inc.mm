- (void)scheduleVirtualDisplayActivationRetryForID:(NSString *)virtualDisplayID wantsMirror:(BOOL)wantsMirror
{
  if (virtualDisplayID.length == 0) {
    return;
  }

  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self scheduleVirtualDisplayActivationRetryForID:virtualDisplayID wantsMirror:wantsMirror];
    });
    return;
  }

  if (self.virtualDisplayActivationAttempts[virtualDisplayID] != nil) {
    return;
  }

  self.virtualDisplayActivationAttempts[virtualDisplayID] = @0;
  [self retryVirtualDisplayActivationForID:virtualDisplayID wantsMirror:wantsMirror attempt:1];
}


- (void)retryVirtualDisplayActivationForID:(NSString *)virtualDisplayID
                               wantsMirror:(BOOL)wantsMirror
                                   attempt:(NSUInteger)attempt
{
  if (virtualDisplayID.length == 0) {
    return;
  }

  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self retryVirtualDisplayActivationForID:virtualDisplayID wantsMirror:wantsMirror attempt:attempt];
    });
    return;
  }

  const NSUInteger maxAttempts = 12;
  NSDictionary *record = self.virtualDisplayRecords[virtualDisplayID];
  id virtualDisplay = self.virtualDisplays[virtualDisplayID];

  if (![record isKindOfClass:NSDictionary.class] || virtualDisplay == nil) {
    [self.virtualDisplayActivationAttempts removeObjectForKey:virtualDisplayID];
    return;
  }

  NSString *displayID = [self visibleDisplayIDForVirtualDisplay:virtualDisplay];
  BOOL shouldMirror = wantsMirror || [record[@"mirrorMode"] isEqualToString:@"target-mirrors-virtual"];

  if (displayID.length > 0) {
    NSMutableDictionary *updatedRecord = [record mutableCopy];
    updatedRecord[@"displayID"] = displayID;
    updatedRecord[@"status"] = @"Created";
    updatedRecord[@"lastError"] = @"";

    if (shouldMirror) {
      NSString *mirrorError = nil;
      updatedRecord = [[self recordByApplyingVirtualMirrorForID:virtualDisplayID
                                                         record:updatedRecord
                                                   errorMessage:&mirrorError] mutableCopy];
    }

    self.virtualDisplayRecords[virtualDisplayID] = updatedRecord;
    [self.virtualDisplayActivationAttempts removeObjectForKey:virtualDisplayID];
    [self persistVirtualDisplayRecords];
    NSLog(@"[macDisplayBar] Virtual display activation completed: id=%@ displayID=%@ mirrored=%@ attempt=%lu",
          virtualDisplayID,
          displayID,
          [updatedRecord[@"mirrorStatus"] isEqualToString:@"Mirrored to target"] ? @"YES" : @"NO",
          (unsigned long)attempt);
    return;
  }

  if (attempt >= maxAttempts) {
    NSMutableDictionary *failedRecord = [record mutableCopy];
    failedRecord[@"status"] = @"Create failed";
    failedRecord[@"lastError"] = @"Virtual display did not appear in active display list";
    failedRecord[@"mirrorMode"] = @"none";
    failedRecord[@"mirrorStatus"] = @"Not mirrored";
    [self.virtualDisplayActivationAttempts removeObjectForKey:virtualDisplayID];
    [self.virtualDisplays removeObjectForKey:virtualDisplayID];
    self.virtualDisplayRecords[virtualDisplayID] = failedRecord;
    [self persistVirtualDisplayRecords];
    NSLog(@"[macDisplayBar] Virtual display activation failed: id=%@ attempts=%lu",
          virtualDisplayID,
          (unsigned long)attempt);
    return;
  }

  NSMutableDictionary *pendingRecord = [record mutableCopy];
  pendingRecord[@"status"] = @"Creating";
  pendingRecord[@"lastError"] = @"";
  if (shouldMirror) {
    pendingRecord[@"mirrorMode"] = @"target-mirrors-virtual";
    pendingRecord[@"mirrorStatus"] = @"Mirror pending";
  }
  self.virtualDisplayRecords[virtualDisplayID] = pendingRecord;
  self.virtualDisplayActivationAttempts[virtualDisplayID] = @(attempt);
  [self persistVirtualDisplayRecords];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self retryVirtualDisplayActivationForID:virtualDisplayID wantsMirror:wantsMirror attempt:attempt + 1];
  });
}

