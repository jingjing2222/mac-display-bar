import { overlay } from 'overlay-kit';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import type {
  DisplayControlDisplay,
  DisplayControlMode,
} from '../../specs/NativeDisplayControl';
import type { TranslationKey } from '../i18n/strings';
import { Icon } from './Icon';
import { ModeSummary } from './ModeSummary';
import { ResolutionModeOverlay } from './ResolutionModeOverlay';
import { ResolutionRevertOverlay } from './ResolutionRevertOverlay';
import { StableLegendList } from './StableLegendList';

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
  const previewModes = modes.slice(0, 3);
  const selectMode = (modeID: string) => {
    if (modeID === display.currentMode.id) {
      return;
    }

    const previousMode = display.currentMode;
    onSelect(modeID);
    openRevertOverlay({
      onRevert: () => onSelect(previousMode.id),
      previousMode,
      t,
    });
  };

  const openModeOverlay = () => {
    overlay.open(({ close, isOpen, unmount }) => {
      if (!isOpen) {
        return null;
      }

      const closeOverlay = () => {
        close();
        unmount();
      };

      return (
        <ResolutionModeOverlay
          modes={display.availableModes}
          onClose={closeOverlay}
          onFavorite={onFavorite}
          onRemoveFavorite={onRemoveFavorite}
          onSelect={(modeID) => {
            closeOverlay();
            selectMode(modeID);
          }}
          t={t}
        />
      );
    });
  };

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
      <Pressable
        accessibilityRole="button"
        onPress={openModeOverlay}
        style={({ pressed }) => [
          styles.current,
          pressed && styles.currentPressed,
        ]}
      >
        <Text style={styles.currentLabel}>{t('currentMode')}</Text>
        <View style={styles.currentValueRow}>
          <ModeSummary mode={display.currentMode} />
          <Icon color="#b2b6bd" name="chevronDown" size={15} />
        </View>
      </Pressable>
      {previewModes.length > 0 ? (
        <View style={styles.previewList}>
          <View style={styles.previewHeader}>
            <Text style={styles.previewTitle}>
              {favorites.length > 0 ? t('favoriteModes') : t('allModes')}
            </Text>
            <Pressable
              accessibilityRole="button"
              onPress={openModeOverlay}
              style={({ pressed }) => [
                styles.allModesButton,
                pressed && styles.modePressed,
              ]}
            >
              <Text style={styles.allModesText}>
                {display.availableModes.length} {t('modesAvailable')}
              </Text>
            </Pressable>
          </View>
          <StableLegendList
            data={previewModes}
            estimatedItemSize={62}
            keyExtractor={(mode) => mode.id}
            renderItem={({ item }) => (
              <ModePreviewRow
                mode={item}
                onFavorite={onFavorite}
                onRemoveFavorite={onRemoveFavorite}
                onSelect={selectMode}
                t={t}
              />
            )}
            scrollEnabled={false}
            style={[
              styles.modeList,
              { height: Math.max(previewModes.length * 62, 62) },
            ]}
          />
        </View>
      ) : null}
    </View>
  );
}

function ModePreviewRow({
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
    <View style={[styles.modeRow, mode.isCurrent && styles.modeSelected]}>
      <Pressable
        accessibilityRole="button"
        onPress={() => onSelect(mode.id)}
        style={({ pressed }) => [
          styles.modeMain,
          pressed && styles.modePressed,
        ]}
      >
        <View style={styles.modeIcon}>
          <Icon
            color={mode.isCurrent ? '#ffffff' : '#2b89ff'}
            name={mode.isCurrent ? 'check' : 'display'}
            size={14}
          />
        </View>
        <View style={styles.modeTextBlock}>
          <ModeSummary mode={mode} selected={mode.isCurrent} />
        </View>
      </Pressable>
      <Pressable
        accessibilityRole="button"
        onPress={() =>
          mode.isFavorite ? onRemoveFavorite(mode.id) : onFavorite(mode.id)
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
  );
}

function openRevertOverlay({
  onRevert,
  previousMode,
  t,
}: {
  onRevert: () => void;
  previousMode: DisplayControlMode;
  t: (key: TranslationKey) => string;
}) {
  overlay.open(({ close, isOpen, unmount }) => {
    if (!isOpen) {
      return null;
    }

    const closeOverlay = () => {
      close();
      unmount();
    };

    return (
      <ResolutionRevertOverlay
        onClose={closeOverlay}
        onRevert={onRevert}
        previousMode={previousMode}
        t={t}
      />
    );
  });
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
  currentPressed: {
    backgroundColor: '#3b3d45',
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
  currentValueRow: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  previewList: {
    backgroundColor: '#000000',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    padding: 8,
  },
  previewHeader: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  previewTitle: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '700',
    lineHeight: 16,
  },
  allModesButton: {
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    paddingHorizontal: 8,
    paddingVertical: 5,
  },
  allModesText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '700',
    lineHeight: 15,
  },
  modeList: {
    width: '100%',
  },
  modeRow: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    flexDirection: 'row',
    marginBottom: 8,
    minHeight: 54,
    overflow: 'hidden',
  },
  modeMain: {
    alignSelf: 'stretch',
    alignItems: 'stretch',
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'center',
    minHeight: 54,
    minWidth: 0,
    paddingHorizontal: 10,
  },
  modeIcon: {
    alignItems: 'center',
    alignSelf: 'stretch',
    justifyContent: 'center',
    width: 18,
  },
  modeSelected: {
    backgroundColor: '#2b89ff',
    borderColor: '#2b89ff',
  },
  modePressed: {
    backgroundColor: '#3b3d45',
  },
  modeTextBlock: {
    alignSelf: 'stretch',
    flex: 1,
    justifyContent: 'center',
    marginLeft: 8,
    minWidth: 0,
  },
  modeTextSelected: {
    color: '#ffffff',
  },
  favorite: {
    alignItems: 'center',
    alignSelf: 'center',
    backgroundColor: '#15181e',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    justifyContent: 'center',
    marginRight: 8,
    minHeight: 30,
    minWidth: 58,
    paddingHorizontal: 8,
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
