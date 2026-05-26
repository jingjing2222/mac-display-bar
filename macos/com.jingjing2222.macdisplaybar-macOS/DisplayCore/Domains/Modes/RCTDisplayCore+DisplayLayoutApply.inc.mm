- (void)applyDisplayOriginForDisplayID:(CGDirectDisplayID)displayID x:(int32_t)x y:(int32_t)y
{
  CGDisplayConfigRef config = NULL;
  CGError beginError = CGBeginDisplayConfiguration(&config);

  if (beginError != kCGErrorSuccess || config == NULL) {
    return;
  }

  CGError originError = CGConfigureDisplayOrigin(config, displayID, x, y);

  if (originError == kCGErrorSuccess) {
    CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
  } else {
    CGCancelDisplayConfiguration(config);
  }
}
