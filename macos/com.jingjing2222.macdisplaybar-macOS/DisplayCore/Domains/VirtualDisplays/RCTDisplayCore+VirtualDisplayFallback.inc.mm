- (BOOL)createVirtualHiDpiFallbackForDisplayIDString:(NSString *)targetDisplayID
                                               width:(NSUInteger)width
                                              height:(NSUInteger)height
                                         refreshRate:(double)refreshRate
                                        statusReason:(NSString *)statusReason
                                        errorMessage:(NSString **)errorMessage
{
  if (![NSThread isMainThread]) {
    __block BOOL didCreateFallback = NO;
    __block NSString *capturedError = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
      didCreateFallback = [self createVirtualHiDpiFallbackForDisplayIDString:targetDisplayID
                                                                       width:width
                                                                      height:height
                                                                 refreshRate:refreshRate
                                                                statusReason:statusReason
                                                                errorMessage:&capturedError];
    });
    if (errorMessage != nil) {
      *errorMessage = capturedError;
    }
    return didCreateFallback;
  }

  if (targetDisplayID.length == 0 || width == 0 || height == 0) {
    if (errorMessage != nil) {
      *errorMessage = @"Virtual HiDPI fallback target invalid";
    }
    return NO;
  }

  for (NSString *existingVirtualDisplayID in self.virtualDisplayRecords.allKeys) {
    NSDictionary *existingRecord = self.virtualDisplayRecords[existingVirtualDisplayID];

    if (![existingRecord isKindOfClass:NSDictionary.class]) {
      continue;
    }

    BOOL matchesTarget = [existingRecord[@"targetDisplayID"] isEqualToString:targetDisplayID];
    BOOL matchesSize = [existingRecord[@"width"] unsignedIntegerValue] == width &&
        [existingRecord[@"height"] unsignedIntegerValue] == height;
    BOOL matchesRefresh = fabs([existingRecord[@"refreshRate"] doubleValue] - refreshRate) < 0.5;
    BOOL matchesScale = [existingRecord[@"isHiDpi"] boolValue];

    if (matchesTarget && matchesSize && matchesRefresh && matchesScale) {
      NSString *liveSourceDisplayID = [self visibleDisplayIDForVirtualDisplay:self.virtualDisplays[existingVirtualDisplayID]];

      if ([existingRecord[@"status"] isEqualToString:@"Creating"]) {
        NSMutableDictionary *pendingRecord = [existingRecord mutableCopy];
        pendingRecord[@"mirrorTargetDisplayID"] = targetDisplayID;
        pendingRecord[@"mirrorMode"] = @"target-mirrors-virtual";
        pendingRecord[@"mirrorStatus"] = @"Mirror pending";
        pendingRecord[@"lastError"] = @"";
        self.virtualDisplayRecords[existingVirtualDisplayID] = pendingRecord;
        [self persistVirtualDisplayRecords];
        [self scheduleVirtualDisplayActivationRetryForID:existingVirtualDisplayID wantsMirror:YES];
        if (errorMessage != nil) {
          *errorMessage = @"Virtual HiDPI fallback creating";
        }
        NSLog(@"[macDisplayBar] Generated HiDPI virtual fallback pending reuse: targetDisplayID=%@ virtualDisplayID=%@ reason=%@",
              targetDisplayID,
              existingVirtualDisplayID,
              statusReason ?: @"");
        return YES;
      }

      if (liveSourceDisplayID.length == 0 ||
          [existingRecord[@"status"] isEqualToString:@"Terminated"]) {
        NSLog(@"[macDisplayBar] Generated HiDPI virtual fallback skipped stale record: targetDisplayID=%@ virtualDisplayID=%@ status=%@",
              targetDisplayID,
              existingVirtualDisplayID,
              existingRecord[@"status"] ?: @"");
        continue;
      }

      NSString *mirrorError = nil;
      NSDictionary *updatedRecord = [self recordByApplyingVirtualMirrorForID:existingVirtualDisplayID
                                                                      record:existingRecord
                                                                errorMessage:&mirrorError];
      self.virtualDisplayRecords[existingVirtualDisplayID] = updatedRecord;
      [self persistVirtualDisplayRecords];

      BOOL didMirror = [updatedRecord[@"mirrorStatus"] isEqualToString:@"Mirrored to target"];
      if (!didMirror && errorMessage != nil) {
        *errorMessage = mirrorError ?: @"Virtual HiDPI fallback mirror failed";
      }

      NSLog(@"[macDisplayBar] Generated HiDPI virtual fallback reused: targetDisplayID=%@ virtualDisplayID=%@ width=%lu height=%lu refreshRate=%.3f mirrored=%@ reason=%@",
            targetDisplayID,
            existingVirtualDisplayID,
            (unsigned long)width,
            (unsigned long)height,
            refreshRate,
            didMirror ? @"YES" : @"NO",
            statusReason ?: @"");
      return didMirror;
    }
  }

  NSString *virtualDisplayID = [[NSUUID UUID] UUIDString];
  NSString *creationError = nil;
  NSNumber *serialNumber = @(arc4random());
  NSDictionary *record = [self createVirtualDisplayRecordWithID:virtualDisplayID
                                                targetDisplayID:targetDisplayID
                                                   serialNumber:serialNumber
                                                         width:width
                                                        height:height
                                                   refreshRate:refreshRate
                                                       isHiDpi:YES
                                                  errorMessage:&creationError];

  if (record.count == 0) {
    if (errorMessage != nil) {
      *errorMessage = creationError ?: @"Virtual HiDPI fallback creation failed";
    }
    return NO;
  }

  if ([record[@"status"] isEqualToString:@"Creating"]) {
    NSMutableDictionary *pendingRecord = [record mutableCopy];
    pendingRecord[@"mirrorTargetDisplayID"] = targetDisplayID;
    pendingRecord[@"mirrorMode"] = @"target-mirrors-virtual";
    pendingRecord[@"mirrorStatus"] = @"Mirror pending";
    pendingRecord[@"lastError"] = @"";
    self.virtualDisplayRecords[virtualDisplayID] = pendingRecord;
    [self persistVirtualDisplayRecords];
    [self scheduleVirtualDisplayActivationRetryForID:virtualDisplayID wantsMirror:YES];
    if (errorMessage != nil) {
      *errorMessage = @"Virtual HiDPI fallback creating";
    }
    NSLog(@"[macDisplayBar] Generated HiDPI virtual fallback pending activation: targetDisplayID=%@ virtualDisplayID=%@ width=%lu height=%lu refreshRate=%.3f reason=%@",
          targetDisplayID,
          virtualDisplayID,
          (unsigned long)width,
          (unsigned long)height,
          refreshRate,
          statusReason ?: @"");
    return YES;
  }

  NSString *mirrorError = nil;
  NSDictionary *updatedRecord = [self recordByApplyingVirtualMirrorForID:virtualDisplayID
                                                                  record:record
                                                            errorMessage:&mirrorError];
  self.virtualDisplayRecords[virtualDisplayID] = updatedRecord;
  [self persistVirtualDisplayRecords];

  BOOL didMirror = [updatedRecord[@"mirrorStatus"] isEqualToString:@"Mirrored to target"];
  if (!didMirror && errorMessage != nil) {
    *errorMessage = mirrorError ?: @"Virtual HiDPI fallback mirror failed";
  }
  if (!didMirror) {
    [self removeVirtualDisplay:virtualDisplayID];
  }

  NSLog(@"[macDisplayBar] Generated HiDPI virtual fallback created: targetDisplayID=%@ virtualDisplayID=%@ width=%lu height=%lu refreshRate=%.3f mirrored=%@ reason=%@",
        targetDisplayID,
        virtualDisplayID,
        (unsigned long)width,
        (unsigned long)height,
        refreshRate,
        didMirror ? @"YES" : @"NO",
        statusReason ?: @"");
  return didMirror;
}

