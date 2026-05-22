import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import type {
  DisplayControlDisplay,
  DisplayControlMode,
} from '../../specs/NativeDisplayControl';
import type { TranslationKey } from '../i18n/strings';
import { Icon } from './Icon';

const font = {
  family: 'Inter',
} as const;

export function ResolutionPicker({
  display,
  onFavorite,
  onRemoveFavorite,
  onSelect,
  t,
}: {
  display: DisplayControlDisplay;
  onFavorite: (modeID: string) => void;
  onRemoveFavorite: (modeID: string) => void;
  onSelect: (modeID: string) => void;
  t: (key: TranslationKey) => string;
}) {
  const favorites = display.availableModes.filter((mode) => mode.isFavorite);
  const modes = favorites.length > 0 ? favorites : display.availableModes;

  return (
    <View style={styles.block}>
      <View style={styles.header}>
        <View style={styles.labelRow}>
          <Icon color="#b2b6bd" name="display" size={14} />
          <Text style={styles.label}>{t('resolution')}</Text>
        </View>
        <Text style={styles.value}>
          {Math.round(display.currentMode.refreshRate)}Hz
        </Text>
      </View>
      <View style={styles.current}>
        <Text style={styles.currentLabel}>{t('currentMode')}</Text>
        <Text style={styles.currentValue}>
          {modeLabel(display.currentMode)}
        </Text>
      </View>
      {modes.length > 0 ? (
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          <View style={styles.modeRow}>
            {modes.map((mode) => (
              <View key={mode.id} style={styles.modeItem}>
                <Pressable
                  accessibilityRole="button"
                  onPress={() => onSelect(mode.id)}
                  style={({ pressed }) => [
                    styles.modeButton,
                    mode.isCurrent && styles.modeSelected,
                    pressed && styles.modePressed,
                  ]}
                >
                  <Text
                    style={[
                      styles.modeText,
                      mode.isCurrent && styles.modeTextSelected,
                    ]}
                  >
                    {modeLabel(mode)}
                  </Text>
                </Pressable>
                <Pressable
                  accessibilityRole="button"
                  onPress={() =>
                    mode.isFavorite
                      ? onRemoveFavorite(mode.id)
                      : onFavorite(mode.id)
                  }
                  style={({ pressed }) => [
                    styles.favorite,
                    mode.isFavorite && styles.favoriteSelected,
                    pressed && styles.modePressed,
                  ]}
                >
                  <Text
                    style={[
                      styles.favoriteText,
                      mode.isFavorite && styles.modeTextSelected,
                    ]}
                  >
                    {mode.isFavorite ? t('savedFavorite') : t('saveFavorite')}
                  </Text>
                </Pressable>
              </View>
            ))}
          </View>
        </ScrollView>
      ) : null}
    </View>
  );
}

export function modeLabel(mode: DisplayControlMode) {
  const scale = mode.isHiDpi ? 'HiDPI' : '1x';

  return `${mode.width} x ${mode.height} / ${Math.round(mode.refreshRate)}Hz / ${scale}`;
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
    lineHeight: 18,
  },
  current: {
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    marginBottom: 10,
    padding: 10,
  },
  currentLabel: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 11,
    fontWeight: '600',
    lineHeight: 14,
    marginBottom: 4,
    textTransform: 'uppercase',
  },
  currentValue: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 15,
    fontWeight: '600',
    lineHeight: 20,
  },
  modeRow: {
    flexDirection: 'row',
    paddingRight: 8,
  },
  modeItem: {
    marginRight: 8,
    width: 150,
  },
  modeButton: {
    alignItems: 'flex-start',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    justifyContent: 'center',
    minHeight: 48,
    paddingHorizontal: 10,
    paddingVertical: 8,
  },
  modeSelected: {
    backgroundColor: '#2b89ff',
    borderColor: '#2b89ff',
  },
  modePressed: {
    backgroundColor: '#3b3d45',
  },
  modeText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    lineHeight: 16,
  },
  modeTextSelected: {
    color: '#ffffff',
  },
  favorite: {
    alignItems: 'center',
    backgroundColor: '#15181e',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    justifyContent: 'center',
    marginTop: 6,
    minHeight: 30,
  },
  favoriteSelected: {
    backgroundColor: '#00ca8e',
    borderColor: '#00ca8e',
  },
  favoriteText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    lineHeight: 15,
  },
});
