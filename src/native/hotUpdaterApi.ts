import { HotUpdater } from '@hot-updater/react-native';

const updateStrategy = 'fingerprint' as const;

export type HotUpdateBundle = NonNullable<
  Awaited<ReturnType<typeof HotUpdater.checkForUpdate>>
>;

export const hotUpdaterApi = {
  checkForUpdate(onError: (error: Error) => void) {
    return HotUpdater.checkForUpdate({
      onError,
      updateStrategy,
    });
  },
  isUpdateDownloaded() {
    return HotUpdater.isUpdateDownloaded();
  },
  reload() {
    return HotUpdater.reload();
  },
};
