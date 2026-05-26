#pragma once

#import <Foundation/Foundation.h>

#include <float.h>
#include <math.h>
#include <stdint.h>

static inline double MDBClampDouble(double value, double minimum, double maximum)
{
  return MIN(MAX(value, minimum), maximum);
}

static inline uint8_t MDBClampUInt8(double value)
{
  return (uint8_t)MDBClampDouble(value, 0, UINT8_MAX);
}

static inline uint16_t MDBClampUInt16(double value)
{
  return (uint16_t)MDBClampDouble(value, 0, UINT16_MAX);
}

static inline uint32_t MDBClampUInt32(NSUInteger value)
{
  return (uint32_t)MIN(value, (NSUInteger)UINT32_MAX);
}

static inline double MDBNearestDouble(double value, NSArray<NSNumber *> *allowedValues)
{
  NSNumber *closestValue = allowedValues.firstObject;
  double closestDistance = DBL_MAX;

  for (NSNumber *candidate in allowedValues) {
    double distance = fabs(candidate.doubleValue - value);

    if (distance < closestDistance) {
      closestDistance = distance;
      closestValue = candidate;
    }
  }

  return closestValue != nil ? closestValue.doubleValue : value;
}
