import { useCallback, useEffect, useRef, useState } from 'react';

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

const noUpdateCooldownMs = 60_000;

export function useHotUpdate() {
  const [bundle, setBundle] = useState<HotUpdateBundle | null>(null);
  const [message, setMessage] = useState('Manual update check ready');
  const [status, setStatus] = useState<HotUpdateStatus>('idle');
  const cooldownRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const clearCooldown = useCallback(() => {
    if (!cooldownRef.current) {
      return;
    }

    clearTimeout(cooldownRef.current);
    cooldownRef.current = null;
  }, []);

  const startNoUpdateCooldown = useCallback(() => {
    clearCooldown();
    cooldownRef.current = setTimeout(() => {
      cooldownRef.current = null;
      setMessage('Manual update check ready');
      setStatus('idle');
    }, noUpdateCooldownMs);
  }, [clearCooldown]);

  useEffect(() => {
    return clearCooldown;
  }, [clearCooldown]);

  const checkForUpdate = useCallback(async () => {
    clearCooldown();
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
        if (!reportedError) {
          startNoUpdateCooldown();
        }
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
  }, [clearCooldown, startNoUpdateCooldown]);

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
      status !== 'reloading' &&
      status !== 'up-to-date',
    canReload: status === 'ready',
    checkForUpdate,
    message,
    reloadUpdate,
    status,
  };
}
