import { Pressable, StyleSheet, Text, View } from 'react-native';

import type { TranslationKey } from '../i18n/strings';
import { useHotUpdate } from '../hooks/hotUpdate/useHotUpdate';
import { Icon } from './Icon';

const font = {
  family: 'Inter',
} as const;

export function TopUpdateHeader({
  isReady,
  t,
}: {
  isReady: boolean;
  t: (key: TranslationKey) => string;
}) {
  const { canCheck, canReload, checkForUpdate, reloadUpdate, status } =
    useHotUpdate();

  return (
    <View style={styles.header}>
      <View style={styles.titleBlock}>
        <View style={styles.appRow}>
          <View style={styles.appIcon}>
            <Icon color="#ffffff" name="display" size={17} />
          </View>
          <View style={styles.appTextBlock}>
            <Text style={styles.appName}>{t('appName')}</Text>
            <View style={styles.statusRow}>
              <View
                style={[
                  styles.statusDot,
                  isReady ? styles.dotReady : styles.dotWarn,
                ]}
              />
              <Text style={styles.statusText}>
                {isReady ? t('appReady') : t('appUnavailable')}
              </Text>
              <Text style={styles.updateTitle}>{t('updateTitle')}</Text>
              <Text style={styles.updateStatus}>{updateLabel(status, t)}</Text>
            </View>
          </View>
        </View>
      </View>

      <View style={styles.actions}>
        <Pressable
          accessibilityLabel={t('updateCheck')}
          accessibilityRole="button"
          disabled={!canCheck}
          onPress={checkForUpdate}
          style={({ pressed }) => [
            styles.button,
            pressed && canCheck && styles.buttonPressed,
            !canCheck && styles.buttonDisabled,
          ]}
        >
          <Icon color="#ffffff" name="refresh" size={13} />
          <Text style={styles.buttonText}>{checkLabel(status, t)}</Text>
        </Pressable>
        <Pressable
          accessibilityLabel={t('updateApply')}
          accessibilityRole="button"
          disabled={!canReload}
          onPress={reloadUpdate}
          style={({ pressed }) => [
            styles.button,
            canReload && styles.applyButton,
            pressed && canReload && styles.buttonPressed,
            !canReload && styles.buttonDisabled,
          ]}
        >
          <Icon color="#ffffff" name="download" size={13} />
          <Text style={styles.buttonText}>{t('updateApply')}</Text>
        </Pressable>
      </View>
    </View>
  );
}

function checkLabel(status: string, t: (key: TranslationKey) => string) {
  if (status === 'checking') {
    return t('updateChecking');
  }

  if (status === 'downloading') {
    return t('updateDownloading');
  }

  return t('updateCheck');
}

function updateLabel(status: string, t: (key: TranslationKey) => string) {
  switch (status) {
    case 'up-to-date':
      return t('updateCurrent');
    case 'ready':
      return t('updateReady');
    case 'checking':
      return t('updateChecking');
    case 'downloading':
      return t('updateDownloading');
    default:
      return t('updateManual');
  }
}

const styles = StyleSheet.create({
  header: {
    backgroundColor: '#000000',
    borderBottomColor: 'rgba(178,182,189,0.1)',
    borderBottomWidth: 1,
    flexDirection: 'row',
    paddingHorizontal: 16,
    paddingVertical: 14,
  },
  titleBlock: {
    flex: 1,
    minWidth: 0,
    paddingRight: 12,
  },
  appRow: {
    alignItems: 'center',
    flexDirection: 'row',
  },
  appIcon: {
    alignItems: 'center',
    backgroundColor: '#2b89ff',
    borderRadius: 8,
    height: 34,
    justifyContent: 'center',
    marginRight: 10,
    width: 34,
  },
  appTextBlock: {
    flex: 1,
    minWidth: 0,
  },
  appName: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 18,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 24,
  },
  statusRow: {
    alignItems: 'center',
    flexDirection: 'row',
    marginTop: 5,
  },
  statusDot: {
    borderRadius: 9999,
    height: 7,
    marginRight: 6,
    width: 7,
  },
  dotReady: {
    backgroundColor: '#00ca8e',
  },
  dotWarn: {
    backgroundColor: '#ffcf25',
  },
  statusText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    lineHeight: 15,
    marginRight: 8,
  },
  updateStatus: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '500',
    lineHeight: 15,
  },
  updateTitle: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    lineHeight: 15,
    marginRight: 6,
  },
  actions: {
    flexDirection: 'row',
  },
  button: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    flexDirection: 'row',
    justifyContent: 'center',
    marginLeft: 8,
    minHeight: 36,
    minWidth: 92,
    paddingHorizontal: 10,
  },
  applyButton: {
    backgroundColor: '#2b89ff',
    borderColor: '#2b89ff',
  },
  buttonPressed: {
    backgroundColor: '#3b3d45',
  },
  buttonDisabled: {
    opacity: 0.45,
  },
  buttonText: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 15,
    marginLeft: 6,
  },
});
