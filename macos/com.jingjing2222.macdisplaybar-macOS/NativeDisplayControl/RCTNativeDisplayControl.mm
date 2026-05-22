#import "RCTNativeDisplayControl.h"

#import "../DisplayCore/RCTDisplayCore.h"

@interface RCTNativeDisplayControl ()

@property (nonatomic, strong) RCTDisplayCore *displayCore;

@end

@implementation RCTNativeDisplayControl

- (instancetype)init
{
  self = [super init];

  if (self) {
    self.displayCore = [RCTDisplayCore new];
  }

  return self;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeDisplayControlSpecJSI>(params);
}

- (NSDictionary *)getSnapshot
{
  return [self.displayCore getSnapshot];
}

- (NSDictionary *)refreshSnapshot
{
  return [self.displayCore refreshSnapshot];
}

- (NSDictionary *)setNativeBrightness:(NSString *)displayID level:(double)level
{
  return [self.displayCore setNativeBrightness:displayID level:level];
}

- (NSDictionary *)setSoftwareDimming:(NSString *)displayID level:(double)level
{
  return [self.displayCore setSoftwareDimming:displayID level:level];
}

- (NSDictionary *)setDisplayMode:(NSString *)displayID modeID:(NSString *)modeID
{
  return [self.displayCore setDisplayMode:displayID modeID:modeID];
}

- (NSDictionary *)setDisplayOrigin:(NSString *)displayID x:(double)x y:(double)y
{
  return [self.displayCore setDisplayOrigin:displayID x:x y:y];
}

- (NSDictionary *)savePreset:(NSString *)name
{
  return [self.displayCore savePreset:name];
}

- (NSDictionary *)applyPreset:(NSString *)name
{
  return [self.displayCore applyPreset:name];
}

- (NSDictionary *)deletePreset:(NSString *)name
{
  return [self.displayCore deletePreset:name];
}

- (NSDictionary *)setColorProfile:(NSString *)displayID profileID:(NSString *)profileID
{
  return [self.displayCore setColorProfile:displayID profileID:profileID];
}

- (NSDictionary *)resetColorProfile:(NSString *)displayID
{
  return [self.displayCore resetColorProfile:displayID];
}

- (NSDictionary *)saveProtectedLayout
{
  return [self.displayCore saveProtectedLayout];
}

- (NSDictionary *)restoreProtectedLayout
{
  return [self.displayCore restoreProtectedLayout];
}

- (NSDictionary *)clearProtectedLayout
{
  return [self.displayCore clearProtectedLayout];
}

- (NSDictionary *)saveSyncGroup:(NSString *)name
                     displayIDs:(NSArray<NSString *> *)displayIDs
                 brightnessSync:(BOOL)brightnessSync
                      scaleSync:(BOOL)scaleSync
                layoutProtection:(BOOL)layoutProtection
{
  return [self.displayCore saveSyncGroup:name
                              displayIDs:displayIDs
                          brightnessSync:brightnessSync
                               scaleSync:scaleSync
                         layoutProtection:layoutProtection];
}

- (NSDictionary *)applySyncGroup:(NSString *)groupID
{
  return [self.displayCore applySyncGroup:groupID];
}

- (NSDictionary *)deleteSyncGroup:(NSString *)groupID
{
  return [self.displayCore deleteSyncGroup:groupID];
}

- (NSDictionary *)exportEdid:(NSString *)displayID
{
  return [self.displayCore exportEdid:displayID];
}

- (NSDictionary *)addCustomResolution:(NSString *)displayID
                                width:(double)width
                               height:(double)height
                          refreshRate:(double)refreshRate
                              isHiDpi:(BOOL)isHiDpi
{
  return [self.displayCore addCustomResolution:displayID
                                         width:width
                                        height:height
                                   refreshRate:refreshRate
                                       isHiDpi:isHiDpi];
}

- (NSDictionary *)removeCustomResolution:(NSString *)displayID requestID:(NSString *)requestID
{
  return [self.displayCore removeCustomResolution:displayID requestID:requestID];
}

- (NSDictionary *)queueEdidOverride:(NSString *)displayID
{
  return [self.displayCore queueEdidOverride:displayID];
}

- (NSDictionary *)clearEdidOverride:(NSString *)displayID
{
  return [self.displayCore clearEdidOverride:displayID];
}

- (NSDictionary *)writeOverrideBundle:(NSString *)displayID
{
  return [self.displayCore writeOverrideBundle:displayID];
}

- (NSDictionary *)setDisplayRotation:(NSString *)displayID rotation:(double)rotation
{
  return [self.displayCore setDisplayRotation:displayID rotation:rotation];
}

- (NSDictionary *)enableXdrUpscale:(NSString *)displayID
{
  return [self.displayCore enableXdrUpscale:displayID];
}

- (NSDictionary *)disableXdrUpscale:(NSString *)displayID
{
  return [self.displayCore disableXdrUpscale:displayID];
}

- (NSDictionary *)softDisconnectDisplay:(NSString *)displayID
{
  return [self.displayCore softDisconnectDisplay:displayID];
}

- (NSDictionary *)reconnectDisplay:(NSString *)displayID
{
  return [self.displayCore reconnectDisplay:displayID];
}

- (NSDictionary *)saveFavoriteMode:(NSString *)displayID modeID:(NSString *)modeID
{
  return [self.displayCore saveFavoriteMode:displayID modeID:modeID];
}

- (NSDictionary *)removeFavoriteMode:(NSString *)displayID modeID:(NSString *)modeID
{
  return [self.displayCore removeFavoriteMode:displayID modeID:modeID];
}

- (NSDictionary *)setDdcControl:(NSString *)displayID controlCode:(double)controlCode value:(double)value
{
  return [self.displayCore setDdcControl:displayID controlCode:controlCode value:value];
}

- (NSDictionary *)setSettings:(BOOL)autoRefresh
        refreshIntervalSeconds:(double)refreshIntervalSeconds
          showAdvancedMetadata:(BOOL)showAdvancedMetadata
{
  return [self.displayCore setSettings:autoRefresh
                refreshIntervalSeconds:refreshIntervalSeconds
                  showAdvancedMetadata:showAdvancedMetadata];
}

+ (NSString *)moduleName
{
  return @"NativeDisplayControl";
}

@end
