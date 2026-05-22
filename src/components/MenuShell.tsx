import { ScrollView, StyleSheet, Text, View } from 'react-native';

import type { useDisplayControl } from '../hooks/display/useDisplayControl';
import { useSelectedDisplay } from '../hooks/display/useSelectedDisplay';
import { useI18n } from '../i18n/useI18n';
import { DisplayControlPanel } from './DisplayControlPanel';
import { DisplayDropdown } from './DisplayDropdown';
import { TopUpdateHeader } from './TopUpdateHeader';

const font = {
  family: 'Inter',
} as const;

export const menuMetrics = {
  height: 720,
  width: 520,
} as const;

export function MenuShell({
  control,
}: {
  control: ReturnType<typeof useDisplayControl>;
}) {
  const { t } = useI18n();
  const { selectedDisplay, setSelectedDisplayID } = useSelectedDisplay(
    control.snapshot.displays,
  );
  const isReady =
    control.snapshot.moduleStatus === 'ready' &&
    control.snapshot.displays.length > 0 &&
    !control.snapshotError;

  return (
    <View style={styles.container}>
      <TopUpdateHeader isReady={isReady} t={t} />
      <ScrollView
        contentContainerStyle={styles.content}
        style={styles.scrollPanel}
      >
        {control.snapshotError ? (
          <View style={styles.errorSurface}>
            <Text style={styles.errorText}>{control.snapshotError}</Text>
          </View>
        ) : null}
        <DisplayDropdown
          displays={control.snapshot.displays}
          onSelect={setSelectedDisplayID}
          selectedDisplay={selectedDisplay}
          t={t}
        />
        <DisplayControlPanel
          control={control}
          display={selectedDisplay}
          t={t}
        />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#000000',
    flex: 1,
    height: menuMetrics.height,
    width: menuMetrics.width,
  },
  scrollPanel: {
    backgroundColor: '#000000',
    flex: 1,
    width: menuMetrics.width,
  },
  content: {
    padding: 16,
  },
  errorSurface: {
    backgroundColor: 'rgba(230,43,30,0.12)',
    borderColor: 'rgba(230,43,30,0.4)',
    borderRadius: 8,
    borderWidth: 1,
    marginBottom: 14,
    padding: 12,
  },
  errorText: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '500',
    letterSpacing: 0.2,
    lineHeight: 18,
  },
});
