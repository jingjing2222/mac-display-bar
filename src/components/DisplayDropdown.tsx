import { useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import type { DisplayControlDisplay } from '../../specs/NativeDisplayControl';
import type { TranslationKey } from '../i18n/strings';
import { Icon } from './Icon';

const font = {
  family: 'Inter',
} as const;

export function DisplayDropdown({
  displays,
  onSelect,
  selectedDisplay,
  t,
}: {
  displays: Array<DisplayControlDisplay>;
  onSelect: (displayID: string) => void;
  selectedDisplay: DisplayControlDisplay | null;
  t: (key: TranslationKey) => string;
}) {
  const [open, setOpen] = useState(false);

  if (!selectedDisplay) {
    return (
      <View style={styles.empty}>
        <Text style={styles.emptyTitle}>{t('noDisplaysTitle')}</Text>
        <Text style={styles.emptyBody}>{t('noDisplaysBody')}</Text>
      </View>
    );
  }

  return (
    <View style={styles.block}>
      <Text style={styles.label}>{t('displaySelect')}</Text>
      <Pressable
        accessibilityRole="button"
        onPress={() => setOpen((value) => !value)}
        style={({ pressed }) => [
          styles.trigger,
          open && styles.triggerOpen,
          pressed && styles.triggerPressed,
        ]}
      >
        <View style={styles.displayIcon}>
          <Icon color="#2b89ff" name="display" size={18} />
        </View>
        <View style={styles.triggerTextBlock}>
          <Text style={styles.displayName}>{selectedDisplay.name}</Text>
          <Text style={styles.displayMeta}>
            {displaySubtitle(selectedDisplay, t)}
          </Text>
        </View>
        <Icon
          color="#b2b6bd"
          name={open ? 'chevronUp' : 'chevronDown'}
          size={17}
        />
      </Pressable>

      {open ? (
        <View style={styles.menu}>
          {displays.map((display) => {
            const selected = display.id === selectedDisplay.id;

            return (
              <Pressable
                accessibilityRole="button"
                key={display.id}
                onPress={() => {
                  onSelect(display.id);
                  setOpen(false);
                }}
                style={({ pressed }) => [
                  styles.option,
                  selected && styles.optionSelected,
                  pressed && styles.optionPressed,
                ]}
              >
                <View style={styles.check}>
                  {selected ? (
                    <Icon color="#2b89ff" name="check" size={15} />
                  ) : null}
                </View>
                <View style={styles.optionTextBlock}>
                  <Text style={styles.optionName}>{display.name}</Text>
                  <Text style={styles.optionMeta}>
                    {displaySubtitle(display, t)}
                  </Text>
                </View>
                <View style={styles.pills}>
                  <Pill
                    label={display.isBuiltin ? t('builtIn') : t('external')}
                  />
                  {display.isPrimary ? <Pill label={t('primary')} /> : null}
                  {display.isMirrored ? <Pill label={t('mirrored')} /> : null}
                </View>
              </Pressable>
            );
          })}
        </View>
      ) : null}
    </View>
  );
}

function displaySubtitle(
  display: DisplayControlDisplay,
  t: (key: TranslationKey) => string,
) {
  const mode = display.currentMode;
  const state = display.isAsleep
    ? t('asleep')
    : display.isActive
      ? t('active')
      : t('inactive');

  return `${mode.width} x ${mode.height} / ${Math.round(mode.refreshRate)}Hz / ${state}`;
}

function Pill({ label }: { label: string }) {
  return (
    <View style={styles.pill}>
      <Text style={styles.pillText}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  block: {
    marginBottom: 14,
  },
  label: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0.6,
    lineHeight: 15,
    marginBottom: 8,
    textTransform: 'uppercase',
  },
  trigger: {
    alignItems: 'center',
    backgroundColor: '#15181e',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    flexDirection: 'row',
    minHeight: 58,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  triggerOpen: {
    borderColor: '#2b89ff',
  },
  triggerPressed: {
    backgroundColor: '#1f232b',
  },
  triggerTextBlock: {
    flex: 1,
    minWidth: 0,
  },
  displayIcon: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 7,
    borderWidth: 1,
    height: 34,
    justifyContent: 'center',
    marginRight: 10,
    width: 34,
  },
  displayName: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 16,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 22,
  },
  displayMeta: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '500',
    letterSpacing: 0,
    lineHeight: 16,
    marginTop: 3,
  },
  menu: {
    backgroundColor: '#15181e',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    marginTop: 8,
    padding: 6,
  },
  option: {
    alignItems: 'center',
    borderRadius: 6,
    flexDirection: 'row',
    minHeight: 54,
    paddingHorizontal: 8,
    paddingVertical: 8,
  },
  optionSelected: {
    backgroundColor: '#1f232b',
  },
  optionPressed: {
    backgroundColor: '#3b3d45',
  },
  check: {
    alignItems: 'center',
    justifyContent: 'center',
    width: 18,
  },
  optionTextBlock: {
    flex: 1,
    minWidth: 0,
  },
  optionName: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    lineHeight: 18,
  },
  optionMeta: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 11,
    fontWeight: '500',
    lineHeight: 15,
  },
  pills: {
    alignItems: 'flex-end',
    marginLeft: 8,
  },
  pill: {
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 9999,
    borderWidth: 1,
    marginTop: 3,
    paddingHorizontal: 7,
    paddingVertical: 3,
  },
  pillText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 10,
    fontWeight: '600',
    lineHeight: 12,
  },
  empty: {
    backgroundColor: '#15181e',
    borderColor: 'rgba(178,182,189,0.1)',
    borderRadius: 8,
    borderWidth: 1,
    marginBottom: 14,
    padding: 14,
  },
  emptyTitle: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 15,
    fontWeight: '600',
    lineHeight: 20,
  },
  emptyBody: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '500',
    lineHeight: 18,
    marginTop: 4,
  },
});
