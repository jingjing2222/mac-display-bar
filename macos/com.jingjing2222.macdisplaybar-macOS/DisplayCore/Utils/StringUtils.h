#pragma once

#import <Foundation/Foundation.h>

static inline NSString *MDBTrimmedString(NSString *value)
{
  if (![value isKindOfClass:NSString.class]) {
    return @"";
  }

  return [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

static inline NSString *MDBTrimmedStringOrFallback(NSString *value, NSString *(^fallback)(void))
{
  NSString *trimmedValue = MDBTrimmedString(value);

  if (trimmedValue.length > 0) {
    return trimmedValue;
  }

  return fallback != nil ? (fallback() ?: @"") : @"";
}

static inline NSString *MDBSafeFileNameComponent(NSString *value, NSString *fallback)
{
  NSString *stringValue = [value isKindOfClass:NSString.class] ? value : @"";
  NSMutableString *result = [NSMutableString stringWithCapacity:stringValue.length];
  NSCharacterSet *allowedCharacters = [NSCharacterSet characterSetWithCharactersInString:
      @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-"];

  for (NSUInteger index = 0; index < stringValue.length; index++) {
    unichar character = [stringValue characterAtIndex:index];

    if ([allowedCharacters characterIsMember:character]) {
      [result appendFormat:@"%C", character];
    } else {
      [result appendString:@"_"];
    }
  }

  return result.length > 0 ? result : (fallback ?: @"");
}

static inline NSString *MDBShellQuotedString(NSString *value)
{
  NSString *stringValue = [value isKindOfClass:NSString.class] ? value : @"";
  return [NSString stringWithFormat:@"'%@'",
                                    [stringValue stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"]];
}

static inline NSString *MDBAppleScriptQuotedString(NSString *value)
{
  NSString *stringValue = [value isKindOfClass:NSString.class] ? value : @"";
  NSString *escapedValue = [stringValue stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
  return [escapedValue stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
}
