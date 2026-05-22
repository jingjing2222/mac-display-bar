import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

import type {
  DisplayControlPreset,
  DisplayControlSettings,
  DisplayControlSyncGroup,
} from '../../specs/NativeDisplayControl';

const font = {
  family: 'Inter',
} as const;

const refreshIntervalOptions = [5, 15, 30, 60];

export function SettingsControls({
  settings,
  onSetSettings,
}: {
  settings: DisplayControlSettings;
  onSetSettings: (
    autoRefresh: boolean,
    refreshIntervalSeconds: number,
    showAdvancedMetadata: boolean,
  ) => void;
}) {
  return (
    <View style={styles.block}>
      <View style={styles.header}>
        <Text style={styles.label}>Settings</Text>
        <Text style={styles.value}>
          {settings.autoRefresh
            ? `${settings.refreshIntervalSeconds}s refresh`
            : 'Manual refresh'}
        </Text>
      </View>

      <View style={styles.actions}>
        <ControlButton
          label="Auto"
          onPress={() =>
            onSetSettings(
              !settings.autoRefresh,
              settings.refreshIntervalSeconds,
              settings.showAdvancedMetadata,
            )
          }
          selected={settings.autoRefresh}
        />
        <ControlButton
          label="Meta"
          onPress={() =>
            onSetSettings(
              settings.autoRefresh,
              settings.refreshIntervalSeconds,
              !settings.showAdvancedMetadata,
            )
          }
          selected={settings.showAdvancedMetadata}
        />
      </View>

      <View style={styles.actions}>
        {refreshIntervalOptions.map((intervalSeconds) => (
          <ControlButton
            key={intervalSeconds}
            label={`${intervalSeconds}s`}
            onPress={() =>
              onSetSettings(
                settings.autoRefresh,
                intervalSeconds,
                settings.showAdvancedMetadata,
              )
            }
            selected={settings.refreshIntervalSeconds === intervalSeconds}
          />
        ))}
      </View>
    </View>
  );
}

export function SyncControls({
  groupName,
  layoutDriftCount,
  layoutProtectionEnabled,
  layoutProtectionStatus,
  syncGroups,
  onApplyGroup,
  onChangeGroupName,
  onClearLayout,
  onDeleteGroup,
  onRestoreLayout,
  onSaveGroup,
  onSaveLayout,
}: {
  groupName: string;
  layoutDriftCount: number;
  layoutProtectionEnabled: boolean;
  layoutProtectionStatus: string;
  syncGroups: Array<DisplayControlSyncGroup>;
  onApplyGroup: (groupID: string) => void;
  onChangeGroupName: (name: string) => void;
  onClearLayout: () => void;
  onDeleteGroup: (groupID: string) => void;
  onRestoreLayout: () => void;
  onSaveGroup: () => void;
  onSaveLayout: () => void;
}) {
  return (
    <View style={styles.block}>
      <View style={styles.header}>
        <Text style={styles.label}>Sync and layout</Text>
        <Text style={styles.value}>
          {layoutProtectionEnabled
            ? `${layoutProtectionStatus} / ${layoutDriftCount} drift`
            : layoutProtectionStatus}
        </Text>
      </View>

      <View style={styles.createRow}>
        <TextInput
          onChangeText={onChangeGroupName}
          placeholder="Group name"
          placeholderTextColor="#656a76"
          style={styles.input}
          value={groupName}
        />
        <PrimaryButton label="Group" onPress={onSaveGroup} />
      </View>

      <View style={styles.actions}>
        <ControlButton label="Protect" onPress={onSaveLayout} />
        <ControlButton label="Restore" onPress={onRestoreLayout} />
        <ControlButton label="Clear" onPress={onClearLayout} />
      </View>

      {syncGroups.length > 0 ? (
        <View style={styles.list}>
          {syncGroups.map((group) => (
            <View key={group.id} style={styles.row}>
              <View style={styles.textBlock}>
                <Text style={styles.name}>{group.name}</Text>
                <Text style={styles.meta}>
                  {group.displayIDs.length} displays / brightness + scale
                </Text>
              </View>
              <SmallButton
                label="Apply"
                onPress={() => onApplyGroup(group.id)}
              />
              <SmallButton
                label="Delete"
                onPress={() => onDeleteGroup(group.id)}
              />
            </View>
          ))}
        </View>
      ) : null}
    </View>
  );
}

export function PresetControls({
  name,
  presets,
  onApply,
  onChangeName,
  onDelete,
  onSave,
}: {
  name: string;
  presets: Array<DisplayControlPreset>;
  onApply: (name: string) => void;
  onChangeName: (name: string) => void;
  onDelete: (name: string) => void;
  onSave: () => void;
}) {
  return (
    <View style={styles.block}>
      <View style={styles.header}>
        <Text style={styles.label}>Presets</Text>
        <Text style={styles.value}>{presets.length}</Text>
      </View>

      <View style={styles.createRow}>
        <TextInput
          onChangeText={onChangeName}
          placeholder="Preset name"
          placeholderTextColor="#656a76"
          style={styles.input}
          value={name}
        />
        <PrimaryButton label="Save" onPress={onSave} />
      </View>

      {presets.length > 0 ? (
        <View style={styles.list}>
          {presets.map((preset) => (
            <View key={preset.name} style={styles.row}>
              <View style={styles.textBlock}>
                <Text style={styles.name}>{preset.name}</Text>
                <Text style={styles.meta}>{preset.displayCount} displays</Text>
              </View>
              <SmallButton label="Apply" onPress={() => onApply(preset.name)} />
              <SmallButton
                label="Delete"
                onPress={() => onDelete(preset.name)}
              />
            </View>
          ))}
        </View>
      ) : null}
    </View>
  );
}

function ControlButton({
  label,
  onPress,
  selected,
}: {
  label: string;
  onPress: () => void;
  selected?: boolean;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [
        styles.actionButton,
        selected && styles.selectedButton,
        pressed && styles.pressedButton,
      ]}
    >
      <Text style={[styles.buttonText, selected && styles.selectedButtonText]}>
        {label}
      </Text>
    </Pressable>
  );
}

function PrimaryButton({
  label,
  onPress,
}: {
  label: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [
        styles.primaryButton,
        pressed && styles.pressedButton,
      ]}
    >
      <Text style={styles.primaryButtonText}>{label}</Text>
    </Pressable>
  );
}

function SmallButton({
  label,
  onPress,
}: {
  label: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [
        styles.smallButton,
        pressed && styles.pressedButton,
      ]}
    >
      <Text style={styles.buttonText}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  block: {
    borderBottomColor: 'rgba(178,182,189,0.1)',
    borderBottomWidth: 1,
    paddingVertical: 16,
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
  },
  value: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    letterSpacing: 0.2,
    lineHeight: 18,
  },
  actions: {
    flexDirection: 'row',
    marginTop: 10,
  },
  actionButton: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    flex: 1,
    justifyContent: 'center',
    marginRight: 8,
    minHeight: 34,
  },
  selectedButton: {
    backgroundColor: '#2b89ff',
    borderColor: '#2b89ff',
  },
  pressedButton: {
    backgroundColor: '#3b3d45',
  },
  buttonText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 18,
  },
  selectedButtonText: {
    color: '#ffffff',
  },
  createRow: {
    flexDirection: 'row',
  },
  input: {
    backgroundColor: '#15181e',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    color: '#ffffff',
    flex: 1,
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '500',
    letterSpacing: 0,
    lineHeight: 18,
    marginRight: 8,
    minHeight: 40,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  primaryButton: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: 'rgba(178,182,189,0.1)',
    borderRadius: 8,
    borderWidth: 1,
    justifyContent: 'center',
    minHeight: 40,
    paddingHorizontal: 16,
  },
  primaryButtonText: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 14,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 18,
  },
  list: {
    marginTop: 12,
  },
  row: {
    alignItems: 'center',
    flexDirection: 'row',
    marginTop: 8,
  },
  textBlock: {
    flex: 1,
    paddingRight: 8,
  },
  name: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 18,
  },
  meta: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '500',
    letterSpacing: 0,
    lineHeight: 16,
  },
  smallButton: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    justifyContent: 'center',
    marginLeft: 8,
    minHeight: 34,
    minWidth: 58,
    paddingHorizontal: 8,
  },
});
