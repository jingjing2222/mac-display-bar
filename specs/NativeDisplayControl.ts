import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export type DisplayControlMode = {
  id: string;
  width: number;
  height: number;
  refreshRate: number;
  isHiDpi: boolean;
  isCurrent: boolean;
  isFavorite: boolean;
  requiresOverride?: boolean;
};

export type DisplayControlDdcState = {
  brightness: number;
  contrast: number;
  volume: number;
  inputSource: number;
  readStatus: string;
  lastError: string;
};

export type DisplayControlFrame = {
  x: number;
  y: number;
  width: number;
  height: number;
};

export type DisplayControlIdentity = {
  uuid: string;
  vendorID: number;
  modelID: number;
  serialNumber: number;
  productName: string;
  transport: string;
};

export type DisplayControlColorProfile = {
  id: string;
  name: string;
  path: string;
  isCurrent: boolean;
  isFactory: boolean;
};

export type DisplayControlHdrState = {
  isSupported: boolean;
  isActive: boolean;
  currentHeadroom: number;
  potentialHeadroom: number;
  referenceHeadroom: number;
  xdrPreset: string;
};

export type DisplayControlCustomResolution = {
  id: string;
  width: number;
  height: number;
  refreshRate: number;
  isHiDpi: boolean;
  status: string;
};

export type DisplayControlAdvancedState = {
  supportsEdidExport: boolean;
  edidBytes: number;
  edidExportPath: string;
  edidOverridePath: string;
  edidOverrideStatus: string;
  overrideBundlePath: string;
  overrideBundleStatus: string;
  rotationRequest: number;
  rotationStatus: string;
  softConnectionState: string;
  xdrUpscaleState: string;
  lastOperation: string;
  lastOperationAt: string;
  customResolutions: Array<DisplayControlCustomResolution>;
};

export type DisplayControlDisplay = {
  id: string;
  name: string;
  connectionType: string;
  isPrimary: boolean;
  isBuiltin: boolean;
  isOnline: boolean;
  isActive: boolean;
  isAsleep: boolean;
  isMirrored: boolean;
  isHardwareMirrored: boolean;
  mirrorsDisplayID: string;
  identity: DisplayControlIdentity;
  rotation: number;
  frame: DisplayControlFrame;
  currentMode: DisplayControlMode;
  availableModes: Array<DisplayControlMode>;
  modeStatus: string;
  modeError: string;
  nativeBrightness: number;
  brightnessControl: string;
  brightnessError: string;
  softwareDimming: number;
  supportsBrightness: boolean;
  supportsSoftwareDimming: boolean;
  supportsDdc: boolean;
  ddc: DisplayControlDdcState;
  supportsHdr: boolean;
  hdr: DisplayControlHdrState;
  colorProfileStatus: string;
  colorProfileError: string;
  colorProfiles: Array<DisplayControlColorProfile>;
  advanced: DisplayControlAdvancedState;
};

export type DisplayControlPreset = {
  name: string;
  createdAt: string;
  displayCount: number;
};

export type DisplayControlSyncGroup = {
  id: string;
  name: string;
  displayIDs: Array<string>;
  brightnessSync: boolean;
  scaleSync: boolean;
  layoutProtection: boolean;
};

export type DisplayControlSettings = {
  autoRefresh: boolean;
  refreshIntervalSeconds: number;
  showAdvancedMetadata: boolean;
};

export type DisplayControlSnapshot = {
  moduleStatus: string;
  generatedAt: string;
  platform: string;
  architecture: string;
  machineModel: string;
  isAppleSilicon: boolean;
  displayTopologyRevision: number;
  displayTopologyStatus: string;
  displayTopologyChangedAt: string;
  displays: Array<DisplayControlDisplay>;
  presets: Array<DisplayControlPreset>;
  syncGroups: Array<DisplayControlSyncGroup>;
  layoutProtectionEnabled: boolean;
  layoutProtectionStatus: string;
  layoutDriftCount: number;
  settings: DisplayControlSettings;
};

export interface Spec extends TurboModule {
  getSystemLocale(): string;
  getSnapshot(): DisplayControlSnapshot;
  refreshSnapshot(): DisplayControlSnapshot;
  setNativeBrightness(displayID: string, level: number): DisplayControlSnapshot;
  setSoftwareDimming(displayID: string, level: number): DisplayControlSnapshot;
  setDisplayMode(displayID: string, modeID: string): DisplayControlSnapshot;
  setDisplayOrigin(
    displayID: string,
    x: number,
    y: number,
  ): DisplayControlSnapshot;
  savePreset(name: string): DisplayControlSnapshot;
  applyPreset(name: string): DisplayControlSnapshot;
  deletePreset(name: string): DisplayControlSnapshot;
  setColorProfile(displayID: string, profileID: string): DisplayControlSnapshot;
  resetColorProfile(displayID: string): DisplayControlSnapshot;
  saveProtectedLayout(): DisplayControlSnapshot;
  restoreProtectedLayout(): DisplayControlSnapshot;
  clearProtectedLayout(): DisplayControlSnapshot;
  saveSyncGroup(
    name: string,
    displayIDs: Array<string>,
    brightnessSync: boolean,
    scaleSync: boolean,
    layoutProtection: boolean,
  ): DisplayControlSnapshot;
  applySyncGroup(groupID: string): DisplayControlSnapshot;
  deleteSyncGroup(groupID: string): DisplayControlSnapshot;
  exportEdid(displayID: string): DisplayControlSnapshot;
  addCustomResolution(
    displayID: string,
    width: number,
    height: number,
    refreshRate: number,
    isHiDpi: boolean,
  ): DisplayControlSnapshot;
  removeCustomResolution(
    displayID: string,
    requestID: string,
  ): DisplayControlSnapshot;
  queueEdidOverride(displayID: string): DisplayControlSnapshot;
  clearEdidOverride(displayID: string): DisplayControlSnapshot;
  writeOverrideBundle(displayID: string): DisplayControlSnapshot;
  setDisplayRotation(
    displayID: string,
    rotation: number,
  ): DisplayControlSnapshot;
  enableXdrUpscale(displayID: string): DisplayControlSnapshot;
  disableXdrUpscale(displayID: string): DisplayControlSnapshot;
  softDisconnectDisplay(displayID: string): DisplayControlSnapshot;
  reconnectDisplay(displayID: string): DisplayControlSnapshot;
  saveFavoriteMode(displayID: string, modeID: string): DisplayControlSnapshot;
  removeFavoriteMode(displayID: string, modeID: string): DisplayControlSnapshot;
  setDdcControl(
    displayID: string,
    controlCode: number,
    value: number,
  ): DisplayControlSnapshot;
  setSettings(
    autoRefresh: boolean,
    refreshIntervalSeconds: number,
    showAdvancedMetadata: boolean,
  ): DisplayControlSnapshot;
}

export default TurboModuleRegistry.get<Spec>('NativeDisplayControl');
