import { StyleSheet, Text, View } from 'react-native';

import type { DisplayControlMode } from '../../specs/NativeDisplayControl';

const font = {
  family: 'Inter',
} as const;

export function ModeSummary({
  mode,
  selected = false,
}: {
  mode: DisplayControlMode;
  selected?: boolean;
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
            selected && styles.selectedMeta,
          ]}
        >
          {mode.isHiDpi ? 'HiDPI' : '1x'}
        </Text>
      </View>
    </View>
  );
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
