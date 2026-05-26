import NativeDisplayControl, {
  type DisplayControlDisplay,
  type DisplayControlSnapshot,
} from '../../specs/NativeDisplayControl';

export const fallbackSnapshot: DisplayControlSnapshot = {
  moduleStatus: 'unavailable',
  generatedAt: '',
  platform: 'macOS',
  architecture: 'unknown',
  machineModel: 'unknown',
  isAppleSilicon: false,
  displayTopologyRevision: 0,
  displayTopologyStatus: 'Unknown',
  displayTopologyChangedAt: '',
  displays: [],
  virtualDisplays: [],
  pipWindows: [],
  presets: [],
  syncGroups: [],
  layoutProtectionEnabled: false,
  layoutProtectionStatus: 'Unprotected',
  layoutDriftCount: 0,
  settings: {
    autoRefresh: false,
    refreshIntervalSeconds: 15,
    showAdvancedMetadata: true,
  },
};

export type CustomResolutionDraft = {
  width: number;
  height: number;
  refreshRate: number;
  isHiDpi: boolean;
};

export type PanelResolutionDraft = {
  width: number;
  height: number;
};

const snapshotOrFallback = (
  snapshot: DisplayControlSnapshot | null | undefined,
) => {
  if (snapshot == null) {
    return fallbackSnapshot;
  }

  return {
    ...fallbackSnapshot,
    ...snapshot,
    displays: snapshot.displays ?? [],
    virtualDisplays: snapshot.virtualDisplays ?? [],
    pipWindows: snapshot.pipWindows ?? [],
    presets: snapshot.presets ?? [],
    syncGroups: snapshot.syncGroups ?? [],
    settings: {
      ...fallbackSnapshot.settings,
      ...snapshot.settings,
    },
  };
};

export const displayControlApi = {
  getSnapshot() {
    return snapshotOrFallback(NativeDisplayControl?.getSnapshot());
  },
  refreshSnapshot() {
    return snapshotOrFallback(
      NativeDisplayControl?.refreshSnapshot() ??
        NativeDisplayControl?.getSnapshot(),
    );
  },
  setSettings(
    autoRefresh: boolean,
    refreshIntervalSeconds: number,
    showAdvancedMetadata: boolean,
  ) {
    return snapshotOrFallback(
      NativeDisplayControl?.setSettings(
        autoRefresh,
        refreshIntervalSeconds,
        showAdvancedMetadata,
      ),
    );
  },
  setSoftwareDimming(displayID: string, level: number) {
    return snapshotOrFallback(
      NativeDisplayControl?.setSoftwareDimming(displayID, level),
    );
  },
  setNativeBrightness(displayID: string, level: number) {
    return snapshotOrFallback(
      NativeDisplayControl?.setNativeBrightness(displayID, level),
    );
  },
  setDisplayMode(displayID: string, modeID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.setDisplayMode(displayID, modeID),
    );
  },
  setDisplayOrigin(displayID: string, x: number, y: number) {
    return snapshotOrFallback(
      NativeDisplayControl?.setDisplayOrigin(displayID, x, y),
    );
  },
  setDdcControl(displayID: string, controlCode: number, value: number) {
    return snapshotOrFallback(
      NativeDisplayControl?.setDdcControl(displayID, controlCode, value),
    );
  },
  setColorProfile(displayID: string, profileID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.setColorProfile(displayID, profileID),
    );
  },
  resetColorProfile(displayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.resetColorProfile(displayID),
    );
  },
  savePreset(name: string) {
    return snapshotOrFallback(NativeDisplayControl?.savePreset(name));
  },
  applyPreset(name: string) {
    return snapshotOrFallback(NativeDisplayControl?.applyPreset(name));
  },
  deletePreset(name: string) {
    return snapshotOrFallback(NativeDisplayControl?.deletePreset(name));
  },
  saveProtectedLayout() {
    return snapshotOrFallback(NativeDisplayControl?.saveProtectedLayout());
  },
  restoreProtectedLayout() {
    return snapshotOrFallback(NativeDisplayControl?.restoreProtectedLayout());
  },
  clearProtectedLayout() {
    return snapshotOrFallback(NativeDisplayControl?.clearProtectedLayout());
  },
  saveSyncGroup(name: string, displayIDs: Array<string>) {
    return snapshotOrFallback(
      NativeDisplayControl?.saveSyncGroup(name, displayIDs, true, true, true),
    );
  },
  applySyncGroup(groupID: string) {
    return snapshotOrFallback(NativeDisplayControl?.applySyncGroup(groupID));
  },
  deleteSyncGroup(groupID: string) {
    return snapshotOrFallback(NativeDisplayControl?.deleteSyncGroup(groupID));
  },
  exportEdid(displayID: string) {
    return snapshotOrFallback(NativeDisplayControl?.exportEdid(displayID));
  },
  addCustomResolution(
    display: DisplayControlDisplay,
    request: CustomResolutionDraft,
  ) {
    return snapshotOrFallback(
      NativeDisplayControl?.addCustomResolution(
        display.id,
        request.width,
        request.height,
        request.refreshRate,
        request.isHiDpi,
      ),
    );
  },
  removeCustomResolution(displayID: string, requestID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.removeCustomResolution(displayID, requestID),
    );
  },
  queueEdidOverride(displayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.queueEdidOverride(displayID),
    );
  },
  clearEdidOverride(displayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.clearEdidOverride(displayID),
    );
  },
  writeOverrideBundle(displayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.writeOverrideBundle(displayID),
    );
  },
  installDisplayOverride(displayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.installDisplayOverride(displayID),
    );
  },
  removeDisplayOverride(displayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.removeDisplayOverride(displayID),
    );
  },
  reinitializeDisplay(displayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.reinitializeDisplay(displayID),
    );
  },
  setNativePanelResolutionOverride(
    displayID: string,
    request: PanelResolutionDraft,
  ) {
    return snapshotOrFallback(
      NativeDisplayControl?.setNativePanelResolutionOverride(
        displayID,
        request.width,
        request.height,
      ),
    );
  },
  clearNativePanelResolutionOverride(displayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.clearNativePanelResolutionOverride(displayID),
    );
  },
  setFlexibleScalingEnabled(displayID: string, enabled: boolean) {
    return snapshotOrFallback(
      NativeDisplayControl?.setFlexibleScalingEnabled(displayID, enabled),
    );
  },
  setDisplayRotation(displayID: string, rotation: number) {
    return snapshotOrFallback(
      NativeDisplayControl?.setDisplayRotation(displayID, rotation),
    );
  },
  enableXdrUpscale(displayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.enableXdrUpscale(displayID),
    );
  },
  disableXdrUpscale(displayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.disableXdrUpscale(displayID),
    );
  },
  softDisconnectDisplay(displayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.softDisconnectDisplay(displayID),
    );
  },
  reconnectDisplay(displayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.reconnectDisplay(displayID),
    );
  },
  createVirtualDisplay(
    targetDisplayID: string,
    width: number,
    height: number,
    refreshRate: number,
    isHiDpi: boolean,
  ) {
    return snapshotOrFallback(
      NativeDisplayControl?.createVirtualDisplay(
        targetDisplayID,
        width,
        height,
        refreshRate,
        isHiDpi,
      ),
    );
  },
  removeVirtualDisplay(virtualDisplayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.removeVirtualDisplay(virtualDisplayID),
    );
  },
  mirrorVirtualDisplayToTarget(virtualDisplayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.mirrorVirtualDisplayToTarget(virtualDisplayID),
    );
  },
  stopVirtualDisplayMirroring(virtualDisplayID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.stopVirtualDisplayMirroring(virtualDisplayID),
    );
  },
  openDisplayPip(displayID: string) {
    return snapshotOrFallback(NativeDisplayControl?.openDisplayPip(displayID));
  },
  closeDisplayPip(pipWindowID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.closeDisplayPip(pipWindowID),
    );
  },
  setPipWindowFilter(pipWindowID: string, filter: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.setPipWindowFilter(pipWindowID, filter),
    );
  },
  saveFavoriteMode(displayID: string, modeID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.saveFavoriteMode(displayID, modeID),
    );
  },
  removeFavoriteMode(displayID: string, modeID: string) {
    return snapshotOrFallback(
      NativeDisplayControl?.removeFavoriteMode(displayID, modeID),
    );
  },
};
