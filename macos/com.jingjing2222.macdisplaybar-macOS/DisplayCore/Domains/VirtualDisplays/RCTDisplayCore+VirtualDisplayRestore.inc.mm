- (void)restoreManagedVirtualDisplays
{
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self restoreManagedVirtualDisplays];
    });
    return;
  }

  NSArray<NSString *> *virtualDisplayIDs =
      [self.virtualDisplayRecords.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *leftID, NSString *rightID) {
        NSDictionary *leftRecord = self.virtualDisplayRecords[leftID];
        NSDictionary *rightRecord = self.virtualDisplayRecords[rightID];
        double leftUpdatedAt = [leftRecord[@"mirrorUpdatedAt"] doubleValue];
        double rightUpdatedAt = [rightRecord[@"mirrorUpdatedAt"] doubleValue];

        if (leftUpdatedAt > rightUpdatedAt) {
          return NSOrderedAscending;
        }

        if (leftUpdatedAt < rightUpdatedAt) {
          return NSOrderedDescending;
        }

        return [leftID compare:rightID];
      }];
  NSMutableSet<NSString *> *restoredMirrorTargets = [NSMutableSet new];

  for (NSString *virtualDisplayID in virtualDisplayIDs) {
    NSDictionary *record = self.virtualDisplayRecords[virtualDisplayID];

    if (![record isKindOfClass:NSDictionary.class] || [record[@"status"] isEqualToString:@"Create failed"]) {
      continue;
    }

    NSString *errorMessage = nil;
    NSString *resolvedTargetDisplayID = [self resolvedVirtualTargetDisplayIDForRecord:record];

    if (resolvedTargetDisplayID.length == 0) {
      NSMutableDictionary *pausedRecord = [record mutableCopy];
      pausedRecord[@"displayID"] = @"";
      pausedRecord[@"mirrorTargetDisplayID"] = @"";
      pausedRecord[@"mirrorSourceDisplayID"] = @"";
      pausedRecord[@"mirrorMode"] = @"none";
      pausedRecord[@"mirrorStatus"] = @"Not mirrored";
      pausedRecord[@"status"] = @"Paused";
      pausedRecord[@"lastError"] = @"Target unavailable";
      self.virtualDisplayRecords[virtualDisplayID] = pausedRecord;
      continue;
    }

    NSDictionary *restoredRecord = [self createVirtualDisplayRecordWithID:virtualDisplayID
                                                   targetDisplayID:resolvedTargetDisplayID
                                                      serialNumber:record[@"serialNumber"] ?: @(arc4random())
                                                            width:[record[@"width"] doubleValue]
                                                           height:[record[@"height"] doubleValue]
                                                      refreshRate:[record[@"refreshRate"] doubleValue]
                                                          isHiDpi:[record[@"isHiDpi"] boolValue]
                                                     errorMessage:&errorMessage];

    if (restoredRecord.count > 0) {
      NSMutableDictionary *restoredMutableRecord = [restoredRecord mutableCopy];
      restoredMutableRecord[@"targetIdentityKey"] = [record[@"targetIdentityKey"] isKindOfClass:NSString.class]
          ? record[@"targetIdentityKey"]
          : @"";
      restoredRecord = restoredMutableRecord;

      NSString *mirrorMode = [record[@"mirrorMode"] isKindOfClass:NSString.class] ? record[@"mirrorMode"] : @"";
      NSString *mirrorTargetDisplayID = [record[@"mirrorTargetDisplayID"] isKindOfClass:NSString.class]
          ? record[@"mirrorTargetDisplayID"]
          : @"";
      NSString *resolvedMirrorTargetDisplayID = @"";

      if ([mirrorMode isEqualToString:@"target-mirrors-virtual"] && mirrorTargetDisplayID.length > 0) {
        resolvedMirrorTargetDisplayID = [self resolvedVirtualMirrorTargetDisplayIDForRecord:restoredRecord
                                                                                  restoring:YES
                                                                               errorMessage:&errorMessage];
      }

      BOOL wantsMirrorRestore = [mirrorMode isEqualToString:@"target-mirrors-virtual"] &&
          resolvedMirrorTargetDisplayID.length > 0 &&
          ![restoredMirrorTargets containsObject:resolvedMirrorTargetDisplayID];

      if (wantsMirrorRestore && [restoredRecord[@"status"] isEqualToString:@"Creating"]) {
        NSMutableDictionary *pendingRecord = [restoredRecord mutableCopy];
        pendingRecord[@"mirrorTargetDisplayID"] = resolvedMirrorTargetDisplayID;
        pendingRecord[@"mirrorMode"] = @"target-mirrors-virtual";
        pendingRecord[@"mirrorStatus"] = @"Mirror pending";
        pendingRecord[@"lastError"] = @"";
        restoredRecord = pendingRecord;
        [self scheduleVirtualDisplayActivationRetryForID:virtualDisplayID wantsMirror:YES];
      } else if (wantsMirrorRestore) {
        restoredRecord = [self recordByApplyingVirtualMirrorForID:virtualDisplayID
                                                           record:restoredRecord
                                                        restoring:YES
                                                     errorMessage:&errorMessage];
        if ([restoredRecord[@"mirrorStatus"] isEqualToString:@"Mirrored to target"]) {
          [restoredMirrorTargets addObject:restoredRecord[@"mirrorTargetDisplayID"] ?: resolvedMirrorTargetDisplayID];
        }
      } else {
        NSMutableDictionary *stoppedRecord = [restoredRecord mutableCopy];
        stoppedRecord[@"mirrorTargetDisplayID"] = @"";
        stoppedRecord[@"mirrorSourceDisplayID"] = @"";
        stoppedRecord[@"mirrorMode"] = @"none";
        stoppedRecord[@"mirrorStatus"] = @"Not mirrored";
        stoppedRecord[@"lastError"] = @"";
        restoredRecord = stoppedRecord;
      }

      self.virtualDisplayRecords[virtualDisplayID] = restoredRecord;
      if ([restoredRecord[@"status"] isEqualToString:@"Creating"]) {
        [self scheduleVirtualDisplayActivationRetryForID:virtualDisplayID
                                             wantsMirror:[restoredRecord[@"mirrorMode"] isEqualToString:@"target-mirrors-virtual"]];
      }
    } else {
      self.virtualDisplayRecords[virtualDisplayID] =
          [self virtualDisplayRecordWithID:virtualDisplayID
                           targetDisplayID:resolvedTargetDisplayID.length > 0 ? resolvedTargetDisplayID : (record[@"targetDisplayID"] ?: @"")
                                 displayID:@""
                    mirrorTargetDisplayID:@""
                    mirrorSourceDisplayID:@""
                                 mirrorMode:@"none"
                               mirrorStatus:@"Not mirrored"
                                      name:record[@"name"] ?: @"macDisplayBar Virtual Display"
                              serialNumber:record[@"serialNumber"] ?: @(arc4random())
                                     width:[record[@"width"] doubleValue]
                                    height:[record[@"height"] doubleValue]
                               refreshRate:[record[@"refreshRate"] doubleValue]
                                   isHiDpi:[record[@"isHiDpi"] boolValue]
                                    status:@"Restore failed"
                                 lastError:errorMessage ?: @"Virtual display restore failed"];
    }
  }

  [self persistVirtualDisplayRecords];
}

