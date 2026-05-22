import { useMemo } from 'react';

import type {
  DisplayControlDisplay,
  DisplayControlSnapshot,
} from '../../../specs/NativeDisplayControl';
import {
  displayControlApi,
  type CustomResolutionDraft,
} from '../../native/displayControlApi';

type RunSnapshotOperation = (operation: () => DisplayControlSnapshot) => void;

export function useDisplayControlActions({
  displayIDs,
  presetName,
  refreshSnapshot,
  runSnapshotOperation,
  syncGroupName,
}: {
  displayIDs: Array<string>;
  presetName: string;
  refreshSnapshot: () => void;
  runSnapshotOperation: RunSnapshotOperation;
  syncGroupName: string;
}) {
  return useMemo(
    () => ({
      refreshSnapshot,
      setSettings: (
        autoRefresh: boolean,
        refreshIntervalSeconds: number,
        showAdvancedMetadata: boolean,
      ) =>
        runSnapshotOperation(() =>
          displayControlApi.setSettings(
            autoRefresh,
            refreshIntervalSeconds,
            showAdvancedMetadata,
          ),
        ),
      setSoftwareDimming: (displayID: string, level: number) =>
        runSnapshotOperation(() =>
          displayControlApi.setSoftwareDimming(displayID, level),
        ),
      setNativeBrightness: (displayID: string, level: number) =>
        runSnapshotOperation(() =>
          displayControlApi.setNativeBrightness(displayID, level),
        ),
      setDisplayMode: (displayID: string, modeID: string) =>
        runSnapshotOperation(() =>
          displayControlApi.setDisplayMode(displayID, modeID),
        ),
      setDisplayOrigin: (displayID: string, x: number, y: number) =>
        runSnapshotOperation(() =>
          displayControlApi.setDisplayOrigin(displayID, x, y),
        ),
      setDdcControl: (displayID: string, controlCode: number, value: number) =>
        runSnapshotOperation(() =>
          displayControlApi.setDdcControl(displayID, controlCode, value),
        ),
      setColorProfile: (displayID: string, profileID: string) =>
        runSnapshotOperation(() =>
          displayControlApi.setColorProfile(displayID, profileID),
        ),
      resetColorProfile: (displayID: string) =>
        runSnapshotOperation(() =>
          displayControlApi.resetColorProfile(displayID),
        ),
      savePreset: () =>
        runSnapshotOperation(() => displayControlApi.savePreset(presetName)),
      applyPreset: (name: string) =>
        runSnapshotOperation(() => displayControlApi.applyPreset(name)),
      deletePreset: (name: string) =>
        runSnapshotOperation(() => displayControlApi.deletePreset(name)),
      saveProtectedLayout: () =>
        runSnapshotOperation(() => displayControlApi.saveProtectedLayout()),
      restoreProtectedLayout: () =>
        runSnapshotOperation(() => displayControlApi.restoreProtectedLayout()),
      clearProtectedLayout: () =>
        runSnapshotOperation(() => displayControlApi.clearProtectedLayout()),
      saveSyncGroup: () =>
        runSnapshotOperation(() =>
          displayControlApi.saveSyncGroup(syncGroupName, displayIDs),
        ),
      applySyncGroup: (groupID: string) =>
        runSnapshotOperation(() => displayControlApi.applySyncGroup(groupID)),
      deleteSyncGroup: (groupID: string) =>
        runSnapshotOperation(() => displayControlApi.deleteSyncGroup(groupID)),
      exportEdid: (displayID: string) =>
        runSnapshotOperation(() => displayControlApi.exportEdid(displayID)),
      addCustomResolution: (
        display: DisplayControlDisplay,
        request: CustomResolutionDraft,
      ) =>
        runSnapshotOperation(() =>
          displayControlApi.addCustomResolution(display, request),
        ),
      removeCustomResolution: (displayID: string, requestID: string) =>
        runSnapshotOperation(() =>
          displayControlApi.removeCustomResolution(displayID, requestID),
        ),
      queueEdidOverride: (displayID: string) =>
        runSnapshotOperation(() =>
          displayControlApi.queueEdidOverride(displayID),
        ),
      clearEdidOverride: (displayID: string) =>
        runSnapshotOperation(() =>
          displayControlApi.clearEdidOverride(displayID),
        ),
      writeOverrideBundle: (displayID: string) =>
        runSnapshotOperation(() =>
          displayControlApi.writeOverrideBundle(displayID),
        ),
      setDisplayRotation: (displayID: string, rotation: number) =>
        runSnapshotOperation(() =>
          displayControlApi.setDisplayRotation(displayID, rotation),
        ),
      enableXdrUpscale: (displayID: string) =>
        runSnapshotOperation(() =>
          displayControlApi.enableXdrUpscale(displayID),
        ),
      disableXdrUpscale: (displayID: string) =>
        runSnapshotOperation(() =>
          displayControlApi.disableXdrUpscale(displayID),
        ),
      softDisconnectDisplay: (displayID: string) =>
        runSnapshotOperation(() =>
          displayControlApi.softDisconnectDisplay(displayID),
        ),
      reconnectDisplay: (displayID: string) =>
        runSnapshotOperation(() =>
          displayControlApi.reconnectDisplay(displayID),
        ),
      saveFavoriteMode: (displayID: string, modeID: string) =>
        runSnapshotOperation(() =>
          displayControlApi.saveFavoriteMode(displayID, modeID),
        ),
      removeFavoriteMode: (displayID: string, modeID: string) =>
        runSnapshotOperation(() =>
          displayControlApi.removeFavoriteMode(displayID, modeID),
        ),
    }),
    [
      displayIDs,
      presetName,
      refreshSnapshot,
      runSnapshotOperation,
      syncGroupName,
    ],
  );
}
