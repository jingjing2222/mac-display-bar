/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import { HotUpdater } from '@hot-updater/react-native';
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from 'react-native';
import { DisplayList } from './src/components/DisplayList';
import { HotUpdateControls } from './src/components/HotUpdateControls';
import {
  PresetControls,
  SettingsControls,
  SyncControls,
} from './src/components/MenuControls';
import { hotUpdaterBaseURL } from './src/config/hotUpdaterConfig';
import { useDisplayControl } from './src/hooks/display/useDisplayControl';

const font = {
  family: 'Inter',
} as const;

function App() {
  const { width } = useWindowDimensions();
  const panelWidth = Math.min(Math.max(width, 360), 420);
  const {
    actions,
    presetName,
    setPresetName,
    setSyncGroupName,
    snapshot,
    snapshotError,
    syncGroupName,
  } = useDisplayControl();
  const { refreshSnapshot, setSettings } = actions;

  return (
    <View style={styles.container}>
      <ScrollView
        contentContainerStyle={styles.panelContent}
        style={[styles.panel, { width: panelWidth }]}
      >
        <View>
          <View style={styles.header}>
            <View>
              <Text style={styles.eyebrow}>DISPLAY CONTROL</Text>
              <Text style={styles.title}>Mac Display Bar</Text>
            </View>
            <View style={styles.statusBadge}>
              <Text style={styles.statusText}>{snapshot.moduleStatus}</Text>
            </View>
          </View>

          <View style={styles.summary}>
            <View>
              <Text style={styles.summaryValue}>
                {snapshot.displays.length}
              </Text>
              <Text style={styles.summaryLabel}>
                {snapshot.architecture} / {snapshot.platform}
              </Text>
              <Text style={styles.summaryLabel}>
                {snapshot.machineModel} /{' '}
                {snapshot.isAppleSilicon ? 'Apple Silicon' : 'Intel/Other'}
              </Text>
              <Text style={styles.summaryLabel}>
                {snapshot.displayTopologyStatus} / rev{' '}
                {snapshot.displayTopologyRevision}
              </Text>
            </View>
            <Pressable
              accessibilityRole="button"
              onPress={refreshSnapshot}
              style={({ pressed }) => [
                styles.refreshButton,
                pressed && styles.refreshButtonPressed,
              ]}
            >
              <Text style={styles.refreshButtonText}>Refresh</Text>
            </Pressable>
          </View>

          {snapshotError ? (
            <View style={styles.errorSurface}>
              <Text style={styles.errorText}>{snapshotError}</Text>
            </View>
          ) : null}

          <HotUpdateControls />

          <SettingsControls
            onSetSettings={setSettings}
            settings={snapshot.settings}
          />

          <PresetControls
            name={presetName}
            presets={snapshot.presets}
            onApply={actions.applyPreset}
            onChangeName={setPresetName}
            onDelete={actions.deletePreset}
            onSave={actions.savePreset}
          />

          <SyncControls
            groupName={syncGroupName}
            layoutDriftCount={snapshot.layoutDriftCount}
            layoutProtectionEnabled={snapshot.layoutProtectionEnabled}
            layoutProtectionStatus={snapshot.layoutProtectionStatus}
            onApplyGroup={actions.applySyncGroup}
            onChangeGroupName={setSyncGroupName}
            onClearLayout={actions.clearProtectedLayout}
            onDeleteGroup={actions.deleteSyncGroup}
            onRestoreLayout={actions.restoreProtectedLayout}
            onSaveGroup={actions.saveSyncGroup}
            onSaveLayout={actions.saveProtectedLayout}
            syncGroups={snapshot.syncGroups}
          />

          <DisplayList
            actions={actions}
            displays={snapshot.displays}
            showAdvancedMetadata={snapshot.settings.showAdvancedMetadata}
          />
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000',
  },
  panel: {
    flex: 1,
    backgroundColor: '#000000',
  },
  panelContent: {
    padding: 16,
  },
  header: {
    alignItems: 'center',
    borderBottomColor: 'rgba(178,182,189,0.1)',
    borderBottomWidth: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingBottom: 16,
  },
  eyebrow: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0.6,
    lineHeight: 15,
    marginBottom: 8,
  },
  title: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 22,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 26,
  },
  statusBadge: {
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 9999,
    borderWidth: 1,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  statusText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0.6,
    lineHeight: 15,
    textTransform: 'uppercase',
  },
  summary: {
    alignItems: 'center',
    borderBottomColor: 'rgba(178,182,189,0.1)',
    borderBottomWidth: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 16,
  },
  summaryValue: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 28,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 34,
  },
  summaryLabel: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '500',
    letterSpacing: 0.2,
    lineHeight: 18,
  },
  refreshButton: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: 'rgba(178,182,189,0.1)',
    borderRadius: 8,
    borderWidth: 1,
    justifyContent: 'center',
    minHeight: 40,
    paddingHorizontal: 18,
    paddingVertical: 10,
  },
  refreshButtonPressed: {
    backgroundColor: '#3b3d45',
  },
  refreshButtonText: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 14,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 18,
  },
  errorSurface: {
    backgroundColor: 'rgba(230,43,30,0.12)',
    borderColor: 'rgba(230,43,30,0.4)',
    borderRadius: 8,
    borderWidth: 1,
    marginTop: 16,
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

export default HotUpdater.wrap({
  baseURL: hotUpdaterBaseURL,
  updateStrategy: 'appVersion',
  onError: (error) => {
    console.warn('[HotUpdater]', error);
  },
})(App);
