import type { GestureResponderEvent } from 'react-native';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Icon } from './Icon';

const font = {
  family: 'Inter',
} as const;

const sliderMetrics = {
  trackWidth: 270,
} as const;

export function ControlSlider({
  label,
  onChange,
  presets,
  value,
}: {
  label: string;
  onChange: (value: number) => void;
  presets: Array<number>;
  value: number;
}) {
  const clampedValue = Math.min(Math.max(value, 0), 1);
  const fillWidth = Math.round(clampedValue * sliderMetrics.trackWidth);

  const handlePress = (event: GestureResponderEvent) => {
    onChange(
      Math.min(
        Math.max(event.nativeEvent.locationX / sliderMetrics.trackWidth, 0),
        1,
      ),
    );
  };

  return (
    <View style={styles.block}>
      <View style={styles.header}>
        <View style={styles.labelRow}>
          <Icon color="#b2b6bd" name="sliders" size={14} />
          <Text style={styles.label}>{label}</Text>
        </View>
        <Text style={styles.value}>{Math.round(clampedValue * 100)}%</Text>
      </View>
      <Pressable
        accessibilityRole="adjustable"
        onPress={handlePress}
        style={styles.track}
      >
        <View style={[styles.fill, { width: fillWidth }]} />
        <View style={[styles.thumb, { left: Math.max(fillWidth - 7, 0) }]} />
      </Pressable>
      <View style={styles.presets}>
        {presets.map((preset) => {
          const selected = Math.abs(clampedValue - preset) < 0.025;

          return (
            <Pressable
              accessibilityRole="button"
              key={preset}
              onPress={() => onChange(preset)}
              style={({ pressed }) => [
                styles.preset,
                selected && styles.presetSelected,
                pressed && styles.presetPressed,
              ]}
            >
              <Text
                style={[
                  styles.presetText,
                  selected && styles.presetTextSelected,
                ]}
              >
                {Math.round(preset * 100)}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  block: {
    backgroundColor: '#15181e',
    borderColor: 'rgba(178,182,189,0.1)',
    borderRadius: 8,
    borderWidth: 1,
    marginBottom: 10,
    padding: 12,
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
    marginLeft: 6,
  },
  labelRow: {
    alignItems: 'center',
    flexDirection: 'row',
  },
  value: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 18,
  },
  track: {
    backgroundColor: '#252830',
    borderRadius: 9999,
    height: 14,
    justifyContent: 'center',
    width: sliderMetrics.trackWidth,
  },
  fill: {
    backgroundColor: '#2b89ff',
    borderRadius: 9999,
    height: 14,
  },
  thumb: {
    backgroundColor: '#ffffff',
    borderRadius: 9999,
    height: 14,
    position: 'absolute',
    width: 14,
  },
  presets: {
    flexDirection: 'row',
    marginTop: 10,
  },
  preset: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 9999,
    borderWidth: 1,
    justifyContent: 'center',
    marginRight: 8,
    minHeight: 28,
    minWidth: 48,
  },
  presetSelected: {
    backgroundColor: '#2b89ff',
    borderColor: '#2b89ff',
  },
  presetPressed: {
    backgroundColor: '#3b3d45',
  },
  presetText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 15,
  },
  presetTextSelected: {
    color: '#ffffff',
  },
});
