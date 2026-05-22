import { bare } from '@hot-updater/bare';
import { d1Database, r2Storage } from '@hot-updater/cloudflare';
import { config } from 'dotenv';
import { defineConfig } from 'hot-updater';

config({ path: '.env.hotupdater' });

export default defineConfig({
  build: bare({ enableHermes: true }),
  fingerprint: {
    extraSources: [
      'macos/com.jingjing2222.macdisplaybar-macOS/AppDelegate.h',
      'macos/com.jingjing2222.macdisplaybar-macOS/AppDelegate.mm',
      'macos/com.jingjing2222.macdisplaybar-macOS/Base.lproj/Main.storyboard',
      'macos/com.jingjing2222.macdisplaybar-macOS/DisplayCore',
      'macos/com.jingjing2222.macdisplaybar-macOS/NativeDisplayControl',
      'macos/com.jingjing2222.macdisplaybar-macOS/NativeFoo',
      'macos/com.jingjing2222.macdisplaybar-macOS/com.jingjing2222.macdisplaybar.entitlements',
      'macos/com.jingjing2222.macdisplaybar-macOS/main.m',
      'macos/fingerprint-version.txt',
      'macos/com.jingjing2222.macdisplaybar.xcodeproj/project.pbxproj',
      'macos/Podfile',
      'macos/Podfile.lock',
      'macos/PrivacyInfo.xcprivacy',
    ],
    ignorePaths: [
      'macos/Pods/**/*',
      'macos/build/**/*',
      'macos/**/*.xcuserdata/**/*',
      'macos/**/*.xcworkspace/xcuserdata/**/*',
    ],
  },
  storage: r2Storage({
    bucketName: process.env.HOT_UPDATER_CLOUDFLARE_R2_BUCKET_NAME!,
    accountId: process.env.HOT_UPDATER_CLOUDFLARE_ACCOUNT_ID!,
    credentials: {
      accessKeyId: process.env.HOT_UPDATER_CLOUDFLARE_R2_ACCESS_KEY_ID!,
      secretAccessKey: process.env.HOT_UPDATER_CLOUDFLARE_R2_SECRET_ACCESS_KEY!,
    },
  }),
  database: d1Database({
    databaseId: process.env.HOT_UPDATER_CLOUDFLARE_D1_DATABASE_ID!,
    accountId: process.env.HOT_UPDATER_CLOUDFLARE_ACCOUNT_ID!,
    cloudflareApiToken: process.env.HOT_UPDATER_CLOUDFLARE_API_TOKEN!,
  }),
  updateStrategy: 'fingerprint',
});
