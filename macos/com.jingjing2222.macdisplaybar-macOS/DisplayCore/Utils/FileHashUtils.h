#pragma once

#import <CommonCrypto/CommonDigest.h>
#import <Foundation/Foundation.h>

#import "StringUtils.h"

static inline NSString *MDBSHA256FileHash(NSString *path)
{
  NSData *data = [NSData dataWithContentsOfFile:path];

  if (data.length == 0) {
    return @"";
  }

  unsigned char digest[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
  NSMutableString *hexDigest = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];

  for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; index++) {
    [hexDigest appendFormat:@"%02x", digest[index]];
  }

  return [NSString stringWithFormat:@"%@-%lu", hexDigest, (unsigned long)data.length];
}

static inline BOOL MDBFileMatchesStoredHash(NSString *path, NSString *storedHash)
{
  return path.length > 0 && storedHash.length > 0 && [MDBSHA256FileHash(path) isEqualToString:storedHash];
}

static inline NSString *MDBShellSHA256SizeCommand(NSString *path)
{
  NSString *quotedPath = MDBShellQuotedString(path);
  return [NSString stringWithFormat:@"$(/usr/bin/shasum -a 256 %@ | /usr/bin/awk '{print $1}')-$(/usr/bin/stat -f %%z %@)",
                                    quotedPath,
                                    quotedPath];
}
