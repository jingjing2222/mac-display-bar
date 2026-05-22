import { useMemo } from 'react';

import { useTextDraft } from '../useTextDraft';
import { useDisplayControlActions } from './useDisplayControlActions';
import { useDisplaySnapshot } from './useDisplaySnapshot';

export function useDisplayControl() {
  const presetName = useTextDraft('Default');
  const syncGroupName = useTextDraft('All displays');
  const { error, refreshSnapshot, runSnapshotOperation, snapshot } =
    useDisplaySnapshot();
  const displayIDs = useMemo(
    () => snapshot.displays.map((display) => display.id),
    [snapshot.displays],
  );
  const actions = useDisplayControlActions({
    displayIDs,
    presetName: presetName.value,
    refreshSnapshot,
    runSnapshotOperation,
    syncGroupName: syncGroupName.value,
  });

  return {
    actions,
    presetName: presetName.value,
    setPresetName: presetName.setValue,
    setSyncGroupName: syncGroupName.setValue,
    snapshot,
    snapshotError: error,
    syncGroupName: syncGroupName.value,
  };
}
