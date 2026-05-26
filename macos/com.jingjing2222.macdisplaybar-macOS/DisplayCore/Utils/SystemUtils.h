#pragma once

#import <Foundation/Foundation.h>

#include <sys/sysctl.h>

static inline NSTimeInterval MDBSystemBootTime(void)
{
  struct timeval bootTime;
  size_t bootTimeSize = sizeof(bootTime);
  int mib[2] = {CTL_KERN, KERN_BOOTTIME};

  if (sysctl(mib, 2, &bootTime, &bootTimeSize, NULL, 0) != 0 || bootTime.tv_sec == 0) {
    return 0;
  }

  return (NSTimeInterval)bootTime.tv_sec + ((NSTimeInterval)bootTime.tv_usec / 1000000.0);
}
