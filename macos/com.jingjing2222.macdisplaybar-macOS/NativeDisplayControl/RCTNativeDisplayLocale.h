#import <Foundation/Foundation.h>

static inline NSString *RCTNativeDisplayResolvedSystemLocaleFromValues(
    NSArray<NSString *> *preferredLanguages,
    NSString *currentLocaleIdentifier)
{
  NSString *preferredLanguage = preferredLanguages.firstObject;

  if (preferredLanguage.length > 0) {
    return preferredLanguage;
  }

  return currentLocaleIdentifier.length > 0 ? currentLocaleIdentifier : @"en-US";
}

static inline NSString *RCTNativeDisplayResolvedSystemLocale(void)
{
  return RCTNativeDisplayResolvedSystemLocaleFromValues(
      NSLocale.preferredLanguages,
      NSLocale.currentLocale.localeIdentifier);
}
