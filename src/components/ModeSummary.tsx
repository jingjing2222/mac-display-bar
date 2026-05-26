import { StyleSheet, Text, View } from 'react-native';

import type { DisplayControlMode } from '../../specs/NativeDisplayControl';
import type { TranslationKey } from '../i18n/strings';

const font = {
  family: 'Inter',
} as const;

export function ModeSummary({
  mode,
  selected = false,
  t = defaultT,
}: {
  mode: DisplayControlMode;
  selected?: boolean;
  t?: (key: TranslationKey) => string;
}) {
  return (
    <View style={styles.block}>
      <Text style={[styles.resolution, selected && styles.selectedText]}>
        {mode.width} x {mode.height}
      </Text>
      <View style={styles.metaRow}>
        <Text style={[styles.refresh, selected && styles.selectedMeta]}>
          {Math.round(mode.refreshRate)}Hz
        </Text>
        <View style={[styles.dot, selected && styles.selectedDot]} />
        <Text
          style={[
            styles.scale,
            mode.isHiDpi && styles.hidpiScale,
            mode.requiresOverride === true && styles.installScale,
            selected && styles.selectedMeta,
          ]}
        >
          {modeScaleLabel(mode, t)}
        </Text>
      </View>
    </View>
  );
}

export function modeScaleLabel(
  mode: DisplayControlMode,
  t: (key: TranslationKey) => string = defaultT,
) {
  if (mode.requiresRestart === true) {
    return t('pcRestart');
  }

  if (mode.requiresOverride === true) {
    return t('installTarget');
  }

  return mode.isHiDpi ? 'HiDPI' : '1x';
}

function defaultT(key: TranslationKey) {
  if (key === 'pcRestart') {
    return 'PC Restart';
  }

  if (key === 'installTarget') {
    return 'Install target';
  }

  return key;
}

const styles = StyleSheet.create({
  block: {
    flex: 1,
    justifyContent: 'center',
    minWidth: 0,
  },
  resolution: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 15,
    fontWeight: '700',
    lineHeight: 20,
  },
  metaRow: {
    alignItems: 'center',
    flexDirection: 'row',
    marginTop: 3,
  },
  refresh: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 11,
    fontWeight: '700',
    lineHeight: 14,
  },
  dot: {
    backgroundColor: '#656a76',
    borderRadius: 9999,
    height: 3,
    marginHorizontal: 7,
    width: 3,
  },
  scale: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 11,
    fontWeight: '700',
    lineHeight: 14,
  },
  hidpiScale: {
    color: '#00ca8e',
  },
  installScale: {
    color: '#f2cc60',
  },
  selectedText: {
    color: '#ffffff',
  },
  selectedMeta: {
    color: '#ffffff',
  },
  selectedDot: {
    backgroundColor: 'rgba(255,255,255,0.58)',
  },
});
