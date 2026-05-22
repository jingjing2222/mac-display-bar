import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const repoRoot = process.cwd();
const spec = readFileSync(
  join(repoRoot, 'specs/NativeDisplayControl.ts'),
  'utf8',
);
const app = readFileSync(join(repoRoot, 'App.tsx'), 'utf8');
const packageJson = readFileSync(join(repoRoot, 'package.json'), 'utf8');
const iconSource = readFileSync(
  join(repoRoot, 'src/components/Icon.tsx'),
  'utf8',
);
const displayControlApi = readFileSync(
  join(repoRoot, 'src/native/displayControlApi.ts'),
  'utf8',
);
const appEnvironmentApi = readFileSync(
  join(repoRoot, 'src/native/appEnvironmentApi.ts'),
  'utf8',
);
const i18nHook = readFileSync(join(repoRoot, 'src/i18n/useI18n.ts'), 'utf8');
const displayControlHook = readFileSync(
  join(repoRoot, 'src/hooks/display/useDisplayControl.ts'),
  'utf8',
);
const menuShell = readFileSync(
  join(repoRoot, 'src/components/MenuShell.tsx'),
  'utf8',
);
const displayControlPanel = readFileSync(
  join(repoRoot, 'src/components/DisplayControlPanel.tsx'),
  'utf8',
);
const resolutionPicker = readFileSync(
  join(repoRoot, 'src/components/ResolutionPicker.tsx'),
  'utf8',
);
const resolutionModeOverlay = readFileSync(
  join(repoRoot, 'src/components/ResolutionModeOverlay.tsx'),
  'utf8',
);
const stableLegendList = readFileSync(
  join(repoRoot, 'src/components/StableLegendList.tsx'),
  'utf8',
);
const topLevelDisplayHookPath = join(
  repoRoot,
  'src/hooks/useDisplayControl.ts',
);
const bridge = readFileSync(
  join(
    repoRoot,
    'macos/com.jingjing2222.macdisplaybar-macOS/NativeDisplayControl/RCTNativeDisplayControl.mm',
  ),
  'utf8',
);
const displayCoreHeader = readFileSync(
  join(
    repoRoot,
    'macos/com.jingjing2222.macdisplaybar-macOS/DisplayCore/RCTDisplayCore.h',
  ),
  'utf8',
);
const displayCore = readFileSync(
  join(
    repoRoot,
    'macos/com.jingjing2222.macdisplaybar-macOS/DisplayCore/RCTDisplayCore.mm',
  ),
  'utf8',
);
const project = readFileSync(
  join(
    repoRoot,
    'macos/com.jingjing2222.macdisplaybar.xcodeproj/project.pbxproj',
  ),
  'utf8',
);

const requiredMethods = [
  'getSnapshot',
  'refreshSnapshot',
  'setNativeBrightness',
  'setSoftwareDimming',
  'setDdcControl',
  'setDisplayMode',
  'saveFavoriteMode',
  'removeFavoriteMode',
  'setDisplayOrigin',
  'savePreset',
  'applyPreset',
  'deletePreset',
  'setColorProfile',
  'resetColorProfile',
  'saveProtectedLayout',
  'restoreProtectedLayout',
  'clearProtectedLayout',
  'saveSyncGroup',
  'applySyncGroup',
  'deleteSyncGroup',
  'exportEdid',
  'queueEdidOverride',
  'clearEdidOverride',
  'writeOverrideBundle',
  'addCustomResolution',
  'removeCustomResolution',
  'setDisplayRotation',
  'enableXdrUpscale',
  'disableXdrUpscale',
  'softDisconnectDisplay',
  'reconnectDisplay',
  'setSettings',
];

const snapshotFields = [
  'moduleStatus',
  'generatedAt',
  'platform',
  'architecture',
  'machineModel',
  'isAppleSilicon',
  'displayTopologyRevision',
  'displayTopologyStatus',
  'displayTopologyChangedAt',
  'displays',
  'presets',
  'syncGroups',
  'layoutProtectionEnabled',
  'layoutProtectionStatus',
  'layoutDriftCount',
  'settings',
];

const displayFields = [
  'id',
  'name',
  'connectionType',
  'isPrimary',
  'isBuiltin',
  'isOnline',
  'isActive',
  'isAsleep',
  'isMirrored',
  'isHardwareMirrored',
  'mirrorsDisplayID',
  'identity',
  'rotation',
  'frame',
  'currentMode',
  'availableModes',
  'modeStatus',
  'modeError',
  'nativeBrightness',
  'brightnessControl',
  'brightnessError',
  'softwareDimming',
  'supportsBrightness',
  'supportsSoftwareDimming',
  'supportsDdc',
  'ddc',
  'supportsHdr',
  'hdr',
  'colorProfileStatus',
  'colorProfileError',
  'colorProfiles',
  'advanced',
];

const identityFields = [
  'uuid',
  'vendorID',
  'modelID',
  'serialNumber',
  'productName',
  'transport',
];

const ddcFields = [
  'brightness',
  'contrast',
  'volume',
  'inputSource',
  'readStatus',
  'lastError',
];

const hdrFields = [
  'isSupported',
  'isActive',
  'currentHeadroom',
  'potentialHeadroom',
  'referenceHeadroom',
  'xdrPreset',
];

const advancedFields = [
  'supportsEdidExport',
  'edidBytes',
  'edidExportPath',
  'edidOverridePath',
  'edidOverrideStatus',
  'overrideBundlePath',
  'overrideBundleStatus',
  'rotationRequest',
  'rotationStatus',
  'softConnectionState',
  'xdrUpscaleState',
  'lastOperation',
  'lastOperationAt',
  'customResolutions',
];

const settingsFields = [
  'autoRefresh',
  'refreshIntervalSeconds',
  'showAdvancedMetadata',
];

test('NativeDisplayControl spec exposes the BetterDisplay phase-three control surface', () => {
  for (const method of requiredMethods) {
    expect(spec).toContain(`${method}(`);
  }

  expect(spec).toContain(
    "TurboModuleRegistry.get<Spec>('NativeDisplayControl')",
  );
});

test('native bridge and display core publish the same control surface', () => {
  for (const method of requiredMethods) {
    expect(bridge).toContain(`- (NSDictionary *)${method}`);
    expect(displayCoreHeader).toContain(`- (NSDictionary *)${method}`);
  }

  expect(bridge).toContain('return @"NativeDisplayControl"');
});

test('macOS project builds the display control engine and bridge', () => {
  expect(project).toContain('RCTNativeDisplayControl.mm in Sources');
  expect(project).toContain('RCTDisplayCore.mm in Sources');
});

test('snapshot contract covers display identity, control state, and advanced operations', () => {
  for (const field of snapshotFields) {
    expect(spec).toContain(`${field}:`);
    expect(displayCore).toContain(`@"${field}"`);
  }

  for (const field of displayFields) {
    expect(spec).toContain(`${field}:`);
    expect(displayCore).toContain(`@"${field}"`);
  }

  for (const field of [
    ...identityFields,
    ...ddcFields,
    ...hdrFields,
    ...advancedFields,
    ...settingsFields,
  ]) {
    expect(spec).toContain(`${field}:`);
    expect(displayCore).toContain(`@"${field}"`);
  }
});

test('native API wrapper owns direct TurboModule calls', () => {
  for (const method of requiredMethods.filter(
    (method) => !['getSnapshot'].includes(method),
  )) {
    expect(displayControlApi).toContain(`NativeDisplayControl?.${method}`);
  }

  expect(app).not.toContain('NativeDisplayControl?.');
  expect(app).toContain('./src/hooks/display/useDisplayControl');
  expect(app).toContain('<MenuShell control={control} />');
  expect(displayControlHook).toContain('useDisplaySnapshot');
  expect(displayControlHook).toContain('useDisplayControlActions');
  expect(existsSync(topLevelDisplayHookPath)).toBe(false);
});

test('i18n reads system locale through native API instead of Intl', () => {
  expect(spec).toContain('getSystemLocale(): string');
  expect(bridge).toContain('- (NSString *)getSystemLocale');
  expect(bridge).toContain('[NSLocale preferredLanguages]');
  expect(appEnvironmentApi).toContain(
    'NativeDisplayControl?.getSystemLocale()',
  );
  expect(i18nHook).toContain('appEnvironmentApi.getSystemLocale()');
  expect(i18nHook).not.toContain('Intl.');
});

test('menu shell owns fixed header and scrollable content', () => {
  expect(menuShell).toContain('TopUpdateHeader');
  expect(menuShell).toContain('ScrollView');
  expect(menuShell).toContain('contentContainerStyle={styles.content}');
  expect(menuShell).toContain('width: 520');
  expect(menuShell).toContain('height: 720');
  expect(existsSync(join(repoRoot, 'src/components/DisplayList.tsx'))).toBe(
    false,
  );
});

test('menu UI uses react-native-svg backed public icon paths', () => {
  expect(packageJson).toContain('"react-native-svg"');
  expect(iconSource).toContain("from 'react-native-svg'");
  expect(iconSource).toContain('name: IconName');
  expect(iconSource).toContain("case 'display'");
  expect(iconSource).toContain("case 'sliders'");
});

test('menu lists use JS-only overlay and FlashList-backed list', () => {
  expect(packageJson).toContain('"overlay-kit"');
  expect(packageJson).toContain('"@legendapp/list"');
  expect(packageJson).toContain('"@shopify/flash-list"');
  expect(app).toContain('OverlayProvider');
  expect(resolutionPicker).toContain("from 'overlay-kit'");
  expect(resolutionPicker).toContain('ResolutionModeOverlay');
  expect(resolutionModeOverlay).toContain('TextInput');
  expect(resolutionModeOverlay).toContain('StableLegendList');
  expect(displayControlPanel).toContain('StableLegendList');
  expect(stableLegendList).toContain("from '@shopify/flash-list'");
  expect(stableLegendList).toContain('FlashList');
  expect(stableLegendList).toContain('removeClippedSubviews={false}');
});

test('custom resolution drafts follow current mode snapshot changes', () => {
  expect(displayControlPanel).toContain('const modeDraft = useMemo');
  expect(displayControlPanel).toContain('setCustomWidth(modeDraft.width)');
  expect(displayControlPanel).toContain('setCustomHeight(modeDraft.height)');
  expect(displayControlPanel).toContain(
    'setCustomRefreshRate(modeDraft.refreshRate)',
  );
  expect(displayControlPanel).toContain('display.id');
});

test('generated HiDPI selections install overrides and do not fall back to standard scale modes', () => {
  const generatedHiDpiApplyMethod = displayCore.slice(
    displayCore.indexOf('- (BOOL)applyAvailableHiDpiModeForDisplayID:'),
    displayCore.indexOf('- (void)applyDisplayOriginForDisplayID:'),
  );
  const generatedModeBranch = displayCore.slice(
    displayCore.indexOf('- (BOOL)applyDisplayModeForDisplayID:'),
    displayCore.indexOf('- (BOOL)applyAvailableHiDpiModeForDisplayID:'),
  );

  expect(displayCore).toContain('generatedHiDpiModeComponentsFromModeID');
  expect(displayCore).toContain('applyAvailableHiDpiModeForDisplayID');
  expect(displayCore).toContain('installOverrideBundleAtPath');
  expect(displayCore).toContain('with administrator privileges');
  expect(displayCore).toContain('RCTDisplayOverrideInstallDirectory');
  expect(generatedModeBranch).toContain(
    'installOverrideBundleAtPath:bundlePath',
  );
  expect(generatedModeBranch).toContain('!didApplyMode && didInstallBundle');
  expect(generatedModeBranch).toContain('attempt < 3 && !didApplyMode');
  expect(generatedHiDpiApplyMethod).toContain(
    'CGDisplaySetDisplayMode(displayID, hiDpiMode, NULL)',
  );
  expect(displayCore).toContain('HiDPI settings installed');
  expect(displayCore).not.toContain('GeneratedHiDpiOverlay');
  expect(displayCore).not.toContain('install required');
  expect(generatedHiDpiApplyMethod).not.toContain('allowStandardFallback');
  expect(generatedHiDpiApplyMethod).not.toContain('fallbackMode');
});

test('display snapshots do not mutate AppKit dimming windows', () => {
  const displayDictionaryMethod = displayCore.slice(
    displayCore.indexOf('- (NSDictionary *)dictionaryForDisplay:'),
    displayCore.indexOf('- (NSDictionary *)identityForDisplayID:'),
  );

  expect(displayDictionaryMethod).not.toContain(
    'syncDimmingWindowForDisplayID',
  );
  expect(displayCore).toContain('if (![NSThread isMainThread])');
  expect(displayCore).toContain('dispatch_async(dispatch_get_main_queue()');
});

test('display snapshots keep AppKit access narrow and on the main thread', () => {
  const screenMetadataMethod = displayCore.slice(
    displayCore.indexOf(
      '- (NSDictionary<NSString *, NSDictionary *> *)screenMetadataForActiveDisplays',
    ),
    displayCore.indexOf('- (NSDictionary *)dictionaryForDisplay:'),
  );
  const displayDictionaryMethod = displayCore.slice(
    displayCore.indexOf('- (NSDictionary *)dictionaryForDisplay:'),
    displayCore.indexOf('- (NSDictionary *)identityForDisplayID:'),
  );
  const hdrProbeMethod = displayCore.slice(
    displayCore.indexOf('- (BOOL)displaySupportsHdrForDisplayID:'),
    displayCore.indexOf('- (BOOL)screenSupportsHdr:'),
  );
  const xdrUpscaleMethod = displayCore.slice(
    displayCore.indexOf('- (NSDictionary *)enableXdrUpscale:'),
    displayCore.indexOf('- (NSDictionary *)disableXdrUpscale:'),
  );

  expect(screenMetadataMethod).toContain(
    'dispatch_sync(dispatch_get_main_queue()',
  );
  expect(screenMetadataMethod).toContain('NSScreen.screens');
  expect(displayDictionaryMethod).not.toContain('screenForDisplayID');
  expect(displayDictionaryMethod).not.toContain('hdrStateForScreen:screen');
  expect(hdrProbeMethod).toContain('dispatch_sync(dispatch_get_main_queue()');
  expect(xdrUpscaleMethod).toContain('displaySupportsHdrForDisplayID');
  expect(xdrUpscaleMethod).not.toContain('screenForDisplayID');
});

test('display snapshots do not perform live DDC I2C reads on the main thread', () => {
  const ddcStateMethod = displayCore.slice(
    displayCore.indexOf('- (NSDictionary *)ddcStateForDisplayIDString:'),
    displayCore.indexOf('- (void)refreshDdcValuesForActiveDisplays'),
  );

  expect(ddcStateMethod).not.toContain('refreshDdcValuesForDisplayID');
  expect(ddcStateMethod).not.toContain('readDdcVcpForDisplayID');
  expect(displayCore).toContain('@"readStatus" : self.ddcReadStatus');
});

test('manual refresh updates live DDC values outside snapshot mapping', () => {
  const refreshSnapshotMethod = displayCore.slice(
    displayCore.indexOf('- (NSDictionary *)refreshSnapshot'),
    displayCore.indexOf('- (NSDictionary *)setNativeBrightness:'),
  );

  expect(refreshSnapshotMethod).toContain('refreshDdcValuesForActiveDisplays');
  expect(displayCore).toContain('- (void)refreshDdcValuesForActiveDisplays');
});

test('layout drift detection follows identity fallback when display IDs change', () => {
  expect(displayCore).toContain(
    '[self resolveDisplayIDString:storedDisplayID storedState:protectedFrame]',
  );
  expect(displayCore).toContain(
    'NSMutableSet<NSString *> *matchedCurrentDisplayIDs',
  );
  expect(displayCore).toContain(
    '[matchedCurrentDisplayIDs containsObject:displayID]',
  );
});
