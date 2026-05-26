- (BOOL)installOverrideBundleAtPath:(NSString *)bundlePath errorMessage:(NSString **)errorMessage
{
  return [self installOverrideBundleAtPath:bundlePath
                           displayIDString:@""
                                 didMutate:nil
                              errorMessage:errorMessage];
}


- (BOOL)installOverrideBundleAtPath:(NSString *)bundlePath
                    displayIDString:(NSString *)displayID
                          didMutate:(BOOL *)didMutate
                       errorMessage:(NSString **)errorMessage
{
  if (didMutate != nil) {
    *didMutate = NO;
  }

  NSURL *sourceURL = [NSURL fileURLWithPath:bundlePath];
  NSString *vendorDirectoryName = sourceURL.URLByDeletingLastPathComponent.lastPathComponent;
  NSString *productFileName = sourceURL.lastPathComponent;

  if (vendorDirectoryName.length == 0 || productFileName.length == 0) {
    if (errorMessage != nil) {
      *errorMessage = @"Display override bundle path invalid";
    }
    return NO;
  }

  NSURL *targetDirectoryURL =
      [[NSURL fileURLWithPath:RCTDisplayOverrideInstallDirectory isDirectory:YES]
          URLByAppendingPathComponent:vendorDirectoryName
                          isDirectory:YES];
  NSURL *targetFileURL = [targetDirectoryURL URLByAppendingPathComponent:productFileName];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *directError = nil;
  BOOL targetExists = [fileManager fileExistsAtPath:targetFileURL.path];
  BOOL sourceMatchesTarget = targetExists && [fileManager contentsEqualAtPath:sourceURL.path andPath:targetFileURL.path];
  NSString *storedInstalledHash = displayID.length > 0 ? (self.overrideInstalledHashes[displayID] ?: @"") : @"";
  NSString *storedInstalledPath = displayID.length > 0 ? (self.overrideInstalledPaths[displayID] ?: @"") : @"";
  NSString *currentTargetHash = targetExists ? MDBSHA256FileHash(targetFileURL.path) : @"";
  BOOL targetMatchesStoredInstall = storedInstalledHash.length > 0 && [currentTargetHash isEqualToString:storedInstalledHash];
  BOOL storedTargetExists = storedInstalledPath.length > 0;
  NSString *stagedBackupPath = @"";
  NSString *stagedBackupHash = @"";

  NSLog(@"[macDisplayBar] Display override install start: source=%@ target=%@",
        sourceURL.path,
        targetFileURL.path);

  if (storedTargetExists && ![storedInstalledPath isEqualToString:targetFileURL.path]) {
    NSLog(@"[macDisplayBar] Display override install refused: display target identity changed displayID=%@ storedTarget=%@ currentTarget=%@",
          displayID,
          storedInstalledPath,
          targetFileURL.path);

    if (errorMessage != nil) {
      *errorMessage = @"Display override target identity changed";
    }

    return NO;
  }

  if (targetExists && storedInstalledHash.length > 0 && !targetMatchesStoredInstall) {
    NSLog(@"[macDisplayBar] Display override install refused: target changed externally displayID=%@ target=%@ storedHash=%@ currentHash=%@",
          displayID,
          targetFileURL.path,
          storedInstalledHash,
          currentTargetHash);

    if (errorMessage != nil) {
      *errorMessage = @"Installed override changed externally";
    }

    return NO;
  }

  if (sourceMatchesTarget) {
    if (targetExists && displayID.length > 0 && storedInstalledHash.length > 0) {
      self.overrideInstalledPaths[displayID] = targetFileURL.path;
      self.overrideInstalledHashes[displayID] = currentTargetHash;
      [self.overrideLastErrors removeObjectForKey:displayID];
      NSLog(@"[macDisplayBar] Display override install adopted matching managed target: displayID=%@ target=%@",
            displayID,
            targetFileURL.path);
    } else if (targetExists && displayID.length > 0 && storedInstalledHash.length == 0) {
      [self.overrideLastErrors removeObjectForKey:displayID];
      NSLog(@"[macDisplayBar] Display override install found externally matching target: displayID=%@ target=%@ hash=%@",
            displayID,
            targetFileURL.path,
            currentTargetHash);
    }

    NSLog(@"[macDisplayBar] Display override install skipped: target already matches source=%@",
          targetFileURL.path);
    return YES;
  }

  if (targetExists && self.overrideBackupPaths[displayID].length > 0 && storedInstalledHash.length == 0) {
    NSLog(@"[macDisplayBar] Display override install refused: managed hash missing displayID=%@ target=%@",
          displayID,
          targetFileURL.path);

    if (errorMessage != nil) {
      *errorMessage = @"Installed override ownership hash missing";
    }

    return NO;
  }

  BOOL needsBackup = targetExists && displayID.length > 0 && self.overrideBackupPaths[displayID].length == 0;

  if (needsBackup) {
    NSString *backupPath = [self backupPathForOverrideTargetURL:targetFileURL displayIDString:displayID];

    if (backupPath.length == 0 || ![fileManager copyItemAtPath:targetFileURL.path toPath:backupPath error:&directError]) {
      NSLog(@"[macDisplayBar] Display override backup failed: target=%@ backup=%@ error=%@",
            targetFileURL.path,
            backupPath,
            directError.localizedDescription ?: @"");

      if (errorMessage != nil) {
        *errorMessage = directError.localizedDescription ?: @"Display override backup failed";
      }

      return NO;
    }

    stagedBackupPath = backupPath;
    stagedBackupHash = MDBSHA256FileHash(backupPath);
    NSLog(@"[macDisplayBar] Display override backup created: displayID=%@ target=%@ backup=%@",
          displayID,
          targetFileURL.path,
          backupPath);
  }

  [fileManager createDirectoryAtURL:targetDirectoryURL
        withIntermediateDirectories:YES
                         attributes:nil
                              error:&directError];

  if (directError == nil) {
    NSURL *directTempURL = [targetDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@".%@.%@.tmp",
                                                                                                      productFileName,
                                                                                                      [[NSUUID UUID] UUIDString]]];

    [fileManager removeItemAtURL:directTempURL error:nil];

    if ([fileManager copyItemAtURL:sourceURL toURL:directTempURL error:&directError] &&
        [fileManager replaceItemAtURL:targetFileURL
                         withItemAtURL:directTempURL
                        backupItemName:nil
                               options:0
                      resultingItemURL:nil
                                 error:&directError]) {
      NSLog(@"[macDisplayBar] Display override direct install verified: target=%@",
            targetFileURL.path);
      if (stagedBackupPath.length > 0) {
        self.overrideBackupPaths[displayID] = stagedBackupPath;
        self.overrideBackupHashes[displayID] = stagedBackupHash;
      }
      if (didMutate != nil) {
        *didMutate = YES;
      }
      return YES;
    }

    [fileManager removeItemAtURL:directTempURL error:nil];
  }

  NSLog(@"[macDisplayBar] Display override direct install failed: target=%@ error=%@",
        targetFileURL.path,
        directError.localizedDescription ?: @"");

  NSURL *stagedDirectoryURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
      URLByAppendingPathComponent:[NSString stringWithFormat:@"macDisplayBar-overrides/%@", [[NSUUID UUID] UUIDString]]
                      isDirectory:YES];
  NSURL *stagedSourceURL = [stagedDirectoryURL URLByAppendingPathComponent:productFileName];
  NSError *stagingError = nil;

  [fileManager createDirectoryAtURL:stagedDirectoryURL
        withIntermediateDirectories:YES
                         attributes:nil
                              error:&stagingError];

  if (stagingError == nil) {
    [fileManager copyItemAtURL:sourceURL toURL:stagedSourceURL error:&stagingError];
  }

  if (stagingError != nil) {
    NSLog(@"[macDisplayBar] Display override privileged install staging failed: source=%@ error=%@",
          sourceURL.path,
          stagingError.localizedDescription ?: @"");

    if (errorMessage != nil) {
      *errorMessage = stagingError.localizedDescription ?: @"Display override staging failed";
    }

    [fileManager removeItemAtURL:stagedDirectoryURL error:nil];
    return NO;
  }

  NSLog(@"[macDisplayBar] Display override privileged install staged source: source=%@ stagedSource=%@",
        sourceURL.path,
        stagedSourceURL.path);

  NSString *targetTempPath = [targetFileURL.path stringByAppendingFormat:@".%@.tmp", [[NSUUID UUID] UUIDString]];
  NSString *expectedStagedSourceHash = MDBSHA256FileHash(stagedSourceURL.path);
  NSString *stagedSourceHashCommand = MDBShellSHA256SizeCommand(stagedSourceURL.path);
  NSString *stagedSourcePrecondition = [NSString stringWithFormat:@"if /bin/test ! -f %@ || /bin/test \"%@\" != %@; then exit 75; fi",
                                                                  MDBShellQuotedString(stagedSourceURL.path),
                                                                  expectedStagedSourceHash,
                                                                  stagedSourceHashCommand];
  NSString *expectedTargetHash = targetExists ? currentTargetHash : @"";
  NSString *targetHashCommand = MDBShellSHA256SizeCommand(targetFileURL.path);
  NSString *targetPrecondition = targetExists
      ? [NSString stringWithFormat:@"if /bin/test ! -f %@ || /bin/test \"%@\" != %@; then exit 73; fi",
                                   MDBShellQuotedString(targetFileURL.path),
                                   expectedTargetHash,
                                   targetHashCommand]
      : [NSString stringWithFormat:@"if /bin/test -e %@; then exit 74; fi",
                                   MDBShellQuotedString(targetFileURL.path)];
  NSString *command = [NSString stringWithFormat:@"/bin/mkdir -p %@ && %@ && %@ && /usr/bin/install -o root -g wheel -m 0644 %@ %@ && /bin/mv -f %@ %@",
                                                 MDBShellQuotedString(targetDirectoryURL.path),
                                                 targetPrecondition,
                                                 stagedSourcePrecondition,
                                                 MDBShellQuotedString(stagedSourceURL.path),
                                                 MDBShellQuotedString(targetTempPath),
                                                 MDBShellQuotedString(targetTempPath),
                                                 MDBShellQuotedString(targetFileURL.path)];
  NSString *script = [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges",
                                                MDBAppleScriptQuotedString(command)];
  NSTask *task = [NSTask new];
  NSPipe *errorPipe = [NSPipe pipe];

  task.launchPath = @"/usr/bin/osascript";
  task.arguments = @[ @"-e", script ];
  task.standardError = errorPipe;

  @try {
    [[NSNotificationCenter defaultCenter] postNotificationName:RCTDisplayPrivilegedInstallWillBeginNotification
                                                        object:self];
    [task launch];
    [task waitUntilExit];
  } @catch (NSException *exception) {
    NSLog(@"[macDisplayBar] Display override privileged install exception: target=%@ reason=%@",
          targetFileURL.path,
          exception.reason ?: @"");
    if (errorMessage != nil) {
      *errorMessage = exception.reason ?: @"Privileged override install failed";
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:RCTDisplayPrivilegedInstallDidEndNotification
                                                        object:self];
    [fileManager removeItemAtURL:stagedDirectoryURL error:nil];
    return NO;
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:RCTDisplayPrivilegedInstallDidEndNotification
                                                      object:self];

  if (task.terminationStatus == 0) {
    BOOL targetMatches = [fileManager contentsEqualAtPath:stagedSourceURL.path andPath:targetFileURL.path];

    if (!targetMatches) {
      NSLog(@"[macDisplayBar] Display override privileged install verification failed: target=%@",
            targetFileURL.path);

      if (errorMessage != nil) {
        *errorMessage = @"installed override contents do not match source";
      }

      [fileManager removeItemAtURL:stagedDirectoryURL error:nil];
      return NO;
    }

    NSLog(@"[macDisplayBar] Display override privileged install verified: target=%@",
          targetFileURL.path);
    if (stagedBackupPath.length > 0) {
      self.overrideBackupPaths[displayID] = stagedBackupPath;
      self.overrideBackupHashes[displayID] = stagedBackupHash;
    }
    if (didMutate != nil) {
      *didMutate = YES;
    }
    [fileManager removeItemAtURL:stagedDirectoryURL error:nil];
    return YES;
  }

  NSData *errorData = [errorPipe.fileHandleForReading readDataToEndOfFile];
  NSString *privilegedError =
      [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
  NSString *fallbackError = directError.localizedDescription ?: @"Privileged override install failed";

  NSLog(@"[macDisplayBar] Display override privileged install failed: status=%d target=%@ stderr=%@ directError=%@",
        task.terminationStatus,
        targetFileURL.path,
        privilegedError ?: @"",
        directError.localizedDescription ?: @"");

  if (errorMessage != nil) {
    *errorMessage = privilegedError.length > 0 ? privilegedError : fallbackError;
  }

  [fileManager removeItemAtURL:stagedDirectoryURL error:nil];
  return NO;
}


- (BOOL)removeInstalledOverrideForDisplayIDString:(NSString *)displayID errorMessage:(NSString **)errorMessage
{
  NSURL *targetFileURL = [self overrideTargetFileURLForLifecycleKey:displayID];
  NSString *installedPath = self.overrideInstalledPaths[displayID] ?: @"";
  NSString *bundlePath = self.overrideBundlePaths[displayID] ?: @"";
  NSString *backupPath = self.overrideBackupPaths[displayID] ?: @"";
  NSString *installedHash = self.overrideInstalledHashes[displayID] ?: @"";
  NSString *backupHash = self.overrideBackupHashes[displayID] ?: @"";
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL targetExists = targetFileURL.path.length > 0 && [fileManager fileExistsAtPath:targetFileURL.path];

  if (targetFileURL.path.length == 0) {
    if (errorMessage != nil) {
      *errorMessage = @"Display override target path invalid";
    }
    return NO;
  }

  if (targetExists && installedHash.length == 0 && backupPath.length == 0) {
    if (errorMessage != nil) {
      *errorMessage = @"Installed override is not managed by macDisplayBar";
    }
    NSLog(@"[macDisplayBar] Display override remove refused: unmanaged target displayID=%@ target=%@ installedPath=%@ bundlePath=%@",
          displayID,
          targetFileURL.path,
          installedPath,
          bundlePath);
    return NO;
  }

  if (installedPath.length > 0 && ![installedPath isEqualToString:targetFileURL.path]) {
    if (errorMessage != nil) {
      *errorMessage = @"Display override target identity changed";
    }
    NSLog(@"[macDisplayBar] Display override remove refused: displayID=%@ storedTarget=%@ currentTarget=%@",
          displayID,
          installedPath,
          targetFileURL.path);
    return NO;
  }

  if (!targetExists && backupPath.length == 0) {
    return YES;
  }

  BOOL targetMatchesInstalledHash = targetExists && MDBFileMatchesStoredHash(targetFileURL.path, installedHash);

  if (targetExists && !targetMatchesInstalledHash) {
    if (errorMessage != nil) {
      *errorMessage = @"Installed override is not managed by macDisplayBar";
    }
    NSLog(@"[macDisplayBar] Display override remove refused: displayID=%@ target=%@ installedPath=%@ bundlePath=%@ installedHash=%@ currentHash=%@",
          displayID,
          targetFileURL.path,
          installedPath,
          bundlePath,
          installedHash,
          MDBSHA256FileHash(targetFileURL.path));
    return NO;
  }

  if (backupPath.length > 0 && !MDBFileMatchesStoredHash(backupPath, backupHash)) {
    if (errorMessage != nil) {
      *errorMessage = @"Display override backup changed externally";
    }
    NSLog(@"[macDisplayBar] Display override backup restore refused: displayID=%@ backup=%@ backupHash=%@ currentHash=%@",
          displayID,
          backupPath,
          backupHash,
          MDBSHA256FileHash(backupPath));
    return NO;
  }

  NSError *directError = nil;

  if (backupPath.length > 0 && [fileManager fileExistsAtPath:backupPath]) {
    NSURL *directTempURL = [targetFileURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:[NSString stringWithFormat:@".%@.%@.tmp",
                                                                                                                                targetFileURL.lastPathComponent,
                                                                                                                                [[NSUUID UUID] UUIDString]]];

    [fileManager removeItemAtURL:directTempURL error:nil];

    if ([fileManager copyItemAtPath:backupPath toPath:directTempURL.path error:&directError] &&
        [fileManager replaceItemAtURL:targetFileURL
                         withItemAtURL:directTempURL
                        backupItemName:nil
                               options:0
                      resultingItemURL:nil
                                 error:&directError]) {
      NSLog(@"[macDisplayBar] Display override backup restored: displayID=%@ target=%@ backup=%@",
            displayID,
            targetFileURL.path,
            backupPath);
      return YES;
    }

    [fileManager removeItemAtURL:directTempURL error:nil];
  } else if ([fileManager removeItemAtURL:targetFileURL error:&directError]) {
    NSLog(@"[macDisplayBar] Display override removed: displayID=%@ target=%@",
          displayID,
          targetFileURL.path);
    return YES;
  }

  NSString *command = nil;

  if (backupPath.length > 0 && [fileManager fileExistsAtPath:backupPath]) {
    NSString *targetTempPath = [targetFileURL.path stringByAppendingFormat:@".%@.tmp", [[NSUUID UUID] UUIDString]];
    NSString *expectedTargetHash = targetExists ? installedHash : @"";
    NSString *targetHashCommand = MDBShellSHA256SizeCommand(targetFileURL.path);
    NSString *expectedBackupHash = backupHash;
    NSString *backupHashCommand = MDBShellSHA256SizeCommand(backupPath);
    NSString *backupPrecondition = [NSString stringWithFormat:@"if /bin/test ! -f %@ || /bin/test \"%@\" != %@; then exit 75; fi",
                                                              MDBShellQuotedString(backupPath),
                                                              expectedBackupHash,
                                                              backupHashCommand];
    NSString *targetPrecondition = targetExists
        ? [NSString stringWithFormat:@"if /bin/test ! -f %@ || /bin/test \"%@\" != %@; then exit 73; fi",
                                     MDBShellQuotedString(targetFileURL.path),
                                     expectedTargetHash,
                                     targetHashCommand]
        : [NSString stringWithFormat:@"if /bin/test -e %@; then exit 74; fi",
                                     MDBShellQuotedString(targetFileURL.path)];
    command = [NSString stringWithFormat:@"%@ && %@ && /usr/bin/install -o root -g wheel -m 0644 %@ %@ && /bin/mv -f %@ %@",
                                         targetPrecondition,
                                         backupPrecondition,
                                         MDBShellQuotedString(backupPath),
                                         MDBShellQuotedString(targetTempPath),
                                         MDBShellQuotedString(targetTempPath),
                                         MDBShellQuotedString(targetFileURL.path)];
  } else {
    NSString *expectedTargetHash = installedHash;
    command = [NSString stringWithFormat:@"if /bin/test ! -f %@ || /bin/test \"%@\" != %@; then exit 73; fi && /bin/rm -f %@",
                                         MDBShellQuotedString(targetFileURL.path),
                                         expectedTargetHash,
                                         MDBShellSHA256SizeCommand(targetFileURL.path),
                                         MDBShellQuotedString(targetFileURL.path)];
  }

  NSString *script = [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges",
                                                MDBAppleScriptQuotedString(command)];
  NSTask *task = [NSTask new];
  NSPipe *errorPipe = [NSPipe pipe];

  task.launchPath = @"/usr/bin/osascript";
  task.arguments = @[ @"-e", script ];
  task.standardError = errorPipe;

  @try {
    [[NSNotificationCenter defaultCenter] postNotificationName:RCTDisplayPrivilegedInstallWillBeginNotification
                                                        object:self];
    [task launch];
    [task waitUntilExit];
  } @catch (NSException *exception) {
    if (errorMessage != nil) {
      *errorMessage = exception.reason ?: @"Privileged override remove failed";
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:RCTDisplayPrivilegedInstallDidEndNotification
                                                        object:self];
    return NO;
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:RCTDisplayPrivilegedInstallDidEndNotification
                                                      object:self];

  if (task.terminationStatus == 0) {
    BOOL didApply = NO;

    if (backupPath.length > 0 && [fileManager fileExistsAtPath:backupPath]) {
      didApply = [fileManager contentsEqualAtPath:backupPath andPath:targetFileURL.path];
    } else {
      didApply = ![fileManager fileExistsAtPath:targetFileURL.path];
    }

    if (didApply) {
      NSLog(@"[macDisplayBar] Display override privileged remove verified: displayID=%@ target=%@",
            displayID,
            targetFileURL.path);
      return YES;
    }
  }

  NSData *errorData = [errorPipe.fileHandleForReading readDataToEndOfFile];
  NSString *privilegedError =
      [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];

  NSLog(@"[macDisplayBar] Display override privileged remove failed: status=%d target=%@ stderr=%@ directError=%@",
        task.terminationStatus,
        targetFileURL.path,
        privilegedError ?: @"",
        directError.localizedDescription ?: @"");

  if (errorMessage != nil) {
    *errorMessage = privilegedError.length > 0 ? privilegedError : (directError.localizedDescription ?: @"Privileged override remove failed");
  }

  return NO;
}


- (BOOL)requestDisplayReinitializeForDisplayID:(CGDirectDisplayID)displayID errorMessage:(NSString **)errorMessage
{
  uint32_t vendorID = CGDisplayVendorNumber(displayID);
  uint32_t productID = CGDisplayModelNumber(displayID);
  uint32_t serialNumber = CGDisplaySerialNumber(displayID);
  io_iterator_t iterator = MACH_PORT_NULL;
  kern_return_t result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"), &iterator);

  if (result != KERN_SUCCESS || iterator == MACH_PORT_NULL) {
    if (errorMessage != nil) {
      *errorMessage = [NSString stringWithFormat:@"IODisplayConnect lookup failed: 0x%08x", result];
    }
    return NO;
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
      kern_return_t probeResult = IOServiceRequestProbe(service, kIOFBUserRequestProbe);
      IOObjectRelease(service);
      IOObjectRelease(iterator);

      if (probeResult == KERN_SUCCESS) {
        NSLog(@"[macDisplayBar] Display override reinitialize requested: displayID=%u", displayID);
        return YES;
      }

      if (errorMessage != nil) {
        *errorMessage = [NSString stringWithFormat:@"Display reinitialize failed: 0x%08x", probeResult];
      }
      return NO;
    }

    IOObjectRelease(service);
  }

  IOObjectRelease(iterator);

  if (errorMessage != nil) {
    *errorMessage = @"Matching IODisplayConnect service not found";
  }
  return NO;
}

