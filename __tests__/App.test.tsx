/**
 * @format
 */

import React from 'react';
import { ScrollView } from 'react-native';
import ReactTestRenderer from 'react-test-renderer';
import { vi } from 'vitest';

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
    setDisplayRotation: vi.fn(() => nativeSnapshot),
    enableXdrUpscale: vi.fn(() => nativeSnapshot),
    disableXdrUpscale: vi.fn(() => nativeSnapshot),
    softDisconnectDisplay: vi.fn(() => nativeSnapshot),
    reconnectDisplay: vi.fn(() => nativeSnapshot),
    saveFavoriteMode: vi.fn(() => nativeSnapshot),
    removeFavoriteMode: vi.fn(() => nativeSnapshot),
    setDdcControl: vi.fn(() => nativeSnapshot),
    setSettings: vi.fn(() => nativeSnapshot),
  };

  return { default: nativeModule };
});

import App from '../App';

beforeEach(() => {
  hotUpdaterMocks.checkForUpdate.mockReset();
  hotUpdaterMocks.checkForUpdate.mockResolvedValue(null);
  hotUpdaterMocks.isUpdateDownloaded.mockReset();
  hotUpdaterMocks.isUpdateDownloaded.mockReturnValue(false);
  hotUpdaterMocks.reload.mockReset();
  hotUpdaterMocks.reload.mockResolvedValue(undefined);
  hotUpdaterMocks.updateBundle.mockReset();
  hotUpdaterMocks.updateBundle.mockResolvedValue(true);
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
      width: 460,
    }),
  );
});

test('renders BetterDisplay phase-three controls from native snapshot', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer | null = null;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const renderedText = JSON.stringify(renderer!.toJSON());
  expect(renderedText).toContain('Color LCD');
  expect(renderedText).toContain('Resolution and refresh');
  expect(renderedText).toContain('Color and HDR');
  expect(renderedText).toContain('DDC hardware');
  expect(renderedText).toContain('Settings');
  expect(renderedText).toContain('15s refresh');
  expect(renderedText).toContain('HDMI1');
  expect(renderedText).toContain('Advanced');
  expect(renderedText).toContain('Custom:');
  expect(renderedText).toContain('Queue');
  expect(renderedText).toContain('Sync and layout');
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
    accessibilityLabel: 'Check for app update',
  });

  await ReactTestRenderer.act(async () => {
    await checkButton.props.onPress();
  });

  const reloadButton = renderer!.root.findByProps({
    accessibilityLabel: 'Reload downloaded app update',
  });

  expect(hotUpdaterMocks.checkForUpdate).toHaveBeenCalledTimes(1);
  expect(hotUpdaterMocks.updateBundle).toHaveBeenCalledTimes(1);
  expect(reloadButton.props.disabled).toBe(false);

  await ReactTestRenderer.act(async () => {
    await reloadButton.props.onPress();
  });

  expect(hotUpdaterMocks.reload).toHaveBeenCalledTimes(1);
});
