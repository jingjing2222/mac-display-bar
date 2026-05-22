#import "RCTNativeFoo.h"

@implementation RCTNativeFoo

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeFooSpecJSI>(params);
}

- (NSString *)foo
{
  return @"bar";
}

+ (NSString *)moduleName
{
  return @"NativeFoo";
}

@end
