#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCTDisplayCore : NSObject

- (NSDictionary *)getSnapshot;
- (NSDictionary *)refreshSnapshot;
- (NSDictionary *)setNativeBrightness:(NSString *)displayID level:(double)level;
- (NSDictionary *)setSoftwareDimming:(NSString *)displayID level:(double)level;
- (NSDictionary *)setDisplayMode:(NSString *)displayID modeID:(NSString *)modeID;
- (NSDictionary *)setDisplayOrigin:(NSString *)displayID x:(double)x y:(double)y;
- (NSDictionary *)savePreset:(NSString *)name;
- (NSDictionary *)applyPreset:(NSString *)name;
- (NSDictionary *)deletePreset:(NSString *)name;
- (NSDictionary *)setColorProfile:(NSString *)displayID profileID:(NSString *)profileID;
- (NSDictionary *)resetColorProfile:(NSString *)displayID;
- (NSDictionary *)saveProtectedLayout;
- (NSDictionary *)restoreProtectedLayout;
- (NSDictionary *)clearProtectedLayout;
- (NSDictionary *)saveSyncGroup:(NSString *)name
                     displayIDs:(NSArray<NSString *> *)displayIDs
                 brightnessSync:(BOOL)brightnessSync
                      scaleSync:(BOOL)scaleSync
                layoutProtection:(BOOL)layoutProtection;
- (NSDictionary *)applySyncGroup:(NSString *)groupID;
- (NSDictionary *)deleteSyncGroup:(NSString *)groupID;
- (NSDictionary *)exportEdid:(NSString *)displayID;
- (NSDictionary *)addCustomResolution:(NSString *)displayID
                                width:(double)width
                               height:(double)height
                          refreshRate:(double)refreshRate
                              isHiDpi:(BOOL)isHiDpi;
- (NSDictionary *)removeCustomResolution:(NSString *)displayID requestID:(NSString *)requestID;
- (NSDictionary *)queueEdidOverride:(NSString *)displayID;
- (NSDictionary *)clearEdidOverride:(NSString *)displayID;
- (NSDictionary *)writeOverrideBundle:(NSString *)displayID;
- (NSDictionary *)setDisplayRotation:(NSString *)displayID rotation:(double)rotation;
- (NSDictionary *)enableXdrUpscale:(NSString *)displayID;
- (NSDictionary *)disableXdrUpscale:(NSString *)displayID;
- (NSDictionary *)softDisconnectDisplay:(NSString *)displayID;
- (NSDictionary *)reconnectDisplay:(NSString *)displayID;
- (NSDictionary *)saveFavoriteMode:(NSString *)displayID modeID:(NSString *)modeID;
- (NSDictionary *)removeFavoriteMode:(NSString *)displayID modeID:(NSString *)modeID;
- (NSDictionary *)setDdcControl:(NSString *)displayID controlCode:(double)controlCode value:(double)value;
- (NSDictionary *)setSettings:(BOOL)autoRefresh
        refreshIntervalSeconds:(double)refreshIntervalSeconds
          showAdvancedMetadata:(BOOL)showAdvancedMetadata;

@end

NS_ASSUME_NONNULL_END
