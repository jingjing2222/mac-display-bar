import { useMemo, useState } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

import type { DisplayControlMode } from '../../specs/NativeDisplayControl';
import type { TranslationKey } from '../i18n/strings';
import { Icon } from './Icon';
import { ModeSummary } from './ModeSummary';
import { StableLegendList } from './StableLegendList';

const font = {
  family: 'Inter',
} as const;

export function ResolutionModeOverlay({
  modes,
  onClose,
  onFavorite,
  onRemoveFavorite,
  onSelect,
  t,
}: {
  modes: Array<DisplayControlMode>;
  onClose: () => void;
  onFavorite: (modeID: string) => void;
  onRemoveFavorite: (modeID: string) => void;
  onSelect: (modeID: string) => void;
  t: (key: TranslationKey) => string;
}) {
  const [query, setQuery] = useState('');
  const [filters, setFilters] = useState({
    current: false,
    favorites: false,
    hidpi: false,
    standardScale: false,
  });
  const filteredModes = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase();
    const scaleFilterEnabled = filters.hidpi || filters.standardScale;

    return modes.filter((mode) => {
      const matchesQuery =
        !normalizedQuery ||
        `${mode.width} ${mode.height} ${Math.round(mode.refreshRate)} ${mode.isHiDpi ? 'hidpi' : '1x'}`
          .toLowerCase()
          .includes(normalizedQuery);
      const matchesScale =
        !scaleFilterEnabled ||
        (filters.hidpi && mode.isHiDpi) ||
        (filters.standardScale && !mode.isHiDpi);
      const matchesFavorite = !filters.favorites || mode.isFavorite;
      const matchesCurrent = !filters.current || mode.isCurrent;

      return matchesQuery && matchesScale && matchesFavorite && matchesCurrent;
    });
  }, [filters, modes, query]);

  const toggleFilter = (key: keyof typeof filters) => {
    setFilters((value) => ({ ...value, [key]: !value[key] }));
  };

  return (
    <View style={styles.root}>
      <Pressable style={styles.backdrop} onPress={onClose} />
      <View style={styles.sheet}>
        <View style={styles.header}>
          <View>
            <Text style={styles.title}>{t('chooseResolution')}</Text>
            <Text style={styles.meta}>
              {filteredModes.length} {t('modesAvailable')}
            </Text>
          </View>
          <Pressable
            accessibilityRole="button"
            onPress={onClose}
            style={({ pressed }) => [
              styles.closeButton,
              pressed && styles.closeButtonPressed,
            ]}
          >
            <Icon color="#b2b6bd" name="chevronDown" size={17} />
          </Pressable>
        </View>
        <View style={styles.searchBox}>
          <Icon color="#656a76" name="display" size={14} />
          <TextInput
            onChangeText={setQuery}
            placeholder={t('searchResolution')}
            placeholderTextColor="#656a76"
            style={styles.searchInput}
            value={query}
          />
        </View>
        <View style={styles.filterRow}>
          <FilterToggle
            active={filters.hidpi}
            label={t('filterHidpi')}
            onPress={() => toggleFilter('hidpi')}
          />
          <FilterToggle
            active={filters.standardScale}
            label={t('filterStandardScale')}
            onPress={() => toggleFilter('standardScale')}
          />
          <FilterToggle
            active={filters.favorites}
            label={t('filterFavorites')}
            onPress={() => toggleFilter('favorites')}
          />
          <FilterToggle
            active={filters.current}
            label={t('filterCurrent')}
            onPress={() => toggleFilter('current')}
          />
        </View>
        {filteredModes.length > 0 ? (
          <StableLegendList
            data={filteredModes}
            estimatedItemSize={68}
            keyExtractor={(mode) => mode.id}
            renderItem={({ item }) => (
              <ModeOverlayRow
                mode={item}
                onFavorite={onFavorite}
                onRemoveFavorite={onRemoveFavorite}
                onSelect={onSelect}
                t={t}
              />
            )}
            style={styles.list}
          />
        ) : (
          <View style={styles.empty}>
            <Text style={styles.emptyText}>{t('noMatchingModes')}</Text>
          </View>
        )}
      </View>
    </View>
  );
}

function ModeOverlayRow({
  mode,
  onFavorite,
  onRemoveFavorite,
  onSelect,
  t,
}: {
  mode: DisplayControlMode;
  onFavorite: (modeID: string) => void;
  onRemoveFavorite: (modeID: string) => void;
  onSelect: (modeID: string) => void;
  t: (key: TranslationKey) => string;
}) {
  return (
    <View style={[styles.row, mode.isCurrent && styles.rowSelected]}>
      <Pressable
        accessibilityRole="button"
        onPress={() => onSelect(mode.id)}
        style={({ pressed }) => [styles.rowMain, pressed && styles.rowPressed]}
      >
        <View style={styles.rowIcon}>
          <Icon
            color={mode.isCurrent ? '#ffffff' : '#2b89ff'}
            name={mode.isCurrent ? 'check' : 'display'}
            size={15}
          />
        </View>
        <View style={styles.rowTextBlock}>
          <ModeSummary mode={mode} selected={mode.isCurrent} />
        </View>
      </Pressable>
      <Pressable
        accessibilityRole="button"
        onPress={() =>
          mode.isFavorite ? onRemoveFavorite(mode.id) : onFavorite(mode.id)
        }
        style={({ pressed }) => [
          styles.favoriteButton,
          mode.isFavorite && styles.favoriteButtonSelected,
          pressed && styles.rowPressed,
        ]}
      >
        <Text
          style={[
            styles.favoriteText,
            mode.isFavorite && styles.favoriteTextSelected,
          ]}
        >
          {mode.isFavorite ? t('savedFavorite') : t('saveFavorite')}
        </Text>
      </Pressable>
    </View>
  );
}

function FilterToggle({
  active,
  label,
  onPress,
}: {
  active: boolean;
  label: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [
        styles.filterToggle,
        active && styles.filterToggleActive,
        pressed && styles.rowPressed,
      ]}
    >
      <Text
        style={[
          styles.filterToggleText,
          active && styles.filterToggleTextActive,
        ]}
      >
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root: {
    bottom: 0,
    left: 0,
    position: 'absolute',
    right: 0,
    top: 0,
  },
  backdrop: {
    backgroundColor: 'rgba(0,0,0,0.62)',
    bottom: 0,
    left: 0,
    position: 'absolute',
    right: 0,
    top: 0,
  },
  sheet: {
    backgroundColor: '#15181e',
    borderColor: 'rgba(178,182,189,0.18)',
    borderRadius: 8,
    borderWidth: 1,
    bottom: 16,
    left: 16,
    maxHeight: 540,
    padding: 12,
    position: 'absolute',
    right: 16,
    top: 92,
  },
  header: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  title: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 15,
    fontWeight: '700',
    lineHeight: 20,
  },
  meta: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    lineHeight: 16,
  },
  closeButton: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    height: 34,
    justifyContent: 'center',
    width: 34,
  },
  closeButtonPressed: {
    backgroundColor: '#3b3d45',
  },
  searchBox: {
    alignItems: 'center',
    backgroundColor: '#000000',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    flexDirection: 'row',
    minHeight: 42,
    paddingHorizontal: 10,
  },
  searchInput: {
    color: '#ffffff',
    flex: 1,
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    lineHeight: 18,
    marginLeft: 8,
    paddingVertical: 8,
  },
  list: {
    flex: 1,
    marginTop: 10,
  },
  filterRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: 8,
  },
  filterToggle: {
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    marginRight: 6,
    marginTop: 6,
    minHeight: 28,
    paddingHorizontal: 9,
    paddingVertical: 6,
  },
  filterToggleActive: {
    backgroundColor: '#ffffff',
    borderColor: '#ffffff',
  },
  filterToggleText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 11,
    fontWeight: '700',
    lineHeight: 14,
  },
  filterToggleTextActive: {
    color: '#000000',
  },
  row: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    flexDirection: 'row',
    marginBottom: 8,
    minHeight: 60,
    overflow: 'hidden',
  },
  rowSelected: {
    backgroundColor: '#2b89ff',
    borderColor: '#2b89ff',
  },
  rowMain: {
    alignSelf: 'stretch',
    alignItems: 'stretch',
    flex: 1,
    flexDirection: 'row',
    minHeight: 60,
    minWidth: 0,
    paddingHorizontal: 10,
  },
  rowPressed: {
    opacity: 0.76,
  },
  rowIcon: {
    alignItems: 'center',
    alignSelf: 'stretch',
    justifyContent: 'center',
    width: 26,
  },
  rowTextBlock: {
    alignSelf: 'stretch',
    flex: 1,
    justifyContent: 'center',
    minWidth: 0,
  },
  favoriteButton: {
    alignItems: 'center',
    alignSelf: 'center',
    backgroundColor: '#15181e',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    justifyContent: 'center',
    marginRight: 8,
    minHeight: 32,
    minWidth: 66,
    paddingHorizontal: 8,
  },
  favoriteButtonSelected: {
    backgroundColor: '#00ca8e',
    borderColor: '#00ca8e',
  },
  favoriteText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '700',
    lineHeight: 15,
  },
  favoriteTextSelected: {
    color: '#ffffff',
  },
  empty: {
    alignItems: 'center',
    flex: 1,
    justifyContent: 'center',
  },
  emptyText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    lineHeight: 18,
  },
});
