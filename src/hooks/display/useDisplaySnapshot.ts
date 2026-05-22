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
    if (!value.settings.autoRefresh) {
      return null;
    }

    return Math.max(value.settings.refreshIntervalSeconds, 5) * 1000;
  }, [value.settings.autoRefresh, value.settings.refreshIntervalSeconds]);

  useIntervalEffect(refreshSnapshot, refreshIntervalMilliseconds);

  return {
    error,
    refreshSnapshot,
    runSnapshotOperation: run,
    snapshot: value,
  };
}
