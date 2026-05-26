- (BOOL)configureDisplayID:(CGDirectDisplayID)displayID
           mirrorOfDisplay:(CGDirectDisplayID)sourceDisplayID
              errorMessage:(NSString **)errorMessage
{
  if (displayID == 0) {
    if (errorMessage != nil) {
      *errorMessage = @"Mirror target display is unavailable";
    }

    return NO;
  }

  CGDisplayConfigRef config = NULL;
  CGError beginError = CGBeginDisplayConfiguration(&config);

  if (beginError != kCGErrorSuccess || config == NULL) {
    if (errorMessage != nil) {
      *errorMessage = [NSString stringWithFormat:@"Mirror configuration start failed: 0x%08x", beginError];
    }

    return NO;
  }

  CGError mirrorError = CGConfigureDisplayMirrorOfDisplay(config, displayID, sourceDisplayID);

  if (mirrorError != kCGErrorSuccess) {
    CGCancelDisplayConfiguration(config);
    if (errorMessage != nil) {
      *errorMessage = [NSString stringWithFormat:@"Mirror configuration failed: 0x%08x", mirrorError];
    }

    NSLog(@"[macDisplayBar] Virtual display mirror configuration failed: target=%u source=%u error=0x%08x",
          displayID,
          sourceDisplayID,
          mirrorError);
    return NO;
  }

  CGError completeError = CGCompleteDisplayConfiguration(config, kCGConfigureForSession);

  if (completeError != kCGErrorSuccess) {
    if (errorMessage != nil) {
      *errorMessage = [NSString stringWithFormat:@"Mirror apply failed: 0x%08x", completeError];
    }

    NSLog(@"[macDisplayBar] Virtual display mirror apply failed: target=%u source=%u error=0x%08x",
          displayID,
          sourceDisplayID,
          completeError);
    return NO;
  }

  CGDirectDisplayID actualSourceDisplayID = CGDisplayMirrorsDisplay(displayID);
  if (actualSourceDisplayID != sourceDisplayID) {
    if (errorMessage != nil) {
      *errorMessage = [NSString stringWithFormat:@"Mirror post-check failed: expected %u actual %u",
                                                 sourceDisplayID,
                                                 actualSourceDisplayID];
    }

    NSLog(@"[macDisplayBar] Virtual display mirror post-check failed: target=%u expectedSource=%u actualSource=%u",
          displayID,
          sourceDisplayID,
          actualSourceDisplayID);
    return NO;
  }

  NSLog(@"[macDisplayBar] Virtual display mirror configured: target=%u source=%u",
        displayID,
        sourceDisplayID);
  return YES;
}


- (NSDictionary *)recordByApplyingVirtualMirrorForID:(NSString *)virtualDisplayID
                                              record:(NSDictionary *)record
                                        errorMessage:(NSString **)errorMessage
{
  return [self recordByApplyingVirtualMirrorForID:virtualDisplayID
                                           record:record
                                        restoring:NO
                                     errorMessage:errorMessage];
}


- (NSDictionary *)recordByApplyingVirtualMirrorForID:(NSString *)virtualDisplayID
                                              record:(NSDictionary *)record
                                           restoring:(BOOL)restoring
                                        errorMessage:(NSString **)errorMessage
{
  NSString *targetDisplayID = [self resolvedVirtualMirrorTargetDisplayIDForRecord:record
                                                                        restoring:restoring
                                                                     errorMessage:errorMessage];
  NSString *sourceDisplayID = [record[@"displayID"] isKindOfClass:NSString.class] ? record[@"displayID"] : @"";
  NSMutableDictionary *updatedRecord = [record mutableCopy];
  NSString *liveSourceDisplayID = [self visibleDisplayIDForVirtualDisplay:self.virtualDisplays[virtualDisplayID]];

  if (targetDisplayID.length > 0) {
    updatedRecord[@"targetDisplayID"] = targetDisplayID;
    updatedRecord[@"targetIdentityKey"] = [self identityKeyForDisplayID:(CGDirectDisplayID)targetDisplayID.integerValue];
  }

  if (liveSourceDisplayID.length > 0 && ![liveSourceDisplayID isEqualToString:sourceDisplayID]) {
    sourceDisplayID = liveSourceDisplayID;
    updatedRecord[@"displayID"] = liveSourceDisplayID;
  }

  if (targetDisplayID.length == 0 || sourceDisplayID.length == 0) {
    updatedRecord[@"mirrorTargetDisplayID"] = @"";
    updatedRecord[@"mirrorSourceDisplayID"] = @"";
    updatedRecord[@"mirrorMode"] = @"none";
    updatedRecord[@"mirrorStatus"] = @"Not mirrored";
    return updatedRecord;
  }

  BOOL didMirror = [self configureDisplayID:(CGDirectDisplayID)targetDisplayID.integerValue
                            mirrorOfDisplay:(CGDirectDisplayID)sourceDisplayID.integerValue
                               errorMessage:errorMessage];

  updatedRecord[@"mirrorTargetDisplayID"] = didMirror ? targetDisplayID : (record[@"mirrorTargetDisplayID"] ?: @"");
  updatedRecord[@"mirrorSourceDisplayID"] = didMirror ? sourceDisplayID : (record[@"mirrorSourceDisplayID"] ?: @"");
  updatedRecord[@"mirrorMode"] = didMirror ? @"target-mirrors-virtual" : (record[@"mirrorMode"] ?: @"none");
  updatedRecord[@"mirrorStatus"] = didMirror ? @"Mirrored to target" : @"Mirror failed";
  updatedRecord[@"status"] = didMirror ? @"Created and mirrored" : (record[@"status"] ?: @"Created");
  if (didMirror) {
    updatedRecord[@"mirrorUpdatedAt"] = @([[NSDate date] timeIntervalSince1970]);
  }
  NSString *mirrorError = errorMessage != nil ? *errorMessage : nil;
  updatedRecord[@"lastError"] = didMirror ? @"" : (mirrorError ?: @"Virtual display mirror failed");

  if (didMirror) {
    for (NSString *otherVirtualDisplayID in self.virtualDisplayRecords.allKeys) {
      if ([otherVirtualDisplayID isEqualToString:virtualDisplayID]) {
        continue;
      }

      NSDictionary *otherRecord = self.virtualDisplayRecords[otherVirtualDisplayID];
      if (![otherRecord isKindOfClass:NSDictionary.class]) {
        continue;
      }

      NSString *otherMirrorTargetID = [otherRecord[@"mirrorTargetDisplayID"] isKindOfClass:NSString.class]
          ? otherRecord[@"mirrorTargetDisplayID"]
          : @"";

      if (![otherMirrorTargetID isEqualToString:targetDisplayID]) {
        continue;
      }

      NSMutableDictionary *clearedRecord = [otherRecord mutableCopy];
      clearedRecord[@"mirrorTargetDisplayID"] = @"";
      clearedRecord[@"mirrorSourceDisplayID"] = @"";
      clearedRecord[@"mirrorMode"] = @"none";
      clearedRecord[@"mirrorStatus"] = @"Not mirrored";
      clearedRecord[@"lastError"] = @"";
      self.virtualDisplayRecords[otherVirtualDisplayID] = clearedRecord;
      NSLog(@"[macDisplayBar] Virtual display mirror stale record cleared: activeID=%@ staleID=%@ target=%@",
            virtualDisplayID,
            otherVirtualDisplayID,
            targetDisplayID);
    }
  }

  return updatedRecord;
}


- (NSString *)resolvedVirtualMirrorTargetDisplayIDForRecord:(NSDictionary *)record
                                                  restoring:(BOOL)restoring
                                               errorMessage:(NSString **)errorMessage
{
  NSString *targetDisplayID = [record[@"targetDisplayID"] isKindOfClass:NSString.class] ? record[@"targetDisplayID"] : @"";
  NSString *targetIdentityKey = [record[@"targetIdentityKey"] isKindOfClass:NSString.class] ? record[@"targetIdentityKey"] : @"";

  if (targetIdentityKey.length > 0) {
    NSString *matchedDisplayID = [self activeDisplayIDStringForIdentityKey:targetIdentityKey];

    if (matchedDisplayID.length > 0) {
      return matchedDisplayID;
    }

    if (errorMessage != nil) {
      *errorMessage = @"Virtual mirror target identity unavailable";
    }

    NSLog(@"[macDisplayBar] Virtual display mirror target identity unavailable: storedTarget=%@ identityKey=%@ restoring=%@",
          targetDisplayID,
          targetIdentityKey,
          restoring ? @"YES" : @"NO");
    return @"";
  }

  if (restoring) {
    if (errorMessage != nil) {
      *errorMessage = @"Virtual mirror restore skipped because target identity is missing";
    }

    NSLog(@"[macDisplayBar] Virtual display mirror restore skipped: target identity missing storedTarget=%@",
          targetDisplayID);
    return @"";
  }

  if (![self activeDisplayListContainsDisplayID:(CGDirectDisplayID)targetDisplayID.integerValue]) {
    if (errorMessage != nil) {
      *errorMessage = @"Virtual mirror target display unavailable";
    }

    NSLog(@"[macDisplayBar] Virtual display mirror target unavailable: storedTarget=%@",
          targetDisplayID);
    return @"";
  }

  return targetDisplayID;
}


- (NSString *)resolvedVirtualTargetDisplayIDForRecord:(NSDictionary *)record
{
  NSString *targetDisplayID = [record[@"targetDisplayID"] isKindOfClass:NSString.class] ? record[@"targetDisplayID"] : @"";
  NSString *targetIdentityKey = [record[@"targetIdentityKey"] isKindOfClass:NSString.class] ? record[@"targetIdentityKey"] : @"";

  if (targetIdentityKey.length > 0) {
    NSString *matchedDisplayID = [self activeDisplayIDStringForIdentityKey:targetIdentityKey];

    if (matchedDisplayID.length > 0) {
      return matchedDisplayID;
    }

    NSLog(@"[macDisplayBar] Virtual display target identity unavailable: storedTarget=%@ identityKey=%@",
          targetDisplayID,
          targetIdentityKey);
    return @"";
  }

  if ([self displayIDStringIsActive:targetDisplayID]) {
    return targetDisplayID;
  }

  return @"";
}

