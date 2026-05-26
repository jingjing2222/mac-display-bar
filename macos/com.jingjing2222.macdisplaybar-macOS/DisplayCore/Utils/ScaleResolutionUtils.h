#pragma once

#import <Foundation/Foundation.h>

#import "KeyUtils.h"
#import "NumberUtils.h"

#include <arpa/inet.h>
#include <math.h>

static inline NSArray<NSNumber *> *MDBOneKeyHiDpiRatios(void)
{
  return @[
    @1.0,
    @1.25,
    @(4.0 / 3.0),
    @(16.0 / 11.0),
    @(16.0 / 9.0),
    @2.0,
    @(8.0 / 3.0),
  ];
}

static inline NSArray<NSNumber *> *MDBNearNativeScales(void)
{
  return @[
    @0.99,
    @0.98,
    @0.97,
  ];
}

static inline NSArray<NSArray<NSNumber *> *> *MDBOneKeyHiDpiSuffixFamilies(void)
{
  return @[
    @[ @0x00 ],
    @[ @0x00, @0x00, @0x00, @0x01, @0x00, @0x20, @0x00, @0x00 ],
    @[ @0x00, @0x00, @0x00, @0x01 ],
    @[ @0x00, @0x00, @0x00, @0x09, @0x00, @0xa0, @0x00, @0x00 ],
  ];
}

static inline NSData *MDBScaleResolutionData(NSUInteger width, NSUInteger height)
{
  uint32_t encodedResolution[2] = {
    htonl(MDBClampUInt32(width)),
    htonl(MDBClampUInt32(height)),
  };

  return [NSData dataWithBytes:encodedResolution length:sizeof(encodedResolution)];
}

static inline NSData *MDBOneKeyHiDpiScaleResolutionData(NSUInteger logicalWidth,
                                                        NSUInteger logicalHeight,
                                                        NSArray<NSNumber *> *suffixBytes)
{
  uint32_t encodedResolution[2] = {
    htonl(MDBClampUInt32(logicalWidth * 2)),
    htonl(MDBClampUInt32(logicalHeight * 2)),
  };
  NSMutableData *data = [NSMutableData dataWithBytes:encodedResolution length:sizeof(encodedResolution)];

  for (NSNumber *suffixByte in suffixBytes) {
    uint8_t byte = (uint8_t)suffixByte.unsignedCharValue;
    [data appendBytes:&byte length:sizeof(byte)];
  }

  return data;
}

static inline void MDBAppendOneKeyHiDpiScaleResolutions(NSMutableArray<NSData *> *scaleResolutions,
                                                        NSMutableSet<NSData *> *seenResolutions,
                                                        NSUInteger width,
                                                        NSUInteger height,
                                                        NSArray<NSNumber *> *ratios,
                                                        NSArray<NSNumber *> *suffixBytes)
{
  for (NSNumber *ratioValue in ratios) {
    double ratio = ratioValue.doubleValue;
    NSUInteger logicalWidth = (NSUInteger)llround((double)width / ratio);
    NSUInteger logicalHeight = (NSUInteger)llround((double)height / ratio);

    if (logicalWidth == 0 || logicalHeight == 0) {
      continue;
    }

    NSData *data = MDBOneKeyHiDpiScaleResolutionData(logicalWidth, logicalHeight, suffixBytes);

    if ([seenResolutions containsObject:data]) {
      continue;
    }

    [seenResolutions addObject:data];
    [scaleResolutions addObject:data];
  }
}

static inline void MDBAppendNearNativeHiDpiScaleResolutions(NSMutableArray<NSData *> *scaleResolutions,
                                                            NSMutableSet<NSData *> *seenResolutions,
                                                            NSUInteger width,
                                                            NSUInteger height,
                                                            NSArray<NSNumber *> *suffixBytes)
{
  for (NSNumber *scaleValue in MDBNearNativeScales()) {
    double scale = scaleValue.doubleValue;
    NSUInteger logicalWidth = (NSUInteger)llround((double)width * scale);
    NSUInteger logicalHeight = (NSUInteger)llround((double)height * scale);

    if (logicalWidth == 0 || logicalHeight == 0) {
      continue;
    }

    NSData *data = MDBOneKeyHiDpiScaleResolutionData(logicalWidth, logicalHeight, suffixBytes);

    if ([seenResolutions containsObject:data]) {
      continue;
    }

    [seenResolutions addObject:data];
    [scaleResolutions addObject:data];
  }
}

static inline void MDBAppendOneKeyHiDpiScaleResolutionFamily(NSMutableArray<NSData *> *scaleResolutions,
                                                             NSMutableSet<NSData *> *seenResolutions,
                                                             NSUInteger width,
                                                             NSUInteger height)
{
  NSArray<NSNumber *> *ratios = MDBOneKeyHiDpiRatios();

  for (NSArray<NSNumber *> *suffixBytes in MDBOneKeyHiDpiSuffixFamilies()) {
    MDBAppendOneKeyHiDpiScaleResolutions(scaleResolutions, seenResolutions, width, height, ratios, suffixBytes);
    MDBAppendNearNativeHiDpiScaleResolutions(scaleResolutions, seenResolutions, width, height, suffixBytes);
  }
}

static inline NSSet<NSString *> *MDBOneKeyHiDpiRecipeResolutionKeys(NSUInteger width, NSUInteger height)
{
  NSMutableSet<NSString *> *resolutionKeys = [NSMutableSet new];

  for (NSNumber *ratioValue in MDBOneKeyHiDpiRatios()) {
    double ratio = ratioValue.doubleValue;
    NSUInteger logicalWidth = (NSUInteger)llround((double)width / ratio);
    NSUInteger logicalHeight = (NSUInteger)llround((double)height / ratio);

    if (logicalWidth == 0 || logicalHeight == 0) {
      continue;
    }

    [resolutionKeys addObject:MDBIntegerPairKey(logicalWidth, logicalHeight)];
  }

  for (NSNumber *scaleValue in MDBNearNativeScales()) {
    double scale = scaleValue.doubleValue;
    NSUInteger logicalWidth = (NSUInteger)llround((double)width * scale);
    NSUInteger logicalHeight = (NSUInteger)llround((double)height * scale);

    if (logicalWidth == 0 || logicalHeight == 0) {
      continue;
    }

    [resolutionKeys addObject:MDBIntegerPairKey(logicalWidth, logicalHeight)];
  }

  return resolutionKeys;
}

static inline BOOL MDBOneKeyHiDpiRecipeIsExposed(NSSet<NSString *> *hiDpiResolutionKeys,
                                                 NSUInteger width,
                                                 NSUInteger height)
{
  for (NSString *resolutionKey in MDBOneKeyHiDpiRecipeResolutionKeys(width, height)) {
    if ([hiDpiResolutionKeys containsObject:resolutionKey]) {
      return YES;
    }
  }

  return NO;
}
