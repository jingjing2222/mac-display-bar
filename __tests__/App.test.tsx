/**
 * @format
 */

import React from 'react';
import { Pressable, ScrollView, TextInput } from 'react-native';
import ReactTestRenderer from 'react-test-renderer';
import { vi } from 'vitest';

import { languageFromLocale } from '../src/i18n/useI18n';
import NativeDisplayControl from '../specs/NativeDisplayControl';

const nativeSnapshot = vi.hoisted(() => ({
  moduleStatus: 'ready',
  generatedAt: '2026-05-22T00:00:00Z',
  platform: 'macOS',
  architecture: 'arm64',
  machineModel: 'Mac15,6',
  isAppleSilicon: true,
  displayTopologyRevision: 2,
  displayTopologyStatus: 'Stable',
  displayTopologyChangedAt: '',
  virtualDisplays: [
    {
      id: 'virtual-1',
      targetDisplayID: '1',
      targetIdentityKey: 'B7E8A6A8-2C78-49C5-B509-A3E73E4761BD',
      displayID: '8',
      mirrorTargetDisplayID: '1',
      mirrorSourceDisplayID: '8',
      mirrorMode: 'target-mirrors-virtual',
      mirrorStatus: 'Mirrored to target',
      mirrorUpdatedAt: 0,
      name: 'macDisplayBar Virtual 3440x1440',
      width: 3440,
      height: 1440,
      refreshRate: 60,
      isHiDpi: true,
      serialNumber: 1234,
      status: 'Created',
      lastError: '',
    },
  ],
  pipWindows: [
    {
      id: 'pip-1',
      displayID: '1',
      name: 'macDisplayBar PiP - Color LCD',
      width: 480,
      height: 270,
      fps: 2,
      filter: 'none',
      status: 'Open',
      lastError: '',
    },
  ],
  presets: [
    { name: 'Desk', createdAt: '2026-05-22T00:00:00Z', displayCount: 1 },
  ],
  syncGroups: [
    {
      id: 'group-1',
      name: 'All displays',
      displayIDs: ['1'],
      brightnessSync: true,
      scaleSync: true,
      layoutProtection: true,
    },
  ],
  layoutProtectionEnabled: true,
  layoutProtectionStatus: 'Protected',
  layoutDriftCount: 0,
  settings: {
    autoRefresh: true,
    refreshIntervalSeconds: 15,
    showAdvancedMetadata: true,
  },
  displays: [
    {
      id: '1',
      name: 'Color LCD',
      connectionType: 'built-in',
      isPrimary: true,
      isBuiltin: true,
      isOnline: true,
      isActive: true,
      isAsleep: false,
      isMirrored: false,
      isHardwareMirrored: false,
      mirrorsDisplayID: '',
      identity: {
        uuid: 'B7E8A6A8-2C78-49C5-B509-A3E73E4761BD',
        vendorID: 1552,
        modelID: 41032,
        serialNumber: 1234,
        productName: 'Liquid Retina XDR',
        transport: 'built-in',
      },
      rotation: 0,
      frame: { x: 0, y: 0, width: 1512, height: 982 },
      currentMode: {
        id: '3024x1964@120x2',
        width: 3024,
        height: 1964,
        refreshRate: 120,
        isHiDpi: true,
        isCurrent: true,
        isFavorite: true,
      },
      availableModes: [
        {
          id: '3024x1964@120x2',
          width: 3024,
          height: 1964,
          refreshRate: 120,
          isHiDpi: true,
          isCurrent: true,
          isFavorite: true,
        },
        {
          id: '1920x1200@60x2',
          width: 1920,
          height: 1200,
          refreshRate: 60,
          isHiDpi: true,
          isCurrent: false,
          isFavorite: false,
          requiresOverride: true,
        },
        {
          id: 'generated-hidpi:3440:1440:60.000',
          width: 3440,
          height: 1440,
          refreshRate: 60,
          isHiDpi: false,
          isCurrent: false,
          isFavorite: false,
          requiresOverride: true,
          source: 'generated' as const,
        },
      ],
      modeStatus: 'Ready',
      modeError: '',
      nativeBrightness: 0.75,
      brightnessControl: 'native',
      brightnessError: '',
      softwareDimming: 0.25,
      supportsBrightness: true,
      supportsSoftwareDimming: true,
      supportsDdc: true,
      ddc: {
        brightness: 75,
        contrast: 50,
        volume: 25,
        inputSource: 17,
        readStatus: 'Live',
        lastError: '',
      },
      supportsHdr: true,
      hdr: {
        isSupported: true,
        isActive: true,
        currentHeadroom: 2,
        potentialHeadroom: 4,
        referenceHeadroom: 1,
        xdrPreset: 'Reference capable',
      },
      colorProfileStatus: 'Ready',
      colorProfileError: '',
      colorProfiles: [
        {
          id: 'profile-1',
          name: 'Display P3',
          path: '/Library/ColorSync/Profiles/Display P3.icc',
          isCurrent: true,
          isFactory: true,
        },
      ],
      advanced: {
        supportsEdidExport: true,
        edidBytes: 128,
        edidExportPath: '/tmp/EDID-1.bin',
        edidOverridePath: '',
        edidOverrideStatus: 'No override',
        overrideBundlePath: '',
        overrideBundleStatus: 'No bundle',
        overrideInstalledPath: '',
        overrideBackupPath: '',
        overrideInstalledHash: '',
        overrideBackupHash: '',
        overridePendingReboot: false,
        overridePendingReinitialize: false,
        overrideLastError: '',
        nativePanelWidth: 3440,
        nativePanelHeight: 1440,
        nativePanelOverrideWidth: 3440,
        nativePanelOverrideHeight: 1440,
        nativePanelResolutionStatus: 'Override 3440x1440 (detected 3440x1440)',
        flexibleScalingEnabled: true,
        flexibleScalingStatus: 'Enabled',
        rotationRequest: 0,
        rotationStatus: 'Current',
        softConnectionState: 'connected',
        xdrUpscaleState: 'disabled',
        lastOperation: 'EDID exported',
        lastOperationAt: '2026-05-22T00:00:00Z',
        customResolutions: [
          {
            id: 'custom-1',
            width: 3008,
            height: 1692,
            refreshRate: 60,
            isHiDpi: true,
            status: 'Queued for override',
          },
        ],
      },
    },
    {
      id: '2',
      name: 'Studio Display',
      connectionType: 'thunderbolt',
      isPrimary: false,
      isBuiltin: false,
      isOnline: true,
      isActive: true,
      isAsleep: false,
      isMirrored: false,
      isHardwareMirrored: false,
      mirrorsDisplayID: '',
      identity: {
        uuid: 'C8E8A6A8-2C78-49C5-B509-A3E73E4761BD',
        vendorID: 1552,
        modelID: 41033,
        serialNumber: 5678,
        productName: 'Studio Display',
        transport: 'thunderbolt',
      },
      rotation: 0,
      frame: { x: 1512, y: 0, width: 1600, height: 1000 },
      currentMode: {
        id: '2560x1440@60x2',
        width: 2560,
        height: 1440,
        refreshRate: 60,
        isHiDpi: true,
        isCurrent: true,
        isFavorite: false,
      },
      availableModes: [],
      modeStatus: 'Ready',
      modeError: '',
      nativeBrightness: 0.5,
      brightnessControl: 'native',
      brightnessError: '',
      softwareDimming: 0,
      supportsBrightness: true,
      supportsSoftwareDimming: true,
      supportsDdc: false,
      ddc: {
        brightness: 50,
        contrast: 50,
        volume: 0,
        inputSource: 0,
        readStatus: 'Unavailable',
        lastError: '',
      },
      supportsHdr: false,
      hdr: {
        isSupported: false,
        isActive: false,
        currentHeadroom: 1,
        potentialHeadroom: 1,
        referenceHeadroom: 1,
        xdrPreset: 'Unavailable',
      },
      colorProfileStatus: 'Ready',
      colorProfileError: '',
      colorProfiles: [],
      advanced: {
        supportsEdidExport: true,
        edidBytes: 128,
        edidExportPath: '',
        edidOverridePath: '',
        edidOverrideStatus: 'No override',
        overrideBundlePath: '',
        overrideBundleStatus: 'No bundle',
        overrideInstalledPath: '',
        overrideBackupPath: '',
        overrideInstalledHash: '',
        overrideBackupHash: '',
        overridePendingReboot: false,
        overridePendingReinitialize: false,
        overrideLastError: '',
        nativePanelWidth: 5120,
        nativePanelHeight: 2880,
        nativePanelOverrideWidth: 0,
        nativePanelOverrideHeight: 0,
        nativePanelResolutionStatus: 'Detected 5120x2880',
        flexibleScalingEnabled: false,
        flexibleScalingStatus: 'Disabled',
        rotationRequest: 0,
        rotationStatus: 'Current',
        softConnectionState: 'connected',
        xdrUpscaleState: 'disabled',
        lastOperation: '',
        lastOperationAt: '',
        customResolutions: [],
      },
    },
  ],
}));

const hotUpdaterMocks = vi.hoisted(() => ({
  checkForUpdate: vi.fn(),
  isUpdateDownloaded: vi.fn(),
  reload: vi.fn(),
  updateBundle: vi.fn(),
}));

vi.mock('@hot-updater/react-native', () => ({
  HotUpdater: {
    checkForUpdate: hotUpdaterMocks.checkForUpdate,
    isUpdateDownloaded: hotUpdaterMocks.isUpdateDownloaded,
    reload: hotUpdaterMocks.reload,
    wrap: () => (Component: React.ComponentType) => Component,
  },
}));

vi.mock('../specs/NativeDisplayControl', () => {
  const nativeModule = {
    getSystemLocale: vi.fn(() => 'en-US'),
    getSnapshot: vi.fn(() => nativeSnapshot),
    refreshSnapshot: vi.fn(() => nativeSnapshot),
    setNativeBrightness: vi.fn(() => nativeSnapshot),
    setSoftwareDimming: vi.fn(() => nativeSnapshot),
    setDisplayMode: vi.fn(() => nativeSnapshot),
    setDisplayOrigin: vi.fn(() => nativeSnapshot),
    savePreset: vi.fn(() => nativeSnapshot),
    applyPreset: vi.fn(() => nativeSnapshot),
    deletePreset: vi.fn(() => nativeSnapshot),
    setColorProfile: vi.fn(() => nativeSnapshot),
    resetColorProfile: vi.fn(() => nativeSnapshot),
    saveProtectedLayout: vi.fn(() => nativeSnapshot),
    restoreProtectedLayout: vi.fn(() => nativeSnapshot),
    clearProtectedLayout: vi.fn(() => nativeSnapshot),
    saveSyncGroup: vi.fn(() => nativeSnapshot),
    applySyncGroup: vi.fn(() => nativeSnapshot),
    deleteSyncGroup: vi.fn(() => nativeSnapshot),
    exportEdid: vi.fn(() => nativeSnapshot),
    addCustomResolution: vi.fn(() => nativeSnapshot),
    removeCustomResolution: vi.fn(() => nativeSnapshot),
    queueEdidOverride: vi.fn(() => nativeSnapshot),
    clearEdidOverride: vi.fn(() => nativeSnapshot),
    writeOverrideBundle: vi.fn(() => nativeSnapshot),
    installDisplayOverride: vi.fn(() => nativeSnapshot),
    removeDisplayOverride: vi.fn(() => nativeSnapshot),
    reinitializeDisplay: vi.fn(() => nativeSnapshot),
    setNativePanelResolutionOverride: vi.fn(() => nativeSnapshot),
    clearNativePanelResolutionOverride: vi.fn(() => nativeSnapshot),
    setFlexibleScalingEnabled: vi.fn(() => nativeSnapshot),
    setDisplayRotation: vi.fn(() => nativeSnapshot),
    enableXdrUpscale: vi.fn(() => nativeSnapshot),
    disableXdrUpscale: vi.fn(() => nativeSnapshot),
    softDisconnectDisplay: vi.fn(() => nativeSnapshot),
    reconnectDisplay: vi.fn(() => nativeSnapshot),
    createVirtualDisplay: vi.fn(() => nativeSnapshot),
    mirrorVirtualDisplayToTarget: vi.fn(() => nativeSnapshot),
    stopVirtualDisplayMirroring: vi.fn(() => nativeSnapshot),
    removeVirtualDisplay: vi.fn(() => nativeSnapshot),
    openDisplayPip: vi.fn(() => nativeSnapshot),
    setPipWindowFilter: vi.fn(() => nativeSnapshot),
    closeDisplayPip: vi.fn(() => nativeSnapshot),
    saveFavoriteMode: vi.fn(() => nativeSnapshot),
    removeFavoriteMode: vi.fn(() => nativeSnapshot),
    setDdcControl: vi.fn(() => nativeSnapshot),
    setSettings: vi.fn(() => nativeSnapshot),
  };

  return { default: nativeModule };
});

import App from '../App';

beforeEach(() => {
  vi.mocked(NativeDisplayControl!.getSystemLocale).mockReset();
  vi.mocked(NativeDisplayControl!.getSystemLocale).mockReturnValue('en-US');
  hotUpdaterMocks.checkForUpdate.mockReset();
  hotUpdaterMocks.checkForUpdate.mockResolvedValue(null);
  hotUpdaterMocks.isUpdateDownloaded.mockReset();
  hotUpdaterMocks.isUpdateDownloaded.mockReturnValue(false);
  hotUpdaterMocks.reload.mockReset();
  hotUpdaterMocks.reload.mockResolvedValue(undefined);
  hotUpdaterMocks.updateBundle.mockReset();
  hotUpdaterMocks.updateBundle.mockResolvedValue(true);
  vi.mocked(NativeDisplayControl!.setDisplayMode).mockClear();
});

afterEach(() => {
  vi.useRealTimers();
  vi.restoreAllMocks();
});

test('renders correctly', async () => {
  await ReactTestRenderer.act(() => {
    ReactTestRenderer.create(<App />);
  });
});

test('uses the fixed menu bar popover width', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const scrollView = renderer!.root.findByType(ScrollView);

  expect(scrollView.props.style).toEqual(
    expect.objectContaining({
      width: 520,
    }),
  );
});

test('renders redesigned BetterDisplay-style controls from native snapshot', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const renderedText = JSON.stringify(renderer!.toJSON());
  expect(renderedText).toContain('macDisplayBar');
  expect(renderedText).toContain('App update');
  expect(renderedText).toContain('Check for updates');
  expect(renderedText).toContain('Color LCD');
  expect(renderedText).toContain('Display');
  expect(renderedText).toContain('Quick controls');
  expect(renderedText).toContain('Brightness');
  expect(renderedText).toContain('Dimming');
  expect(renderedText).toContain('Resolution');
  expect(renderedText).not.toContain('DDC hardware');
  expect(renderedText).not.toContain('EDID');
  expect(renderedText).not.toContain('UUID');
  expect(renderedText).not.toContain('moduleStatus');
  expect(renderedText).not.toContain('Native module');
});

test('opens display dropdown and selects another display', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const trigger = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('Color LCD'));

  await ReactTestRenderer.act(() => {
    trigger!.props.onPress();
  });

  const renderedText = JSON.stringify(renderer!.toJSON());
  expect(renderedText).toContain('Studio Display');
});

test('opens a searchable resolution overlay', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const trigger = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('Current mode'));

  await ReactTestRenderer.act(async () => {
    trigger!.props.onPress();
    await new Promise((resolve) => setTimeout(resolve, 0));
  });

  let renderedText = normalizedText(renderer!.root);
  expect(renderedText).toContain('Choose resolution');
  expect(renderedText).toContain('1920 x 1200');

  const searchInput = renderer!.root.findByType(TextInput);

  await ReactTestRenderer.act(() => {
    searchInput.props.onChangeText('1200');
  });

  renderedText = normalizedText(renderer!.root);
  expect(renderedText).toContain('1920 x 1200');
});

test('asks to revert after selecting a new resolution', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const trigger = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('Current mode'));

  await ReactTestRenderer.act(async () => {
    trigger!.props.onPress();
    await new Promise((resolve) => setTimeout(resolve, 0));
  });

  const modeRow = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('1920 x 1200'));

  await ReactTestRenderer.act(async () => {
    modeRow!.props.onPress();
    await new Promise((resolve) => setTimeout(resolve, 0));
  });

  expect(NativeDisplayControl!.setDisplayMode).toHaveBeenCalledWith(
    '1',
    '1920x1200@60x2',
  );
  expect(normalizedText(renderer!.root)).toContain(
    'Return to the previous resolution?',
  );

  const revertButton = renderer!.root.findByProps({
    accessibilityLabel: 'Return',
  });

  await ReactTestRenderer.act(async () => {
    revertButton.props.onPress();
    await new Promise((resolve) => setTimeout(resolve, 0));
  });

  expect(NativeDisplayControl!.setDisplayMode).toHaveBeenCalledWith(
    '1',
    '3024x1964@120x2',
  );
});

test('reverts resolution with Enter submit capture', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const trigger = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('Current mode'));

  await ReactTestRenderer.act(async () => {
    trigger!.props.onPress();
    await new Promise((resolve) => setTimeout(resolve, 0));
  });

  const modeRow = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('1920 x 1200'));

  await ReactTestRenderer.act(async () => {
    modeRow!.props.onPress();
    await new Promise((resolve) => setTimeout(resolve, 0));
  });

  const keyboardInput = renderer!.root.findByProps({
    submitBehavior: 'submit',
  });

  await ReactTestRenderer.act(async () => {
    keyboardInput.props.onSubmitEditing();
    await new Promise((resolve) => setTimeout(resolve, 0));
  });

  expect(NativeDisplayControl!.setDisplayMode).toHaveBeenCalledWith(
    '1',
    '3024x1964@120x2',
  );
});

test('generated HiDPI mode installs without opening a guidance or revert flow', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const trigger = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('Current mode'));

  await ReactTestRenderer.act(async () => {
    trigger!.props.onPress();
    await new Promise((resolve) => setTimeout(resolve, 0));
  });

  const modeRow = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('3440 x 1440'));

  expect(
    renderer!.root
      .findAllByProps({ accessibilityRole: 'button' })
      .some((node) => normalizedText(node).includes('Install')),
  ).toBe(true);

  await ReactTestRenderer.act(async () => {
    modeRow!.props.onPress();
    await new Promise((resolve) => setTimeout(resolve, 0));
  });

  expect(NativeDisplayControl!.setDisplayMode).toHaveBeenCalledWith(
    '1',
    'generated-hidpi:3440:1440:60.000',
  );
  expect(normalizedText(renderer!.root)).not.toContain('HiDPI mode needs');
  expect(normalizedText(renderer!.root)).not.toContain(
    'Return to the previous resolution?',
  );
});

test('restart-required generated HiDPI row is status-only', async () => {
  const restartSnapshot = {
    ...nativeSnapshot,
    displays: [
      {
        ...nativeSnapshot.displays[0],
        currentMode: {
          ...nativeSnapshot.displays[0].currentMode,
          isFavorite: false,
        },
        availableModes: [
          {
            ...nativeSnapshot.displays[0].availableModes[0],
            isFavorite: false,
          },
          {
            id: 'generated-hidpi:3440:1440:60.000',
            width: 3440,
            height: 1440,
            refreshRate: 60,
            isHiDpi: true,
            isCurrent: false,
            isFavorite: false,
            requiresOverride: true,
            requiresRestart: true,
            source: 'generated' as const,
          },
        ],
      },
    ],
  };
  vi.mocked(NativeDisplayControl!.getSnapshot).mockReturnValueOnce(
    restartSnapshot,
  );
  vi.mocked(NativeDisplayControl!.refreshSnapshot).mockReturnValueOnce(
    restartSnapshot,
  );
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const restartButtons = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .filter((node) => normalizedText(node).includes('PC Restart'));

  expect(restartButtons.length).toBeGreaterThan(0);
  expect(restartButtons.every((node) => node.props.disabled === true)).toBe(
    true,
  );
  expect(NativeDisplayControl!.setDisplayMode).not.toHaveBeenCalledWith(
    '1',
    'generated-hidpi:3440:1440:60.000',
  );
});

test('advanced tab exposes low-level display operations only after selection', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const advancedTab = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('Advanced'));

  await ReactTestRenderer.act(() => {
    advancedTab!.props.onPress();
  });

  const renderedText = JSON.stringify(renderer!.toJSON());
  expect(renderedText).toContain('Advanced');
  expect(renderedText).toContain('Display information');
  expect(renderedText).toContain('Custom resolution');
  expect(renderedText).toContain('Extra brightness');
  expect(renderedText).toContain('Flexible scaling');
  expect(renderedText).toContain('Native panel');
  expect(renderedText).toContain('UUID');
  expect(renderedText).toContain('Sync and layout');
});

test('advanced tab wires override install lifecycle actions', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const advancedTab = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('Advanced'));

  await ReactTestRenderer.act(() => {
    advancedTab!.props.onPress();
  });

  const installButton = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('Install'));
  const removeButton = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('Remove'));

  await ReactTestRenderer.act(() => {
    installButton!.props.onPress();
  });
  await ReactTestRenderer.act(() => {
    removeButton!.props.onPress();
  });

  expect(NativeDisplayControl!.installDisplayOverride).toHaveBeenCalledWith(
    '1',
  );
  expect(NativeDisplayControl!.removeDisplayOverride).toHaveBeenCalledWith('1');
});

test('advanced tab wires flexible scaling and native panel resolution actions', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const advancedTab = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('Advanced'));

  await ReactTestRenderer.act(() => {
    advancedTab!.props.onPress();
  });

  const enableButton = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('Enable'));
  const setPanelButton = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('Set panel'));
  const clearPanelButton = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('Clear panel'));

  await ReactTestRenderer.act(() => {
    enableButton!.props.onPress();
  });
  await ReactTestRenderer.act(() => {
    setPanelButton!.props.onPress();
  });
  await ReactTestRenderer.act(() => {
    clearPanelButton!.props.onPress();
  });

  expect(NativeDisplayControl!.setFlexibleScalingEnabled).toHaveBeenCalledWith(
    '1',
    true,
  );
  expect(
    NativeDisplayControl!.setNativePanelResolutionOverride,
  ).toHaveBeenCalledWith('1', 3440, 1440);
  expect(
    NativeDisplayControl!.clearNativePanelResolutionOverride,
  ).toHaveBeenCalledWith('1');
});

test('advanced tab creates and removes virtual displays', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const advancedTab = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('Advanced'));

  await ReactTestRenderer.act(() => {
    advancedTab!.props.onPress();
  });

  const createVirtualButton = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('Create virtual'));
  const virtualWidthInput = renderer!.root.findByProps({
    accessibilityLabel: 'Virtual display Width',
  });
  const virtualHeightInput = renderer!.root.findByProps({
    accessibilityLabel: 'Virtual display Height',
  });
  const virtualRefreshInput = renderer!.root.findByProps({
    accessibilityLabel: 'Virtual display Hz',
  });
  const removeVirtualButton = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('Remove virtual'));
  const mirrorVirtualButton = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('Mirror'));
  const stopMirrorButton = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('Stop mirror'));

  await ReactTestRenderer.act(() => {
    virtualWidthInput!.props.onChangeText('3840');
    virtualHeightInput!.props.onChangeText('2160');
    virtualRefreshInput!.props.onChangeText('100');
  });
  await ReactTestRenderer.act(() => {
    createVirtualButton!.props.onPress();
  });
  await ReactTestRenderer.act(() => {
    mirrorVirtualButton!.props.onPress();
  });
  await ReactTestRenderer.act(() => {
    stopMirrorButton!.props.onPress();
  });
  await ReactTestRenderer.act(() => {
    removeVirtualButton!.props.onPress();
  });

  expect(NativeDisplayControl!.createVirtualDisplay).toHaveBeenCalledWith(
    '1',
    3840,
    2160,
    100,
    true,
  );
  expect(
    NativeDisplayControl!.mirrorVirtualDisplayToTarget,
  ).toHaveBeenCalledWith('virtual-1');
  expect(
    NativeDisplayControl!.stopVirtualDisplayMirroring,
  ).toHaveBeenCalledWith('virtual-1');
  expect(NativeDisplayControl!.removeVirtualDisplay).toHaveBeenCalledWith(
    'virtual-1',
  );
});

test('advanced tab opens and closes Picture in Picture windows', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const advancedTab = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('Advanced'));

  await ReactTestRenderer.act(() => {
    advancedTab!.props.onPress();
  });

  const openPipButton = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('Open PiP'));
  const closePipButton = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('Close PiP'));
  const invertFilterButton = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('Invert'));

  expect(normalizedText(renderer!.root)).toContain('Video filter');

  await ReactTestRenderer.act(() => {
    openPipButton!.props.onPress();
  });
  await ReactTestRenderer.act(() => {
    invertFilterButton!.props.onPress();
  });
  await ReactTestRenderer.act(() => {
    closePipButton!.props.onPress();
  });

  expect(NativeDisplayControl!.openDisplayPip).toHaveBeenCalledWith('1');
  expect(NativeDisplayControl!.setPipWindowFilter).toHaveBeenCalledWith(
    'pip-1',
    'invert',
  );
  expect(NativeDisplayControl!.closeDisplayPip).toHaveBeenCalledWith('pip-1');
});

test('advanced tab localizes Picture in Picture filter metadata', async () => {
  const localizedSnapshot = {
    ...nativeSnapshot,
    pipWindows: [
      {
        ...nativeSnapshot.pipWindows[0],
        filter: 'invert',
      },
    ],
  };
  vi.mocked(NativeDisplayControl!.getSystemLocale).mockReturnValue('ko-KR');
  vi.mocked(NativeDisplayControl!.getSnapshot).mockReturnValueOnce(
    localizedSnapshot,
  );
  vi.mocked(NativeDisplayControl!.refreshSnapshot).mockReturnValueOnce(
    localizedSnapshot,
  );
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const advancedTab = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('고급'));

  await ReactTestRenderer.act(() => {
    advancedTab!.props.onPress();
  });

  const renderedText = normalizedText(renderer!.root);
  expect(renderedText).toContain('480 x 270 / 2 fps / Open / 반전');
  expect(renderedText).not.toContain('Open / invert');
});

test('advanced tab scopes virtual displays to the selected display', async () => {
  const scopedSnapshot = {
    ...nativeSnapshot,
    virtualDisplays: [
      {
        ...nativeSnapshot.virtualDisplays[0],
        targetDisplayID: '2',
        targetIdentityKey: 'C8E8A6A8-2C78-49C5-B509-A3E73E4761BD',
      },
    ],
  };
  vi.mocked(NativeDisplayControl!.getSnapshot).mockReturnValueOnce(
    scopedSnapshot,
  );
  vi.mocked(NativeDisplayControl!.refreshSnapshot).mockReturnValueOnce(
    scopedSnapshot,
  );
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const advancedTab = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('Advanced'));

  await ReactTestRenderer.act(() => {
    advancedTab!.props.onPress();
  });

  expect(normalizedText(renderer!.root)).toContain(
    'No virtual displays created by macDisplayBar.',
  );
  expect(normalizedText(renderer!.root)).not.toContain('Stop mirror');
});

test('advanced tab scopes Picture in Picture windows to the selected display', async () => {
  const scopedSnapshot = {
    ...nativeSnapshot,
    pipWindows: [
      {
        ...nativeSnapshot.pipWindows[0],
        displayID: '2',
      },
    ],
  };
  vi.mocked(NativeDisplayControl!.getSnapshot).mockReturnValueOnce(
    scopedSnapshot,
  );
  vi.mocked(NativeDisplayControl!.refreshSnapshot).mockReturnValueOnce(
    scopedSnapshot,
  );
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const advancedTab = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('Advanced'));

  await ReactTestRenderer.act(() => {
    advancedTab!.props.onPress();
  });

  expect(normalizedText(renderer!.root)).toContain(
    'No PiP windows open for this display.',
  );
  expect(normalizedText(renderer!.root)).not.toContain('Close PiP');
});

test('disables display movement controls when only one display is connected', async () => {
  const singleDisplaySnapshot = {
    ...nativeSnapshot,
    displays: [nativeSnapshot.displays[0]],
  };

  vi.mocked(NativeDisplayControl!.getSnapshot).mockReturnValueOnce(
    singleDisplaySnapshot,
  );
  vi.mocked(NativeDisplayControl!.refreshSnapshot).mockReturnValueOnce(
    singleDisplaySnapshot,
  );

  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const arrangeTab = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('Arrange'));

  await ReactTestRenderer.act(() => {
    arrangeTab!.props.onPress();
  });

  const moveLeft = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .find((node) => normalizedText(node).includes('Left'));

  expect(moveLeft!.props.disabled).toBe(true);
  expect(normalizedText(renderer!.root)).toContain(
    'Display movement is available when two or more displays are connected.',
  );
});

test('extra brightness actions call the native display control', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const advancedTab = renderer!.root
    .findAllByType(Pressable)
    .find((node) => instanceText(node).includes('Advanced'));

  await ReactTestRenderer.act(() => {
    advancedTab!.props.onPress();
  });

  const enableExtraBrightness = renderer!.root
    .findAllByProps({ accessibilityRole: 'button' })
    .filter((node) => normalizedText(node).includes('Enable'))
    .at(-1);

  await ReactTestRenderer.act(() => {
    enableExtraBrightness!.props.onPress();
  });

  expect(NativeDisplayControl!.enableXdrUpscale).toHaveBeenCalledWith('1');
});

test('maps system locale to supported app languages', () => {
  expect(languageFromLocale('ko-KR')).toBe('ko');
  expect(languageFromLocale('en-US')).toBe('en');
});

test('reads app language from native locale', async () => {
  vi.mocked(NativeDisplayControl!.getSystemLocale).mockReturnValue('ko-KR');

  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const renderedText = JSON.stringify(renderer!.toJSON());
  expect(renderedText).toContain('앱 업데이트');
  expect(renderedText).toContain('업데이트 확인');
});

test('checks and reloads a downloaded HotUpdater bundle', async () => {
  hotUpdaterMocks.checkForUpdate.mockResolvedValueOnce({
    fileHash: 'bundle-hash',
    fileUrl: 'https://updates.example.com/bundle.zip',
    id: 'bundle-2',
    message: 'Manual update available',
    shouldForceUpdate: false,
    status: 'UPDATE',
    updateBundle: hotUpdaterMocks.updateBundle,
  });
  hotUpdaterMocks.isUpdateDownloaded.mockReturnValue(true);

  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const checkButton = renderer!.root.findByProps({
    accessibilityLabel: 'Check for updates',
  });

  await ReactTestRenderer.act(async () => {
    await checkButton.props.onPress();
  });

  const reloadButton = renderer!.root.findByProps({
    accessibilityLabel: 'Apply update',
  });

  expect(hotUpdaterMocks.checkForUpdate).toHaveBeenCalledTimes(1);
  expect(hotUpdaterMocks.updateBundle).toHaveBeenCalledTimes(1);
  expect(reloadButton.props.disabled).toBe(false);

  await ReactTestRenderer.act(async () => {
    await reloadButton.props.onPress();
  });

  expect(hotUpdaterMocks.reload).toHaveBeenCalledTimes(1);
});

test('keeps the update action disabled for one minute when no update exists', async () => {
  vi.useFakeTimers();
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const checkButton = renderer!.root.findByProps({
    accessibilityLabel: 'Check for updates',
  });

  await ReactTestRenderer.act(async () => {
    await checkButton.props.onPress();
  });

  const disabledButton = renderer!.root.findByProps({
    accessibilityLabel: 'Up to date',
  });

  expect(disabledButton.props.disabled).toBe(true);

  await ReactTestRenderer.act(async () => {
    vi.advanceTimersByTime(60_000);
  });

  const reenabledButton = renderer!.root.findByProps({
    accessibilityLabel: 'Check for updates',
  });

  expect(reenabledButton.props.disabled).toBe(false);

  await ReactTestRenderer.act(() => {
    renderer!.unmount();
  });
  vi.useRealTimers();
});

function instanceText(node: ReactTestRenderer.ReactTestInstance): string {
  return node.children
    .map((child) => (typeof child === 'string' ? child : instanceText(child)))
    .join(' ');
}

function normalizedText(node: ReactTestRenderer.ReactTestInstance): string {
  return instanceText(node).replace(/\s+/g, ' ').trim();
}
