#pragma once

#import <Foundation/Foundation.h>

static inline NSString *MDBIntegerPairKey(NSUInteger first, NSUInteger second)
{
  return [NSString stringWithFormat:@"%lu:%lu", (unsigned long)first, (unsigned long)second];
}

static inline NSString *MDBIntegerPairRefreshKey(NSUInteger first, NSUInteger second, double refreshRate)
{
  return [NSString stringWithFormat:@"%lu:%lu:%.3f", (unsigned long)first, (unsigned long)second, refreshRate];
}
