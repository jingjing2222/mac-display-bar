- (BOOL)modeIDIsFavorite:(NSString *)modeID displayIDString:(NSString *)displayIDString
{
  return [self.favoriteModes[displayIDString] containsObject:modeID];
}


- (NSDictionary *)dictionaryForMode:(CGDisplayModeRef)mode currentModeID:(NSString *)currentModeID
{
  NSString *modeID = [self modeIDForMode:mode];
  size_t width = CGDisplayModeGetWidth(mode);
  size_t height = CGDisplayModeGetHeight(mode);
  double refreshRate = CGDisplayModeGetRefreshRate(mode);
  BOOL isHiDpi = CGDisplayModeGetPixelWidth(mode) > width;

  return @{
    @"id" : modeID,
    @"width" : @(width),
    @"height" : @(height),
    @"refreshRate" : @(refreshRate),
    @"isHiDpi" : @(isHiDpi),
    @"isCurrent" : @([modeID isEqualToString:currentModeID]),
    @"isFavorite" : @NO,
  };
}


- (NSString *)modeIDForMode:(CGDisplayModeRef)mode
{
  return [NSString stringWithFormat:@"%d-%zu-%zu-%zu-%zu-%.3f",
                                    CGDisplayModeGetIODisplayModeID(mode),
                                    CGDisplayModeGetWidth(mode),
                                    CGDisplayModeGetHeight(mode),
                                    CGDisplayModeGetPixelWidth(mode),
                                    CGDisplayModeGetPixelHeight(mode),
                                    CGDisplayModeGetRefreshRate(mode)];
}


- (NSString *)generatedHiDpiModeIDWithWidth:(NSUInteger)width height:(NSUInteger)height refreshRate:(double)refreshRate
{
  return [NSString stringWithFormat:@"%@:%lu:%lu:%.3f",
                                    RCTGeneratedHiDpiModeIDPrefix,
                                    (unsigned long)width,
                                    (unsigned long)height,
                                    refreshRate];
}


- (NSDictionary *)generatedHiDpiModeComponentsFromModeID:(NSString *)modeID
{
  NSArray<NSString *> *components = [modeID componentsSeparatedByString:@":"];

  if (components.count != 4 || ![components[0] isEqualToString:RCTGeneratedHiDpiModeIDPrefix]) {
    return nil;
  }

  NSUInteger width = (NSUInteger)components[1].integerValue;
  NSUInteger height = (NSUInteger)components[2].integerValue;
  double refreshRate = components[3].doubleValue;

  if (width == 0 || height == 0) {
    return nil;
  }

  return @{
    @"width" : @(width),
    @"height" : @(height),
    @"refreshRate" : @(refreshRate),
  };
}

