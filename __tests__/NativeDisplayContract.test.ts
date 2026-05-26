import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const repoRoot = process.cwd();
const spec = readFileSync(
  join(repoRoot, 'specs/NativeDisplayControl.ts'),
  'utf8',
);
const app = readFileSync(join(repoRoot, 'App.tsx'), 'utf8');
const packageJson = readFileSync(join(repoRoot, 'package.json'), 'utf8');
const hotUpdaterConfig = readFileSync(
  join(repoRoot, 'hot-updater.config.ts'),
  'utf8',
);
const ciWorkflow = readFileSync(
  join(repoRoot, '.github/workflows/ci.yml'),
  'utf8',
);
const releaseWorkflow = readFileSync(
  join(repoRoot, '.github/workflows/release.yml'),
  'utf8',
);
const fingerprint = JSON.parse(
  readFileSync(join(repoRoot, 'fingerprint.json'), 'utf8'),
);
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
const displaySnapshotHook = readFileSync(
  join(repoRoot, 'src/hooks/display/useDisplaySnapshot.ts'),
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
const modeSummary = readFileSync(
  join(repoRoot, 'src/components/ModeSummary.tsx'),
  'utf8',
);
const resolutionModeOverlay = readFileSync(
  join(repoRoot, 'src/components/ResolutionModeOverlay.tsx'),
  'utf8',
);
const stringsSource = readFileSync(
  join(repoRoot, 'src/i18n/strings.ts'),
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
const nativeDisplayLocale = readFileSync(
  join(
    repoRoot,
    'macos/com.jingjing2222.macdisplaybar-macOS/NativeDisplayControl/RCTNativeDisplayLocale.h',
  ),
  'utf8',
);
const nativeDisplayTests = readFileSync(
  join(
    repoRoot,
    'macos/com.jingjing2222.macdisplaybarTests/RCTDisplayCoreNativeTests.mm',
  ),
  'utf8',
);
const nativeTestScheme = readFileSync(
  join(
    repoRoot,
    'macos/com.jingjing2222.macdisplaybar.xcodeproj/xcshareddata/xcschemes/macDisplayBarNativeTests.xcscheme',
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
const displayCorePath = join(
  repoRoot,
  'macos/com.jingjing2222.macdisplaybar-macOS/DisplayCore',
);
const displayCoreMain = readFileSync(
  join(displayCorePath, 'RCTDisplayCore.mm'),
  'utf8',
);
const displayCoreSectionFileNames = readdirSync(
  join(displayCorePath, 'Sections'),
)
  .filter((fileName) => fileName.endsWith('.inc.mm'))
  .sort();
const displayCoreSections = displayCoreSectionFileNames
  .map((fileName) =>
    readFileSync(join(displayCorePath, 'Sections', fileName), 'utf8'),
  )
  .join('\n');
const displayCoreDomainFileNames = readdirSync(join(displayCorePath, 'Domains'))
  .flatMap((domainName) =>
    readdirSync(join(displayCorePath, 'Domains', domainName))
      .filter((fileName) => fileName.endsWith('.inc.mm'))
      .map((fileName) => `${domainName}/${fileName}`),
  )
  .sort();
const displayCoreDomains = displayCoreDomainFileNames
  .map((fileName) =>
    readFileSync(join(displayCorePath, 'Domains', fileName), 'utf8'),
  )
  .join('\n');
const displayCoreUtilsFileNames = readdirSync(join(displayCorePath, 'Utils'))
  .filter((fileName) => fileName.endsWith('.h'))
  .sort();
const displayCoreUtils = displayCoreUtilsFileNames
  .map((fileName) =>
    readFileSync(join(displayCorePath, 'Utils', fileName), 'utf8'),
  )
  .join('\n');
const displayCore = `${displayCoreMain}\n${displayCoreSections}\n${displayCoreDomains}\n${displayCoreUtils}`;
const project = readFileSync(
  join(
    repoRoot,
    'macos/com.jingjing2222.macdisplaybar.xcodeproj/project.pbxproj',
  ),
  'utf8',
);

function methodSource(source: string, signature: string): string {
  const start = source.indexOf(signature);

  if (start < 0) {
    return '';
  }

  const nextMethod = source.indexOf('\n- (', start + signature.length);
  return source.slice(start, nextMethod > start ? nextMethod : undefined);
}

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
  'installDisplayOverride',
  'removeDisplayOverride',
  'reinitializeDisplay',
  'setNativePanelResolutionOverride',
  'clearNativePanelResolutionOverride',
  'setFlexibleScalingEnabled',
  'addCustomResolution',
  'removeCustomResolution',
  'setDisplayRotation',
  'enableXdrUpscale',
  'disableXdrUpscale',
  'softDisconnectDisplay',
  'reconnectDisplay',
  'createVirtualDisplay',
  'mirrorVirtualDisplayToTarget',
  'stopVirtualDisplayMirroring',
  'removeVirtualDisplay',
  'openDisplayPip',
  'setPipWindowFilter',
  'closeDisplayPip',
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
  'virtualDisplays',
  'pipWindows',
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
  'overrideInstalledPath',
  'overrideBackupPath',
  'overrideInstalledHash',
  'overrideBackupHash',
  'overridePendingReboot',
  'overridePendingReinitialize',
  'overrideLastError',
  'nativePanelWidth',
  'nativePanelHeight',
  'nativePanelOverrideWidth',
  'nativePanelOverrideHeight',
  'nativePanelResolutionStatus',
  'flexibleScalingEnabled',
  'flexibleScalingStatus',
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

const virtualDisplayFields = [
  'id',
  'targetDisplayID',
  'displayID',
  'mirrorTargetDisplayID',
  'mirrorSourceDisplayID',
  'mirrorMode',
  'mirrorStatus',
  'mirrorUpdatedAt',
  'name',
  'width',
  'height',
  'refreshRate',
  'isHiDpi',
  'serialNumber',
  'status',
  'lastError',
];

const pipWindowFields = [
  'id',
  'displayID',
  'name',
  'width',
  'height',
  'fps',
  'filter',
  'status',
  'lastError',
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

test('display core implementation is split by responsibility', () => {
  expect(displayCoreMain.split('\n').length).toBeLessThan(600);
  expect(displayCoreSectionFileNames).toEqual([
    'RCTDisplayCore+Actions.inc.mm',
    'RCTDisplayCore+AutomationLayout.inc.mm',
    'RCTDisplayCore+HardwareControls.inc.mm',
    'RCTDisplayCore+Modes.inc.mm',
    'RCTDisplayCore+Overrides.inc.mm',
    'RCTDisplayCore+PictureInPicture.inc.mm',
    'RCTDisplayCore+Snapshot.inc.mm',
    'RCTDisplayCore+VirtualDisplays.inc.mm',
  ]);
  for (const sectionFileName of displayCoreSectionFileNames) {
    expect(displayCoreMain).toContain(`#include "Sections/${sectionFileName}"`);
  }
  expect(displayCoreDomainFileNames).toEqual([
    'Modes/RCTDisplayCore+DisplayLayoutApply.inc.mm',
    'Modes/RCTDisplayCore+ModeApply.inc.mm',
    'Modes/RCTDisplayCore+ModeDictionary.inc.mm',
    'Modes/RCTDisplayCore+ModeListing.inc.mm',
    'Modes/RCTDisplayCore+PrivateModes.inc.mm',
    'Overrides/RCTDisplayCore+HiDpiRecipe.inc.mm',
    'Overrides/RCTDisplayCore+OverrideBundle.inc.mm',
    'Overrides/RCTDisplayCore+OverrideInstall.inc.mm',
    'Overrides/RCTDisplayCore+OverrideState.inc.mm',
    'VirtualDisplays/RCTDisplayCore+VirtualDisplayActivation.inc.mm',
    'VirtualDisplays/RCTDisplayCore+VirtualDisplayCreation.inc.mm',
    'VirtualDisplays/RCTDisplayCore+VirtualDisplayFallback.inc.mm',
    'VirtualDisplays/RCTDisplayCore+VirtualDisplayMirror.inc.mm',
    'VirtualDisplays/RCTDisplayCore+VirtualDisplayRecords.inc.mm',
    'VirtualDisplays/RCTDisplayCore+VirtualDisplayRestore.inc.mm',
  ]);
  expect(displayCoreSections).toContain(
    '#include "../Domains/Overrides/RCTDisplayCore+OverrideState.inc.mm"',
  );
  expect(displayCoreSections).toContain(
    '#include "../Domains/Modes/RCTDisplayCore+ModeListing.inc.mm"',
  );
  expect(displayCoreSections).toContain(
    '#include "../Domains/VirtualDisplays/RCTDisplayCore+VirtualDisplayCreation.inc.mm"',
  );
  expect(displayCoreUtilsFileNames).toEqual([
    'FileHashUtils.h',
    'KeyUtils.h',
    'NumberUtils.h',
    'ScaleResolutionUtils.h',
    'StringUtils.h',
    'SystemUtils.h',
  ]);
  for (const utilsFileName of displayCoreUtilsFileNames) {
    expect(displayCoreMain).toContain(`#import "Utils/${utilsFileName}"`);
  }
  expect(displayCoreUtils).toContain(
    'static inline NSString *MDBShellQuotedString',
  );
  expect(displayCoreUtils).toContain(
    'static inline NSString *MDBSHA256FileHash',
  );
  expect(displayCoreUtils).toContain('static inline double MDBClampDouble');
  expect(displayCoreUtils).toContain(
    'static inline NSTimeInterval MDBSystemBootTime',
  );
  expect(displayCoreUtils).toContain(
    'static inline NSString *MDBIntegerPairRefreshKey',
  );
  expect(displayCoreUtils).toContain(
    'static inline void MDBAppendOneKeyHiDpiScaleResolutionFamily',
  );
  expect(displayCoreSections).not.toContain('- (NSString *)shellQuotedString');
  expect(displayCoreSections).not.toContain('- (NSString *)fileHashForPath');
  expect(displayCoreSections).not.toContain('- (double)normalizedRotation');
  expect(displayCoreSections).not.toContain(
    '- (NSString *)resolutionRefreshKeyForWidth',
  );
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
    ...virtualDisplayFields,
    ...pipWindowFields,
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
  expect(bridge).toContain('RCTNativeDisplayResolvedSystemLocale()');
  expect(nativeDisplayLocale).toContain(
    'RCTNativeDisplayResolvedSystemLocaleFromValues',
  );
  expect(nativeDisplayLocale).toContain('NSLocale.preferredLanguages');
  expect(appEnvironmentApi).toContain(
    'NativeDisplayControl?.getSystemLocale()',
  );
  expect(i18nHook).toContain('appEnvironmentApi.getSystemLocale()');
  expect(i18nHook).not.toContain('Intl.');
});

test('native XCTest owns NativeDisplayControl behavior coverage', () => {
  expect(packageJson).toContain('"test:native"');
  expect(project).toContain('macDisplayBarNativeTests');
  expect(project).toContain('RCTDisplayCoreNativeTests.mm in Sources');
  expect(nativeTestScheme).toContain('macDisplayBarNativeTests.xctest');
  expect(nativeDisplayTests).toContain(
    'testNativeApiInventoryIsCoveredByDisplayCore',
  );
  expect(nativeDisplayTests).toContain(
    'testSystemLocaleResolutionUsesNativeFallbackRules',
  );
  expect(nativeDisplayTests).toContain(
    'RCTNativeDisplayResolvedSystemLocaleFromValues',
  );

  for (const method of requiredMethods) {
    expect(nativeDisplayTests).toContain(`@"${method}`);
  }

  for (const removedTsTest of [
    'NativeApiParity.test.ts',
    'NativeCoreBehaviorContract.test.ts',
    'NativeApiCoverageMatrix.test.ts',
    'DisplayControlApi.test.ts',
    'AppEnvironmentApi.test.ts',
  ]) {
    expect(existsSync(join(repoRoot, '__tests__', removedTsTest))).toBe(false);
  }
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
  const generatedHiDpiApplyMethod = methodSource(
    displayCore,
    '- (BOOL)applyAvailableHiDpiModeForDisplayID:',
  );
  const generatedModeBranch = displayCore.slice(
    displayCore.indexOf('- (BOOL)applyDisplayModeForDisplayID:'),
    displayCore.indexOf('- (BOOL)applyAvailableHiDpiModeForDisplayID:'),
  );
  const createVirtualDisplayMethod = displayCore.slice(
    displayCore.indexOf('- (NSDictionary *)createVirtualDisplay:'),
    displayCore.indexOf('- (NSDictionary *)mirrorVirtualDisplayToTarget:'),
  );

  expect(displayCore).toContain('generatedHiDpiModeComponentsFromModeID');
  expect(displayCore).toContain('applyAvailableHiDpiModeForDisplayID');
  expect(displayCore).toContain('installOverrideBundleAtPath');
  expect(displayCore).toContain('with administrator privileges');
  expect(displayCore).toContain('RCTDisplayOverrideInstallDirectory');
  expect(displayCore).toContain('stagedSourceURL');
  expect(displayCore).toContain('NSTemporaryDirectory()');
  expect(displayCore).toContain(
    'NSString *productFileName = [NSString stringWithFormat:@"DisplayProductID-%x", productID]',
  );
  expect(displayCore).not.toContain('DisplayProductID-%x.plist');
  expect(displayCore).toContain('edidOverridePath.length > 0');
  expect(displayCore).toContain('manifest[@"IODisplayEDID"]');
  expect(displayCore).toContain('Display override EDID payload unavailable');
  expect(displayCore).toContain(
    'Display override bundle skipped: displayID=%@ reason=no payload',
  );
  expect(displayCore).toContain('overridePayloadExistsForDisplayIDString');
  expect(displayCore).toContain('removeInstalledOverrideForDisplayIDString');
  expect(displayCore).toContain('overridePendingReboot');
  expect(displayCore).toContain('overridePendingReinitialize');
  expect(displayCore).toContain('overrideBackupPaths');
  expect(displayCore).toContain('overrideInstalledHashes');
  expect(displayCore).toContain('MDBFileMatchesStoredHash');
  expect(displayCore).toContain('CC_SHA256(data.bytes');
  expect(displayCore).toContain('/usr/bin/shasum -a 256');
  expect(displayCore).toContain('stagedSourcePrecondition');
  expect(displayCore).toContain('backupPrecondition');
  expect(displayCore).toContain(
    'Installed override is not managed by macDisplayBar',
  );
  expect(displayCore).toContain('Installed override changed externally');
  expect(displayCore).toContain('Display override target identity changed');
  expect(displayCore).toContain(
    'Display override install adopted matching managed target',
  );
  expect(displayCore).toContain(
    'Display override install found externally matching target',
  );
  expect(displayCore).not.toContain(
    'Display override install adopted matching target',
  );
  expect(displayCore).toContain('Display override backup changed externally');
  expect(displayCore).toContain('Override prepared');
  expect(displayCore).toContain(
    'IOServiceRequestProbe(service, kIOFBUserRequestProbe)',
  );
  expect(displayCore).toContain('/usr/bin/install -o root -g wheel -m 0644');
  expect(displayCore).not.toContain('@"CustomResolutions" : customResolutions');
  expect(displayCore).toContain('RCTDisplay4KWidth = 3840');
  expect(displayCore).toContain('RCTDisplay4KHeight = 2160');
  expect(displayCore).toContain('RCTPrivateDisplayModeIDPrefix = @"cgs"');
  expect(displayCore).toContain('RCTDISPLAY_ENABLE_PRIVATE_CGS_MODES');
  expect(displayCore).toContain('CGSGetNumberOfDisplayModes');
  expect(displayCore).toContain('CGSGetDisplayModeDescriptionOfLength');
  expect(displayCore).toContain('CGSConfigureDisplayMode');
  expect(displayCore).toContain('privateDisplaySymbolNamed');
  expect(displayCore).toContain('SkyLight.framework/SkyLight');
  expect(displayCore).toContain('privateDisplayModeDictionariesForDisplayID');
  expect(displayCore).toContain('privateDisplayModeExistsForDisplayID');
  expect(displayCore).toContain('RCTCGSMaxDisplayModeCount = 1024');
  expect(displayCore).toContain('Private display mode no longer available');
  expect(displayCore).toContain('Private display mode configure failed');
  expect(displayCore).toContain('Private CGS display modes scanned');
  expect(displayCore).toContain('Private CGS display mode applied');
  expect(displayCore).toContain('CGCancelDisplayConfiguration(config)');
  expect(displayCore).toContain('@"currentMode" : currentMode');
  expect(displayCore).toContain(
    'currentModeID = availableMode[@"id"] ?: currentModeID',
  );
  expect(spec).toContain("source?: 'coregraphics' | 'cgs' | 'generated'");
  expect(resolutionPicker).toContain('selectedMode?.isCurrent === true');
  expect(displayCore).toContain('isSub4KHiDpiUnlockTargetWithWidth');
  expect(displayCore).toContain('targetClass=%@');
  expect(displayCore).toContain('@"sub4k"');
  expect(displayCore).toContain('skipped4kOrAbove');
  expect(displayCore).toContain('skippedCgsOnly');
  expect(displayCore).toContain('[source isEqualToString:@"cgs"]');
  expect(displayCore).toContain('!targetIsSub4K');
  expect(displayCore).toContain('displayIsSub4KUnlockTarget');
  expect(displayCore).toContain('exactHiDpiExists');
  expect(displayCore).toContain('recipeInstalled');
  expect(spec).toContain('requiresRestart?: boolean');
  expect(displayCore).toContain('standardModeByResolutionRefresh.allValues');
  expect(displayCore).toContain('generatedTargetSummaries');
  expect(displayCore).toContain('@"isHiDpi" : @YES');
  expect(resolutionModeOverlay).toContain('!isInstallCandidate');
  expect(displayCore).toContain('@"requiresRestart"');
  expect(displayCore).toContain('MDBOneKeyHiDpiRecipeResolutionKeys');
  expect(displayCore).toContain('MDBAppendNearNativeHiDpiScaleResolutions');
  expect(displayCore).toContain('@0.99');
  expect(displayCore).toContain('@0.98');
  expect(displayCore).toContain('@0.97');
  expect(displayCore).toContain('NSClassFromString(@"CGVirtualDisplay")');
  expect(displayCore).toContain('CGVirtualDisplayMode');
  expect(displayCore).toContain('createVirtualDisplayRecordWithID');
  expect(displayCore).toContain('targetDisplayID');
  expect(displayCore).toContain('serialNumber');
  expect(displayCore).toContain('visibleDisplayIDForVirtualDisplay');
  expect(displayCore).toContain('targetIdentityKey');
  expect(displayCore).toContain(
    'resolvedVirtualMirrorTargetDisplayIDForRecord',
  );
  expect(displayCore).toContain('resolvedVirtualTargetDisplayIDForRecord');
  expect(displayCore).toContain('Virtual display target identity unavailable');
  expect(displayCore).toContain(
    'pausedRecord[@"lastError"] = @"Target unavailable"',
  );
  expect(displayCore).toContain(
    'NSMutableDictionary *pausedRecord = [record mutableCopy]',
  );
  expect(displayControlPanel).toContain('displayIdentityKeys.has');
  expect(spec).toContain('targetIdentityKey: string');
  expect(displayCore).toContain('resolvedMirrorTargetDisplayID');
  expect(displayCore).toContain('activeDisplayIDStringForIdentityKey');
  expect(displayCore).toContain(
    'Virtual mirror restore skipped because target identity is missing',
  );
  expect(displayCore).toContain(
    'Virtual display mirror target identity unavailable',
  );
  expect(displayCore).toContain('restoring:YES');
  expect(displayCore).toContain('[self removeVirtualDisplay:virtualDisplayID]');
  expect(displayCore).toContain('customResolutionStorageKeyForDisplayIDString');
  expect(displayCore).toContain('customResolutionRequestsForDisplayIDString');
  expect(displayCore).toContain(
    'NSString *matchedDisplayID = [self activeDisplayIDStringForIdentityKey:identityKey]',
  );
  expect(displayCore).toContain(
    'return matchedDisplayID.length > 0 ? matchedDisplayID : @""',
  );
  expect(displayCore).toContain(
    'generatedHiDpiInstallTargetIsAllowedForDisplayID',
  );
  expect(displayCore).toContain(
    'Generated HiDPI install rejected by target policy',
  );
  expect(displayCore).toContain('CGConfigureDisplayMirrorOfDisplay');
  expect(displayCore).toContain('Virtual display mirror post-check failed');
  expect(displayCore).toContain('target-mirrors-virtual');
  expect(displayCore).toContain('recordByApplyingVirtualMirrorForID');
  expect(displayCore).toContain('self.virtualDisplays[virtualDisplayID]');
  expect(displayCore).toContain('restoreManagedVirtualDisplays');
  expect(displayCore).toContain('sortedArrayUsingComparator');
  expect(displayCore).toContain('mirrorUpdatedAt');
  expect(displayCore).toContain('restoredMirrorTargets');
  expect(displayCore).toContain('createVirtualHiDpiFallbackForDisplayIDString');
  expect(displayCore).toContain(
    'Generated HiDPI virtual fallback skipped stale record',
  );
  expect(displayCore).toContain(
    '[updatedRecord[@"mirrorStatus"] isEqualToString:@"Mirrored to target"]',
  );
  expect(displayCore).toContain('HiDPI virtual fallback mirrored');
  expect(displayCore).toContain('recipe-exposed-exact-unavailable');
  expect(displayCore).toContain('install-completed-exact-unavailable');
  expect(displayCore).toContain(
    'Virtual display remove aborted because mirror stop failed',
  );
  expect(displayCore).toContain('Virtual display mirror stale record cleared');
  expect(displayCore).toContain('CGDisplayMirrorsDisplay');
  expect(displayCore).toContain('targetMirrorsThisVirtual');
  expect(displayCore).toContain('if (didStop)');
  expect(displayCore).toContain('didMutateInstall');
  expect(displayCore).toContain('didMutate:(BOOL *)didMutate');
  expect(displayCore).toContain(
    'self.overrideInstalledHashes[lifecycleKey].length > 0',
  );
  expect(displayCore).toContain('Installed externally');
  expect(displayCore).toContain(
    '[self.overridePendingReinitialize removeObjectForKey:lifecycleKey]',
  );
  expect(displayCore).toContain(
    '[self.overridePendingReboot removeObjectForKey:lifecycleKey]',
  );
  expect(displayCore).toContain(
    'self.overridePendingReinitialize[lifecycleKey] = @NO',
  );
  expect(displayCore).not.toContain(
    'self.overridePendingReboot[lifecycleKey] = @NO',
  );
  expect(displayCore).toContain('CGVirtualDisplay API shape unsupported');
  expect(displayCore).toContain('instancesRespondToSelector:modeInitSelector');
  expect(displayCore).toContain(
    'instancesRespondToSelector:displayInitSelector',
  );
  expect(displayCore).toContain('reason=invalid or inactive display');
  expect(displayCore).toContain('reason=missing vendor/product identity');
  expect(displayCore).toContain('absolute displayID not allowed');
  expect(displayCore).toContain('overrideTargetFileURLForLifecycleKey');
  expect(displayCore).toContain('outside display override directory');
  expect(displayCore).toContain(
    'Display override remove refused: unmanaged target',
  );
  expect(createVirtualDisplayMethod).not.toContain(
    'recordByApplyingVirtualMirrorForID',
  );
  expect(displayCore).toContain('refreshRate > 0 ? refreshRate : 60');
  expect(displayCore).not.toContain('MAX(refreshRate, 1)');
  expect(generatedModeBranch).toContain(
    'writeOverrideBundleForDisplayIDString:displayIDString\n' +
      '                                                           includeEdid:NO\n' +
      '                                                     customResolutions:generatedCustomResolutions',
  );
  expect(generatedModeBranch).toContain(
    'generatedHiDpiCustomResolutionRequestsWithWidth:width',
  );
  expect(generatedModeBranch).not.toContain(
    'saveCustomResolutionIfNeededForDisplayID:displayIDString',
  );
  expect(displayCore).not.toContain('NSSet<NSString *> *allowedKeys');
  expect(displayCore).not.toContain('[allowedKeys containsObject:key]');
  expect(displayCore).toContain('MDBAppendOneKeyHiDpiScaleResolutions');
  expect(displayCore).toContain('MDBOneKeyHiDpiScaleResolutionData');
  expect(displayCore).toContain('installedOneKeyHiDpiRecipeExistsForDisplayID');
  expect(displayCore).toContain('MDBIntegerPairRefreshKey');
  expect(displayCore).toContain('skippedNonTarget');
  expect(displayCore).not.toContain(
    'recipeIsExposed && installedOneKeyRecipe) {\n      continue;',
  );
  expect(displayCore).toContain('if (exactHiDpiExists)');
  expect(displayCore).toContain('targetIsMaxStandardResolution');
  expect(displayCore).toContain(
    '@[ @0x00, @0x00, @0x00, @0x09, @0x00, @0xa0, @0x00, @0x00 ]',
  );
  expect(displayCore).toContain(
    'installed override is not one-key complete; rewriting recipe',
  );
  expect(generatedModeBranch).toContain(
    'installOverrideBundleAtPath:bundlePath',
  );
  expect(generatedModeBranch).toContain('!didApplyMode && didInstallBundle');
  expect(generatedModeBranch).toContain('attempt < 3 && !didApplyMode');
  expect(generatedHiDpiApplyMethod).toContain(
    'CGDisplaySetDisplayMode(displayID, hiDpiMode, NULL)',
  );
  expect(displayCore).toContain('HiDPI settings installed');
  expect(displayCore).toContain('PC restart required before virtual fallback');
  expect(displayCore).toContain('Virtual display activation pending');
  expect(displayCore).toContain('scheduleVirtualDisplayActivationRetryForID');
  expect(displayCore).toContain(
    'Virtual display mirror queued pending activation',
  );
  expect(displayCore).toContain(
    'dispatch_async(dispatch_get_main_queue(), ^{\n      [self restoreManagedVirtualDisplays];',
  );
  expect(displayCore).toContain(
    'RCTDisplayNativePanelResolutionOverridesDefaultsKey',
  );
  expect(displayCore).toContain('RCTDisplayFlexibleScalingDefaultsKey');
  expect(displayCore).toContain('detectedNativePanelResolutionForDisplayID');
  expect(displayCore).toContain('nativePanelResolutionForDisplayID');
  expect(displayCore).toContain(
    'setNativePanelResolutionOverride:(NSString *)displayID',
  );
  expect(displayCore).toContain(
    'self.nativePanelResolutionOverrides[lifecycleKey]',
  );
  expect(displayCore).toContain('setFlexibleScalingEnabled');
  expect(displayCore).toContain('self.flexibleScalingEnabled[lifecycleKey]');
  expect(displayCore).toContain('Flexible scaling state changed');
  expect(displayCore).toContain(
    'flexibleScalingEnabled || hasPanelResolutionOverride',
  );
  expect(displayCore).toContain('nativePanel=%lux%lu');
  expect(displayCore).not.toContain('GeneratedHiDpiOverlay');
  expect(displayCore).toContain('Bundle written (install required)');
  expect(displayCore).toContain('Enabled - install required');
  expect(displayCore).toContain('exact mode unavailable');
  expect(generatedHiDpiApplyMethod).not.toContain('allowStandardFallback');
  expect(generatedHiDpiApplyMethod).not.toContain('fallbackMode');
});

test('Picture in Picture windows are live session resources', () => {
  const openPipMethod = displayCore.slice(
    displayCore.indexOf('- (NSDictionary *)openDisplayPip:'),
    displayCore.indexOf('- (NSDictionary *)closeDisplayPip:'),
  );
  const closePipMethod = displayCore.slice(
    displayCore.indexOf('- (NSDictionary *)closeDisplayPip:'),
    displayCore.indexOf('- (NSDictionary *)saveFavoriteMode:'),
  );
  const capturePipMethod = displayCore.slice(
    displayCore.indexOf('- (void)capturePipFrameForID:'),
    displayCore.indexOf('- (NSDictionary *)stubbedSnapshot'),
  );

  expect(displayCore).toContain(
    'removeObjectForKey:RCTDisplayPipWindowsDefaultsKey',
  );
  expect(displayCore).toContain('pipCloseObservers');
  expect(openPipMethod).toContain('NSWindowWillCloseNotification');
  expect(openPipMethod).toContain('existingWindow != nil');
  expect(openPipMethod).toContain('NSScreen *pipScreen');
  expect(closePipMethod).toContain('removeObserver:closeObserver');
  expect(displayCore).toContain('#import <CoreImage/CoreImage.h>');
  expect(displayCore).toContain('CIContext *pipFilterContext');
  expect(displayCore).toContain('strong) dispatch_queue_t pipCaptureQueue');
  expect(displayCore).toContain('normalizedPipFilter');
  expect(displayCore).toContain('newPipImageFromImage');
  expect(displayCore).toContain('setPipWindowFilter');
  expect(displayCore).toContain('CIPhotoEffectMono');
  expect(displayCore).toContain('CIColorInvert');
  expect(displayCore).toContain('CISepiaTone');
  expect(displayCore).toContain('CIVibrance');
  expect(capturePipMethod).toContain('windowWasOnCapturedDisplay');
  expect(capturePipMethod).toContain('normalizedCurrentFilter');
  expect(capturePipMethod).toContain(
    '![normalizedCurrentFilter isEqualToString:normalizedFilter]',
  );
  expect(capturePipMethod).toContain('updatedRecord[@"filter"]');
  expect(capturePipMethod).toContain('displayIDStringIsActive:displayID');
  expect(capturePipMethod).toContain(
    'pipCaptureTimers removeObjectForKey:pipWindowID',
  );
  expect(capturePipMethod).toContain(
    'pipWindowRecords removeObjectForKey:pipWindowID',
  );
  expect(capturePipMethod).toContain('source display is unavailable');
  expect(capturePipMethod).toContain('CGWindowListCreateImage');
  expect(capturePipMethod).toContain('kCGWindowListOptionOnScreenBelowWindow');
  expect(capturePipMethod).toContain('CGDisplayCreateImage(directDisplayID)');
  expect(displayCore).not.toContain('setObject:self.pipWindowRecords');
});

test('generated mode state labels are translated through shared keys', () => {
  expect(stringsSource).toContain('installTarget');
  expect(modeSummary).toContain("t('pcRestart')");
  expect(modeSummary).toContain("t('installTarget')");
  expect(resolutionPicker).toContain('modeScaleLabel(mode, t)');
  expect(resolutionPicker).not.toContain("? 'PC Restart'");
  expect(resolutionPicker).not.toContain("? 'Install target'");
  expect(resolutionModeOverlay).toContain('t={t}');
  expect(stringsSource).toContain("pcRestart: 'PC Restart'");
  expect(stringsSource).toContain("flexibleScaling: 'Flexible scaling'");
  expect(stringsSource).toContain("nativePanelResolution: 'Native panel'");
  expect(stringsSource).toContain("pictureInPicture: 'Picture in Picture'");
  expect(stringsSource).toContain("pcRestart: 'PC 재시작'");
  expect(stringsSource).toContain("flexibleScaling: '유연한 스케일링'");
  expect(stringsSource).toContain("nativePanelResolution: '네이티브 패널'");
  expect(stringsSource).toContain("pictureInPicture: '화면 속 화면'");
});

test('live PiP and virtual display resources refresh even when auto refresh is off', () => {
  expect(displaySnapshotHook).toContain('hasManagedLiveResources');
  expect(displaySnapshotHook).toContain('value.pipWindows.length > 0');
  expect(displaySnapshotHook).toContain('value.virtualDisplays.length > 0');
  expect(displaySnapshotHook).toContain('return 2000');
});

test('native fingerprint includes codegen specs as file contents', () => {
  expect(hotUpdaterConfig).toContain("'specs/**/*.ts'");
  expect(hotUpdaterConfig).not.toContain(
    "'macos/com.jingjing2222.macdisplaybar-macOS/Info.plist'",
  );
  expect(ciWorkflow).toContain(
    '"macos/com.jingjing2222.macdisplaybar-macOS/Info.plist"',
  );
  expect(ciWorkflow).toContain('macos/fingerprint-version.txt');
  expect(releaseWorkflow).toContain('macos/fingerprint-version.txt');
  expect(releaseWorkflow).toContain('workflow_dispatch');
  expect(releaseWorkflow).toContain('steps.version.outputs.version_changed');
  const detectReleaseVersionScript = readFileSync(
    join(repoRoot, 'scripts/ci/detect-release-version.mjs'),
    'utf8',
  );
  expect(detectReleaseVersionScript).not.toContain(
    "process.env.GITHUB_EVENT_NAME === 'workflow_dispatch'",
  );
  expect(detectReleaseVersionScript).toContain('tagExists(currentTag)');

  const fingerprintSources = [
    ...(fingerprint.ios?.sources ?? []),
    ...(fingerprint.android?.sources ?? []),
  ];
  const specSource = fingerprintSources.find(
    (source) => source.id === 'specs/NativeDisplayControl.ts',
  );

  expect(specSource).toBeDefined();
  expect(specSource.hash).toEqual(expect.any(String));
  expect(specSource.contents).toContain('export interface Spec');
  expect(fingerprintSources).toContainEqual(
    expect.objectContaining({
      id: 'macos/com.jingjing2222.macdisplaybar-macOS/DisplayCore/RCTDisplayCore.mm',
    }),
  );
  expect(fingerprintSources).toContainEqual(
    expect.objectContaining({
      id: 'macos/com.jingjing2222.macdisplaybar-macOS/DisplayCore/RCTDisplayCore.h',
    }),
  );
  expect(fingerprintSources).toContainEqual(
    expect.objectContaining({
      id: 'macos/com.jingjing2222.macdisplaybar-macOS/NativeDisplayControl/RCTNativeDisplayControl.mm',
    }),
  );
  expect(fingerprintSources).not.toContainEqual(
    expect.objectContaining({
      id: 'macos/com.jingjing2222.macdisplaybar-macOS/Info.plist',
    }),
  );
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
