import { Pressable, StyleSheet, Text, View } from 'react-native';

import type { TranslationKey } from '../i18n/strings';
import { Icon, type IconName } from './Icon';

const font = {
  family: 'Inter',
} as const;

const tabLabels = {
  advanced: 'tabAdvanced',
  arrange: 'tabArrange',
  color: 'tabColor',
  display: 'tabDisplay',
  input: 'tabInput',
} as const;

const tabIcons = {
  advanced: 'settings',
  arrange: 'layout',
  color: 'palette',
  display: 'display',
  input: 'plug',
} as const satisfies Record<keyof typeof tabLabels, IconName>;

export function SegmentedTabs<T extends keyof typeof tabLabels>({
  activeTab,
  onChange,
  t,
  tabs,
}: {
  activeTab: T;
  onChange: (tab: T) => void;
  t: (key: TranslationKey) => string;
  tabs: ReadonlyArray<T>;
}) {
  return (
    <View style={styles.tabs}>
      {tabs.map((tab) => {
        const selected = activeTab === tab;

        return (
          <Pressable
            accessibilityRole="button"
            key={tab}
            onPress={() => onChange(tab)}
            style={({ pressed }) => [
              styles.tab,
              selected && styles.tabSelected,
              pressed && styles.tabPressed,
            ]}
          >
            <Icon
              color={selected ? '#ffffff' : '#b2b6bd'}
              name={tabIcons[tab]}
              size={14}
            />
            <Text style={[styles.text, selected && styles.textSelected]}>
              {t(tabLabels[tab])}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  tabs: {
    backgroundColor: '#15181e',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    flexDirection: 'row',
    marginBottom: 12,
    padding: 3,
  },
  tab: {
    alignItems: 'center',
    borderRadius: 6,
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'center',
    minHeight: 32,
  },
  tabSelected: {
    backgroundColor: '#2b89ff',
  },
  tabPressed: {
    backgroundColor: '#3b3d45',
  },
  text: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 15,
    marginLeft: 5,
  },
  textSelected: {
    color: '#ffffff',
  },
});
