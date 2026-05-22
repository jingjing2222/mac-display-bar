import { useCallback, useState } from 'react';

import {
  hotUpdaterApi,
  type HotUpdateBundle,
} from '../../native/hotUpdaterApi';

type HotUpdateStatus =
  | 'idle'
  | 'checking'
  | 'up-to-date'
  | 'downloading'
  | 'ready'
  | 'reloading'
  | 'error';

const messageFromError = (error: unknown) =>
  error instanceof Error ? error.message : 'Unknown error';

const messageFromBundle = (bundle: HotUpdateBundle) =>
  bundle.message?.trim() || `Bundle ${bundle.id}`;

export function useHotUpdate() {
  const [bundle, setBundle] = useState<HotUpdateBundle | null>(null);
  const [message, setMessage] = useState('Manual update check ready');
  const [status, setStatus] = useState<HotUpdateStatus>('idle');

  const checkForUpdate = useCallback(async () => {
    setBundle(null);
    setMessage('Checking for update...');
    setStatus('checking');

    let reportedError: string | null = null;

    try {
      const updateBundle = await hotUpdaterApi.checkForUpdate((error) => {
        reportedError = error.message;
      });

      if (!updateBundle) {
        setMessage(reportedError ?? 'No update bundle found');
        setStatus(reportedError ? 'error' : 'up-to-date');
        return;
      }

      setBundle(updateBundle);
      setMessage(messageFromBundle(updateBundle));
      setStatus('downloading');

      const didUpdate = await updateBundle.updateBundle();
      const didDownload = hotUpdaterApi.isUpdateDownloaded();

      if (didUpdate || didDownload) {
        setMessage(`${messageFromBundle(updateBundle)} ready`);
        setStatus('ready');
        return;
      }

      setMessage('Update bundle download did not complete');
      setStatus('error');
    } catch (error) {
      setMessage(messageFromError(error));
      setStatus('error');
    }
  }, []);

  const reloadUpdate = useCallback(async () => {
    if (status !== 'ready') {
      return;
    }

    setStatus('reloading');
    setMessage('Reloading update bundle...');

    try {
      await hotUpdaterApi.reload();
    } catch (error) {
      setMessage(messageFromError(error));
      setStatus('error');
    }
  }, [status]);

  return {
    bundle,
    canCheck:
      status !== 'checking' &&
      status !== 'downloading' &&
      status !== 'reloading',
    canReload: status === 'ready',
    checkForUpdate,
    message,
    reloadUpdate,
    status,
  };
}
