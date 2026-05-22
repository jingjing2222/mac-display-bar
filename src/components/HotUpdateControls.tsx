import { Pressable, StyleSheet, Text, View } from 'react-native';

import { useHotUpdate } from '../hooks/hotUpdate/useHotUpdate';

const font = {
  family: 'Inter',
} as const;

export function HotUpdateControls() {
  const {
    bundle,
    canCheck,
    canReload,
    checkForUpdate,
    message,
    reloadUpdate,
    status,
  } = useHotUpdate();
  const checkButtonLabel =
    status === 'downloading'
      ? 'Downloading'
      : status === 'checking'
        ? 'Checking'
        : 'Check';

  return (
    <View style={styles.block}>
      <View style={styles.header}>
        <Text style={styles.label}>Hot update</Text>
        <Text style={styles.value}>{statusLabel(status)}</Text>
      </View>

      <View style={styles.actions}>
        <Pressable
          accessibilityLabel="Check for app update"
          accessibilityRole="button"
          disabled={!canCheck}
          onPress={checkForUpdate}
          style={({ pressed }) => [
            styles.button,
            pressed && canCheck && styles.buttonPressed,
            !canCheck && styles.buttonDisabled,
          ]}
        >
          <Text style={[styles.buttonText, !canCheck && styles.disabledText]}>
            {checkButtonLabel}
          </Text>
        </Pressable>

        <Pressable
          accessibilityLabel="Reload downloaded app update"
          accessibilityRole="button"
          disabled={!canReload}
          onPress={reloadUpdate}
          style={({ pressed }) => [
            styles.button,
            styles.reloadButton,
            canReload && styles.reloadButtonReady,
            pressed && canReload && styles.buttonPressed,
            !canReload && styles.buttonDisabled,
          ]}
        >
          <Text style={[styles.buttonText, !canReload && styles.disabledText]}>
            Update
          </Text>
        </Pressable>
      </View>

      <Text style={styles.message}>
        {bundle ? `${bundle.id} / ${message}` : message}
      </Text>
    </View>
  );
}

function statusLabel(status: string) {
  switch (status) {
    case 'checking':
      return 'Checking';
    case 'downloading':
      return 'Downloading';
    case 'ready':
      return 'Ready';
    case 'reloading':
      return 'Reloading';
    case 'up-to-date':
      return 'Current';
    case 'error':
      return 'Error';
    default:
      return 'Manual';
  }
}

const styles = StyleSheet.create({
  block: {
    borderBottomColor: 'rgba(178,182,189,0.1)',
    borderBottomWidth: 1,
    paddingVertical: 16,
  },
  header: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  label: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    letterSpacing: 0.2,
    lineHeight: 18,
  },
  value: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    letterSpacing: 0.2,
    lineHeight: 18,
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
    flex: 1,
    justifyContent: 'center',
    marginRight: 8,
    minHeight: 40,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  reloadButton: {
    marginRight: 0,
  },
  reloadButtonReady: {
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
    fontSize: 14,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 18,
  },
  disabledText: {
    color: '#b2b6bd',
  },
  message: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '500',
    letterSpacing: 0,
    lineHeight: 16,
    marginTop: 8,
  },
});
