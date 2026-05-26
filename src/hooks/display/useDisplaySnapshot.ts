import { useCallback, useEffect, useMemo } from 'react';

import {
  displayControlApi,
  fallbackSnapshot,
} from '../../native/displayControlApi';
import { useIntervalEffect } from '../useIntervalEffect';
import { useOperationState } from '../useOperationState';

export function useDisplaySnapshot() {
  const snapshotState = useOperationState(fallbackSnapshot);
  const { error, run, value } = snapshotState;

  const refreshSnapshot = useCallback(() => {
    run(() => displayControlApi.refreshSnapshot(), {
      resetOnError: true,
    });
  }, [run]);

  useEffect(() => {
    refreshSnapshot();
  }, [refreshSnapshot]);

  const refreshIntervalMilliseconds = useMemo(() => {
    const hasManagedLiveResources =
      value.pipWindows.length > 0 || value.virtualDisplays.length > 0;

    if (!value.settings.autoRefresh && !hasManagedLiveResources) {
      return null;
    }

    if (!value.settings.autoRefresh && hasManagedLiveResources) {
      return 2000;
    }

    return Math.max(value.settings.refreshIntervalSeconds, 5) * 1000;
  }, [
    value.pipWindows.length,
    value.settings.autoRefresh,
    value.settings.refreshIntervalSeconds,
    value.virtualDisplays.length,
  ]);

  useIntervalEffect(refreshSnapshot, refreshIntervalMilliseconds);

  return {
    error,
    refreshSnapshot,
    runSnapshotOperation: run,
    snapshot: value,
  };
}
