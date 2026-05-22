import { useEffect, useMemo, useState } from 'react';
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import type {
  DisplayControlColorProfile,
  DisplayControlDisplay,
  DisplayControlMode,
} from '../../specs/NativeDisplayControl';
import type { CustomResolutionDraft } from '../native/displayControlApi';

const font = {
  family: 'Inter',
} as const;

type DisplayListActions = {
  addCustomResolution: (
    display: DisplayControlDisplay,
    request: CustomResolutionDraft,
  ) => void;
  clearEdidOverride: (displayID: string) => void;
  disableXdrUpscale: (displayID: string) => void;
  enableXdrUpscale: (displayID: string) => void;
  exportEdid: (displayID: string) => void;
  queueEdidOverride: (displayID: string) => void;
  reconnectDisplay: (displayID: string) => void;
  removeCustomResolution: (displayID: string, requestID: string) => void;
  removeFavoriteMode: (displayID: string, modeID: string) => void;
  resetColorProfile: (displayID: string) => void;
  saveFavoriteMode: (displayID: string, modeID: string) => void;
  setColorProfile: (displayID: string, profileID: string) => void;
  setDdcControl: (
    displayID: string,
    controlCode: number,
    value: number,
  ) => void;
  setDisplayMode: (displayID: string, modeID: string) => void;
  setDisplayOrigin: (displayID: string, x: number, y: number) => void;
  setDisplayRotation: (displayID: string, rotation: number) => void;
  setNativeBrightness: (displayID: string, level: number) => void;
  setSoftwareDimming: (displayID: string, level: number) => void;
  softDisconnectDisplay: (displayID: string) => void;
  writeOverrideBundle: (displayID: string) => void;
};

export function DisplayList({
  actions,
  displays,
  showAdvancedMetadata,
}: {
  actions: DisplayListActions;
  displays: Array<DisplayControlDisplay>;
  showAdvancedMetadata: boolean;
}) {
  return (
    <View style={styles.displayList}>
      {displays.length === 0 ? (
        <View style={styles.displayCard}>
          <Text style={styles.displayName}>No displays found</Text>
          <Text style={styles.displayMeta}>Native module unavailable</Text>
        </View>
      ) : (
        displays.map((display) => (
          <DisplayCard
            actions={actions}
            display={display}
            key={display.id}
            showAdvancedMetadata={showAdvancedMetadata}
          />
        ))
      )}
    </View>
  );
}

function DisplayCard({
  actions,
  display,
  showAdvancedMetadata,
}: {
  actions: DisplayListActions;
  display: DisplayControlDisplay;
  showAdvancedMetadata: boolean;
}) {
  return (
    <View style={styles.displayCard}>
      <View style={styles.displayHeader}>
        <View style={styles.displayNameBlock}>
          <Text style={styles.displayName}>{display.name}</Text>
          <Text style={styles.displayMeta}>
            {display.connectionType}
            {display.isPrimary ? ' / Primary' : ''}
            {display.isBuiltin ? ' / Built-in' : ''}
            {!display.isActive ? ' / Inactive' : ''}
            {display.isAsleep ? ' / Asleep' : ''}
            {display.isMirrored ? ' / Mirrored' : ''}
          </Text>
          <Text style={styles.displayMeta}>
            V{display.identity.vendorID} / M{display.identity.modelID} / S
            {display.identity.serialNumber || 'n/a'}
          </Text>
          {showAdvancedMetadata && display.identity.uuid ? (
            <Text style={styles.displayMeta}>UUID {display.identity.uuid}</Text>
          ) : null}
        </View>
        <View
          style={[
            styles.onlineDot,
            display.isOnline && display.isActive && !display.isAsleep
              ? styles.onlineDotOn
              : styles.onlineDotOff,
          ]}
        />
      </View>

      <View style={styles.modeGrid}>
        <Metric
          label="Resolution"
          value={`${display.currentMode.width} x ${display.currentMode.height}`}
        />
        <Metric
          label="Refresh"
          value={`${display.currentMode.refreshRate} Hz`}
        />
        <Metric label="Rotation" value={`${display.rotation}`} />
      </View>

      <View style={styles.modeGrid}>
        <Metric label="Product" value={display.identity.productName} />
        <Metric label="Transport" value={display.identity.transport} />
        <Metric
          label="Mirror"
          value={
            display.isMirrored
              ? display.mirrorsDisplayID
                ? `to ${display.mirrorsDisplayID}`
                : display.isHardwareMirrored
                  ? 'hardware'
                  : 'on'
              : 'off'
          }
        />
      </View>

      <ModeControls
        display={display}
        onFavorite={(modeID) => actions.saveFavoriteMode(display.id, modeID)}
        onRemoveFavorite={(modeID) =>
          actions.removeFavoriteMode(display.id, modeID)
        }
        onChange={(modeID) => actions.setDisplayMode(display.id, modeID)}
      />

      <ArrangementControls
        display={display}
        onChange={(x, y) => actions.setDisplayOrigin(display.id, x, y)}
      />

      <View style={styles.capabilityRow}>
        <Capability label="Brightness" enabled={display.supportsBrightness} />
        <Capability label="Dimming" enabled={display.supportsSoftwareDimming} />
        <Capability label="DDC" enabled={display.supportsDdc} />
        <Capability label="HDR" enabled={display.supportsHdr} />
      </View>

      <BrightnessControls
        display={display}
        onChange={(level) => actions.setNativeBrightness(display.id, level)}
      />

      <DimmingControls
        level={display.softwareDimming}
        onChange={(level) => actions.setSoftwareDimming(display.id, level)}
      />

      <ColorControls
        display={display}
        onReset={() => actions.resetColorProfile(display.id)}
        onSelect={(profileID) => actions.setColorProfile(display.id, profileID)}
      />

      <DdcControls
        display={display}
        onChange={(controlCode, value) =>
          actions.setDdcControl(display.id, controlCode, value)
        }
      />

      <AdvancedControls
        display={display}
        onAddCustomResolution={(request) =>
          actions.addCustomResolution(display, request)
        }
        onClearEdidOverride={() => actions.clearEdidOverride(display.id)}
        onDisableXdrUpscale={() => actions.disableXdrUpscale(display.id)}
        onEnableXdrUpscale={() => actions.enableXdrUpscale(display.id)}
        onExportEdid={() => actions.exportEdid(display.id)}
        onQueueEdidOverride={() => actions.queueEdidOverride(display.id)}
        onReconnect={() => actions.reconnectDisplay(display.id)}
        onRemoveCustomResolution={(requestID) =>
          actions.removeCustomResolution(display.id, requestID)
        }
        onSetRotation={(rotation) =>
          actions.setDisplayRotation(display.id, rotation)
        }
        onSoftDisconnect={() => actions.softDisconnectDisplay(display.id)}
        onWriteOverrideBundle={() => actions.writeOverrideBundle(display.id)}
      />
    </View>
  );
}

function AdvancedControls({
  display,
  onAddCustomResolution,
  onClearEdidOverride,
  onDisableXdrUpscale,
  onEnableXdrUpscale,
  onExportEdid,
  onQueueEdidOverride,
  onReconnect,
  onRemoveCustomResolution,
  onSetRotation,
  onSoftDisconnect,
  onWriteOverrideBundle,
}: {
  display: DisplayControlDisplay;
  onAddCustomResolution: (request: CustomResolutionDraft) => void;
  onClearEdidOverride: () => void;
  onDisableXdrUpscale: () => void;
  onEnableXdrUpscale: () => void;
  onExportEdid: () => void;
  onQueueEdidOverride: () => void;
  onReconnect: () => void;
  onRemoveCustomResolution: (requestID: string) => void;
  onSetRotation: (rotation: number) => void;
  onSoftDisconnect: () => void;
  onWriteOverrideBundle: () => void;
}) {
  const rotationOptions = [0, 90, 180, 270];
  const modeDraft = useMemo(
    () => ({
      height: `${display.currentMode.height}`,
      refreshRate: `${Math.round(display.currentMode.refreshRate || 60)}`,
      width: `${display.currentMode.width}`,
    }),
    [
      display.currentMode.height,
      display.currentMode.refreshRate,
      display.currentMode.width,
    ],
  );
  const [customWidth, setCustomWidth] = useState(modeDraft.width);
  const [customHeight, setCustomHeight] = useState(modeDraft.height);
  const [customRefreshRate, setCustomRefreshRate] = useState(
    modeDraft.refreshRate,
  );
  const [customIsHiDpi, setCustomIsHiDpi] = useState(true);

  useEffect(() => {
    setCustomWidth(modeDraft.width);
    setCustomHeight(modeDraft.height);
    setCustomRefreshRate(modeDraft.refreshRate);
  }, [display.id, modeDraft.height, modeDraft.refreshRate, modeDraft.width]);

  const customResolutionDraft = {
    width: positiveNumberFromInput(customWidth, display.currentMode.width),
    height: positiveNumberFromInput(customHeight, display.currentMode.height),
    refreshRate: positiveNumberFromInput(
      customRefreshRate,
      display.currentMode.refreshRate || 60,
    ),
    isHiDpi: customIsHiDpi,
  };

  return (
    <View style={styles.advancedBlock}>
      <View style={styles.dimmingHeader}>
        <Text style={styles.dimmingLabel}>Advanced</Text>
        <Text style={styles.dimmingValue}>
          {display.advanced.softConnectionState}
        </Text>
      </View>

      <View style={styles.hdrGrid}>
        <Metric
          label="EDID"
          value={
            display.advanced.supportsEdidExport
              ? `${display.advanced.edidBytes} bytes`
              : 'Unavailable'
          }
        />
        <Metric
          label="Custom"
          value={`${display.advanced.customResolutions.length} queued`}
        />
        <Metric label="XDR" value={display.advanced.xdrUpscaleState} />
        <Metric
          label="Rotate"
          value={`${display.advanced.rotationRequest} deg`}
        />
      </View>

      <View style={styles.syncActions}>
        {rotationOptions.map((rotation) => (
          <Pressable
            accessibilityRole="button"
            key={rotation}
            onPress={() => onSetRotation(rotation)}
            style={({ pressed }) => [
              styles.syncActionButton,
              Math.round(display.advanced.rotationRequest) === rotation &&
                styles.dimmingButtonSelected,
              pressed && styles.dimmingButtonPressed,
            ]}
          >
            <Text
              style={[
                styles.dimmingButtonText,
                Math.round(display.advanced.rotationRequest) === rotation &&
                  styles.dimmingButtonTextSelected,
              ]}
            >
              {rotation}
            </Text>
          </Pressable>
        ))}
      </View>

      <View style={styles.syncActions}>
        <ControlButton label="EDID" onPress={onExportEdid} />
        <ControlButton label="Override" onPress={onQueueEdidOverride} />
        <ControlButton label="Clear" onPress={onClearEdidOverride} />
        <ControlButton label="Bundle" onPress={onWriteOverrideBundle} />
      </View>

      <View style={styles.syncActions}>
        <ControlButton label="XDR+" onPress={onEnableXdrUpscale} />
        <ControlButton label="XDR Off" onPress={onDisableXdrUpscale} />
        <ControlButton
          label="HiDPI"
          onPress={() => setCustomIsHiDpi((isHiDpi) => !isHiDpi)}
          selected={customIsHiDpi}
        />
        <ControlButton label="Sleep" onPress={onSoftDisconnect} />
        <ControlButton label="Wake" onPress={onReconnect} />
      </View>

      <View style={styles.customResolutionRow}>
        <TextInput
          accessibilityLabel="Custom resolution width"
          onChangeText={setCustomWidth}
          style={styles.customResolutionInput}
          value={customWidth}
        />
        <TextInput
          accessibilityLabel="Custom resolution height"
          onChangeText={setCustomHeight}
          style={styles.customResolutionInput}
          value={customHeight}
        />
        <TextInput
          accessibilityLabel="Custom resolution refresh rate"
          onChangeText={setCustomRefreshRate}
          style={styles.customResolutionInput}
          value={customRefreshRate}
        />
        <Pressable
          accessibilityRole="button"
          onPress={() => onAddCustomResolution(customResolutionDraft)}
          style={({ pressed }) => [
            styles.customResolutionQueueButton,
            pressed && styles.dimmingButtonPressed,
          ]}
        >
          <Text style={styles.dimmingButtonText}>Queue</Text>
        </Pressable>
      </View>
      <Text style={styles.advancedPathText}>
        Custom: {customResolutionDraft.width} x {customResolutionDraft.height} @{' '}
        {customResolutionDraft.refreshRate}Hz /{' '}
        {customResolutionDraft.isHiDpi ? 'HiDPI' : '1x'}
      </Text>

      {display.advanced.edidExportPath ? (
        <Text style={styles.advancedPathText}>
          {display.advanced.edidExportPath}
        </Text>
      ) : null}

      <Text style={styles.advancedPathText}>
        EDID override: {display.advanced.edidOverrideStatus}
      </Text>
      <Text style={styles.advancedPathText}>
        Override bundle: {display.advanced.overrideBundleStatus}
      </Text>
      {display.advanced.overrideBundlePath ? (
        <Text style={styles.advancedPathText}>
          {display.advanced.overrideBundlePath}
        </Text>
      ) : null}
      <Text style={styles.advancedPathText}>
        Rotation: {display.advanced.rotationStatus}
      </Text>
      {display.advanced.lastOperation ? (
        <Text style={styles.advancedPathText}>
          Last: {display.advanced.lastOperation}
          {display.advanced.lastOperationAt
            ? ` / ${display.advanced.lastOperationAt}`
            : ''}
        </Text>
      ) : null}

      {display.advanced.customResolutions.length > 0 ? (
        <View style={styles.presetList}>
          {display.advanced.customResolutions.map((request) => (
            <View key={request.id} style={styles.presetRow}>
              <View style={styles.presetTextBlock}>
                <Text style={styles.presetName}>
                  {request.width} x {request.height}
                </Text>
                <Text style={styles.presetMeta}>{request.status}</Text>
              </View>
              <Pressable
                accessibilityRole="button"
                onPress={() => onRemoveCustomResolution(request.id)}
                style={({ pressed }) => [
                  styles.presetActionButton,
                  pressed && styles.dimmingButtonPressed,
                ]}
              >
                <Text style={styles.dimmingButtonText}>Remove</Text>
              </Pressable>
            </View>
          ))}
        </View>
      ) : null}
    </View>
  );
}

function positiveNumberFromInput(value: string, fallback: number) {
  const parsed = Number(value.replace(/[^0-9.]/g, ''));

  if (!Number.isFinite(parsed) || parsed <= 0) {
    return Math.max(fallback, 1);
  }

  return parsed;
}

function ColorControls({
  display,
  onReset,
  onSelect,
}: {
  display: DisplayControlDisplay;
  onReset: () => void;
  onSelect: (profileID: string) => void;
}) {
  const currentProfile = display.colorProfiles.find(
    (profile) => profile.isCurrent,
  );

  return (
    <View style={styles.colorBlock}>
      <View style={styles.dimmingHeader}>
        <Text style={styles.dimmingLabel}>Color and HDR</Text>
        <Text style={styles.dimmingValue}>
          {display.colorProfileStatus} /{' '}
          {display.hdr.isSupported ? 'HDR capable' : 'SDR only'}
        </Text>
      </View>

      <View style={styles.hdrGrid}>
        <Metric
          label="HDR"
          value={display.hdr.isActive ? 'Active' : 'Inactive'}
        />
        <Metric
          label="Headroom"
          value={`${display.hdr.currentHeadroom.toFixed(1)} / ${display.hdr.potentialHeadroom.toFixed(1)}`}
        />
        <Metric label="XDR" value={display.hdr.xdrPreset} />
      </View>

      <View style={styles.colorProfileHeader}>
        <View style={styles.presetTextBlock}>
          <Text style={styles.presetName}>
            {currentProfile?.name ?? 'No profile detected'}
          </Text>
          <Text style={styles.presetMeta}>
            {display.colorProfiles.length} profiles
          </Text>
          {display.colorProfileError ? (
            <Text style={styles.ddcErrorText}>{display.colorProfileError}</Text>
          ) : null}
        </View>
        <Pressable
          accessibilityRole="button"
          onPress={onReset}
          style={({ pressed }) => [
            styles.presetActionButton,
            pressed && styles.dimmingButtonPressed,
          ]}
        >
          <Text style={styles.dimmingButtonText}>Reset</Text>
        </Pressable>
      </View>

      {display.colorProfiles.length > 0 ? (
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          {display.colorProfiles.map((profile) => (
            <ProfileButton
              key={profile.id}
              onSelect={onSelect}
              profile={profile}
            />
          ))}
        </ScrollView>
      ) : (
        <Text style={styles.ddcUnavailableText}>
          ColorSync profiles not reported for this display.
        </Text>
      )}
    </View>
  );
}

function ProfileButton({
  profile,
  onSelect,
}: {
  profile: DisplayControlColorProfile;
  onSelect: (profileID: string) => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={() => onSelect(profile.id)}
      style={({ pressed }) => [
        styles.profileButton,
        profile.isCurrent && styles.dimmingButtonSelected,
        pressed && styles.dimmingButtonPressed,
      ]}
    >
      <Text
        style={[
          styles.modeButtonText,
          profile.isCurrent && styles.dimmingButtonTextSelected,
        ]}
      >
        {profile.name}
      </Text>
      <Text
        style={[
          styles.profileButtonMeta,
          profile.isCurrent && styles.dimmingButtonTextSelected,
        ]}
      >
        {profile.isFactory ? 'Factory' : 'Custom'}
      </Text>
    </Pressable>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.metric}>
      <Text style={styles.metricLabel}>{label}</Text>
      <Text style={styles.metricValue}>{value}</Text>
    </View>
  );
}

function ArrangementControls({
  display,
  onChange,
}: {
  display: DisplayControlDisplay;
  onChange: (x: number, y: number) => void;
}) {
  const step = 100;
  const moves = [
    { label: 'Up', x: display.frame.x, y: display.frame.y - step },
    { label: 'Left', x: display.frame.x - step, y: display.frame.y },
    { label: 'Right', x: display.frame.x + step, y: display.frame.y },
    { label: 'Down', x: display.frame.x, y: display.frame.y + step },
  ];

  return (
    <View style={styles.arrangementBlock}>
      <View style={styles.dimmingHeader}>
        <Text style={styles.dimmingLabel}>Arrangement</Text>
        <Text style={styles.dimmingValue}>
          {Math.round(display.frame.x)}, {Math.round(display.frame.y)}
        </Text>
      </View>
      <View style={styles.dimmingButtons}>
        {moves.map((move) => (
          <Pressable
            accessibilityRole="button"
            key={move.label}
            onPress={() => onChange(move.x, move.y)}
            style={({ pressed }) => [
              styles.dimmingButton,
              pressed && styles.dimmingButtonPressed,
            ]}
          >
            <Text style={styles.dimmingButtonText}>{move.label}</Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}

function ModeControls({
  display,
  onChange,
  onFavorite,
  onRemoveFavorite,
}: {
  display: DisplayControlDisplay;
  onChange: (modeID: string) => void;
  onFavorite: (modeID: string) => void;
  onRemoveFavorite: (modeID: string) => void;
}) {
  const favoriteCount = display.availableModes.filter(
    (mode) => mode.isFavorite,
  ).length;

  return (
    <View style={styles.modeBlock}>
      <View style={styles.dimmingHeader}>
        <Text style={styles.dimmingLabel}>Resolution and refresh</Text>
        <Text style={styles.dimmingValue}>
          {modeCompactLabel(display.currentMode)} / {favoriteCount} fav /{' '}
          {display.modeStatus}
        </Text>
      </View>
      {display.modeError ? (
        <Text style={styles.ddcErrorText}>{display.modeError}</Text>
      ) : null}

      {display.availableModes.length > 0 ? (
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          {display.availableModes.map((mode) => (
            <View key={mode.id} style={styles.modeOption}>
              <Pressable
                accessibilityRole="button"
                onPress={() => onChange(mode.id)}
                style={({ pressed }) => [
                  styles.modeButton,
                  mode.isCurrent && styles.dimmingButtonSelected,
                  pressed && styles.dimmingButtonPressed,
                ]}
              >
                <Text
                  style={[
                    styles.modeButtonText,
                    mode.isCurrent && styles.dimmingButtonTextSelected,
                  ]}
                >
                  {modeButtonLabel(mode)}
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
                  styles.favoriteButton,
                  mode.isFavorite && styles.favoriteButtonSelected,
                  pressed && styles.dimmingButtonPressed,
                ]}
              >
                <Text
                  style={[
                    styles.favoriteButtonText,
                    mode.isFavorite && styles.dimmingButtonTextSelected,
                  ]}
                >
                  {mode.isFavorite ? 'Saved' : 'Save'}
                </Text>
              </Pressable>
            </View>
          ))}
        </ScrollView>
      ) : (
        <Text style={styles.ddcUnavailableText}>No alternate modes found.</Text>
      )}
    </View>
  );
}

function modeButtonLabel(mode: DisplayControlMode) {
  const refreshRate =
    mode.refreshRate > 0 ? `${Math.round(mode.refreshRate)}Hz` : 'Default Hz';

  return `${mode.width} x ${mode.height}\n${refreshRate}${mode.isHiDpi ? ' / HiDPI' : ''}`;
}

function modeCompactLabel(mode: DisplayControlMode) {
  const refreshRate =
    mode.refreshRate > 0 ? `${Math.round(mode.refreshRate)}Hz` : 'Default';

  return `${mode.width} x ${mode.height} / ${refreshRate}`;
}

function Capability({ label, enabled }: { label: string; enabled: boolean }) {
  return (
    <View style={[styles.capability, enabled && styles.capabilityEnabled]}>
      <Text
        style={[styles.capabilityText, enabled && styles.capabilityTextEnabled]}
      >
        {label}
      </Text>
    </View>
  );
}

function BrightnessControls({
  display,
  onChange,
}: {
  display: DisplayControlDisplay;
  onChange: (level: number) => void;
}) {
  const levels = [0.25, 0.5, 0.75, 1];
  const isNative = display.brightnessControl === 'native';

  return (
    <View style={styles.dimmingBlock}>
      <View style={styles.dimmingHeader}>
        <Text style={styles.dimmingLabel}>Native brightness</Text>
        <Text style={styles.dimmingValue}>
          {isNative
            ? `${Math.round(display.nativeBrightness * 100)}%`
            : display.brightnessControl === 'ddc'
              ? 'Use DDC'
              : 'Unavailable'}
        </Text>
      </View>

      {isNative ? (
        <View style={styles.dimmingButtons}>
          {levels.map((option) => {
            const selected = Math.abs(display.nativeBrightness - option) < 0.02;

            return (
              <Pressable
                accessibilityRole="button"
                key={option}
                onPress={() => onChange(option)}
                style={({ pressed }) => [
                  styles.dimmingButton,
                  selected && styles.dimmingButtonSelected,
                  pressed && styles.dimmingButtonPressed,
                ]}
              >
                <Text
                  style={[
                    styles.dimmingButtonText,
                    selected && styles.dimmingButtonTextSelected,
                  ]}
                >
                  {Math.round(option * 100)}
                </Text>
              </Pressable>
            );
          })}
        </View>
      ) : (
        <Text style={styles.ddcUnavailableText}>
          {display.brightnessControl === 'ddc'
            ? 'This display exposes brightness through DDC controls.'
            : 'No native brightness control reported by IOKit.'}
        </Text>
      )}

      {display.brightnessError ? (
        <Text style={styles.ddcErrorText}>{display.brightnessError}</Text>
      ) : null}
    </View>
  );
}

function DimmingControls({
  level,
  onChange,
}: {
  level: number;
  onChange: (level: number) => void;
}) {
  const levels = [0, 0.25, 0.5, 0.8];

  return (
    <View style={styles.dimmingBlock}>
      <View style={styles.dimmingHeader}>
        <Text style={styles.dimmingLabel}>Software dimming</Text>
        <Text style={styles.dimmingValue}>{Math.round(level * 100)}%</Text>
      </View>
      <View style={styles.dimmingButtons}>
        {levels.map((option) => {
          const selected = Math.abs(level - option) < 0.01;

          return (
            <Pressable
              accessibilityRole="button"
              key={option}
              onPress={() => onChange(option)}
              style={({ pressed }) => [
                styles.dimmingButton,
                selected && styles.dimmingButtonSelected,
                pressed && styles.dimmingButtonPressed,
              ]}
            >
              <Text
                style={[
                  styles.dimmingButtonText,
                  selected && styles.dimmingButtonTextSelected,
                ]}
              >
                {Math.round(option * 100)}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

type DdcOption = {
  label: string;
  value: number;
};

function DdcControls({
  display,
  onChange,
}: {
  display: DisplayControlDisplay;
  onChange: (controlCode: number, value: number) => void;
}) {
  const groups = [
    {
      label: 'Brightness',
      code: 0x10,
      value: display.ddc.brightness,
      options: percentageOptions,
    },
    {
      label: 'Contrast',
      code: 0x12,
      value: display.ddc.contrast,
      options: percentageOptions,
    },
    {
      label: 'Volume',
      code: 0x62,
      value: display.ddc.volume,
      options: volumeOptions,
    },
    {
      label: 'Input',
      code: 0x60,
      value: display.ddc.inputSource,
      options: inputOptions,
    },
  ];

  return (
    <View style={styles.ddcBlock}>
      <View style={styles.dimmingHeader}>
        <Text style={styles.dimmingLabel}>DDC hardware</Text>
        <Text style={styles.dimmingValue}>
          {display.supportsDdc ? display.ddc.readStatus : 'Unavailable'}
        </Text>
      </View>

      {display.supportsDdc ? (
        groups.map((group) => (
          <View key={group.code} style={styles.ddcGroup}>
            <Text style={styles.ddcGroupLabel}>
              {group.label}
              {group.code === 0x60 ? ` ${formatDdcHex(group.value)}` : ''}
            </Text>
            {group.code === 0x60 ? (
              <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                <View style={styles.ddcButtonsScrollable}>
                  {group.options.map((option: DdcOption) => {
                    const selected = Math.round(group.value) === option.value;

                    return (
                      <DdcButton
                        key={option.value}
                        option={option}
                        selected={selected}
                        onPress={() => onChange(group.code, option.value)}
                        compact
                      />
                    );
                  })}
                </View>
              </ScrollView>
            ) : (
              <View style={styles.ddcButtons}>
                {group.options.map((option: DdcOption) => {
                  const selected = Math.round(group.value) === option.value;

                  return (
                    <DdcButton
                      key={option.value}
                      option={option}
                      selected={selected}
                      onPress={() => onChange(group.code, option.value)}
                    />
                  );
                })}
              </View>
            )}
          </View>
        ))
      ) : (
        <Text style={styles.ddcUnavailableText}>
          External monitor DDC bus not detected.
        </Text>
      )}

      {display.ddc.lastError ? (
        <Text style={styles.ddcErrorText}>{display.ddc.lastError}</Text>
      ) : null}
    </View>
  );
}

function DdcButton({
  compact,
  onPress,
  option,
  selected,
}: {
  compact?: boolean;
  onPress: () => void;
  option: DdcOption;
  selected: boolean;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [
        styles.ddcButton,
        compact && styles.ddcButtonCompact,
        selected && styles.dimmingButtonSelected,
        pressed && styles.dimmingButtonPressed,
      ]}
    >
      <Text
        style={[
          styles.dimmingButtonText,
          selected && styles.dimmingButtonTextSelected,
        ]}
      >
        {option.label}
      </Text>
    </Pressable>
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
        styles.syncActionButton,
        selected && styles.dimmingButtonSelected,
        pressed && styles.dimmingButtonPressed,
      ]}
    >
      <Text
        style={[
          styles.dimmingButtonText,
          selected && styles.dimmingButtonTextSelected,
        ]}
      >
        {label}
      </Text>
    </Pressable>
  );
}

function formatDdcHex(value: number) {
  return `0x${Math.round(value).toString(16).toUpperCase().padStart(2, '0')}`;
}

const percentageOptions: Array<DdcOption> = [
  { label: '25', value: 25 },
  { label: '50', value: 50 },
  { label: '75', value: 75 },
  { label: '100', value: 100 },
];

const volumeOptions: Array<DdcOption> = [
  { label: '0', value: 0 },
  { label: '25', value: 25 },
  { label: '50', value: 50 },
  { label: '75', value: 75 },
];

const inputOptions: Array<DdcOption> = [
  { label: 'VGA', value: 1 },
  { label: 'DVI', value: 3 },
  { label: 'DP1', value: 15 },
  { label: 'DP2', value: 16 },
  { label: 'HDMI1', value: 17 },
  { label: 'HDMI2', value: 18 },
  { label: 'USB-C', value: 27 },
];

const styles = StyleSheet.create({
  displayList: {
    paddingTop: 16,
  },
  displayCard: {
    backgroundColor: '#15181e',
    borderColor: 'rgba(178,182,189,0.1)',
    borderRadius: 8,
    borderWidth: 1,
    marginBottom: 12,
    padding: 16,
  },
  displayHeader: {
    alignItems: 'flex-start',
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  displayNameBlock: {
    flex: 1,
    paddingRight: 12,
  },
  displayName: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 16,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 24,
  },
  displayMeta: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '500',
    letterSpacing: 0.2,
    lineHeight: 18,
    marginTop: 4,
  },
  onlineDot: {
    borderRadius: 9999,
    height: 10,
    marginTop: 7,
    width: 10,
  },
  onlineDotOn: {
    backgroundColor: '#00ca8e',
  },
  onlineDotOff: {
    backgroundColor: '#656a76',
  },
  modeGrid: {
    flexDirection: 'row',
    marginTop: 16,
  },
  metric: {
    flex: 1,
    marginRight: 8,
  },
  metricLabel: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0.6,
    lineHeight: 15,
    marginBottom: 4,
    textTransform: 'uppercase',
  },
  metricValue: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 14,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 18,
  },
  capabilityRow: {
    flexDirection: 'row',
    marginTop: 16,
  },
  capability: {
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 9999,
    borderWidth: 1,
    marginRight: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  capabilityEnabled: {
    borderColor: '#00ca8e',
  },
  capabilityText: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 15,
  },
  capabilityTextEnabled: {
    color: '#00ca8e',
  },
  modeBlock: {
    borderTopColor: 'rgba(178,182,189,0.1)',
    borderTopWidth: 1,
    marginTop: 16,
    paddingTop: 16,
  },
  modeOption: {
    marginRight: 8,
    width: 140,
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
  modeButtonText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 16,
  },
  favoriteButton: {
    alignItems: 'center',
    backgroundColor: '#15181e',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    justifyContent: 'center',
    marginTop: 6,
    minHeight: 30,
  },
  favoriteButtonSelected: {
    backgroundColor: '#00ca8e',
    borderColor: '#00ca8e',
  },
  favoriteButtonText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 15,
  },
  arrangementBlock: {
    borderTopColor: 'rgba(178,182,189,0.1)',
    borderTopWidth: 1,
    marginTop: 16,
    paddingTop: 16,
  },
  dimmingBlock: {
    borderTopColor: 'rgba(178,182,189,0.1)',
    borderTopWidth: 1,
    marginTop: 16,
    paddingTop: 16,
  },
  dimmingHeader: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  dimmingLabel: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    letterSpacing: 0.2,
    lineHeight: 18,
  },
  dimmingValue: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    letterSpacing: 0.2,
    lineHeight: 18,
  },
  dimmingButtons: {
    flexDirection: 'row',
  },
  dimmingButton: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    flex: 1,
    justifyContent: 'center',
    marginRight: 8,
    minHeight: 36,
  },
  dimmingButtonPressed: {
    backgroundColor: '#3b3d45',
  },
  dimmingButtonSelected: {
    backgroundColor: '#2b89ff',
    borderColor: '#2b89ff',
  },
  dimmingButtonText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 18,
  },
  dimmingButtonTextSelected: {
    color: '#ffffff',
  },
  colorBlock: {
    borderTopColor: 'rgba(178,182,189,0.1)',
    borderTopWidth: 1,
    marginTop: 16,
    paddingTop: 16,
  },
  hdrGrid: {
    flexDirection: 'row',
    marginBottom: 12,
  },
  colorProfileHeader: {
    alignItems: 'center',
    flexDirection: 'row',
    marginBottom: 10,
  },
  presetList: {
    marginTop: 12,
  },
  presetRow: {
    alignItems: 'center',
    flexDirection: 'row',
    marginTop: 8,
  },
  presetTextBlock: {
    flex: 1,
    paddingRight: 8,
  },
  presetName: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 18,
  },
  presetMeta: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '500',
    letterSpacing: 0,
    lineHeight: 16,
  },
  presetActionButton: {
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
  profileButton: {
    alignItems: 'flex-start',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    justifyContent: 'center',
    marginRight: 8,
    minHeight: 52,
    paddingHorizontal: 10,
    paddingVertical: 8,
    width: 150,
  },
  profileButtonMeta: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 11,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 14,
    marginTop: 4,
  },
  ddcBlock: {
    borderTopColor: 'rgba(178,182,189,0.1)',
    borderTopWidth: 1,
    marginTop: 16,
    paddingTop: 16,
  },
  ddcGroup: {
    marginBottom: 12,
  },
  ddcGroupLabel: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0.6,
    lineHeight: 15,
    marginBottom: 8,
    textTransform: 'uppercase',
  },
  ddcButtons: {
    flexDirection: 'row',
  },
  ddcButtonsScrollable: {
    flexDirection: 'row',
    paddingRight: 8,
  },
  ddcButton: {
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
  ddcButtonCompact: {
    flex: 0,
    minWidth: 68,
    paddingHorizontal: 10,
  },
  ddcUnavailableText: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '500',
    letterSpacing: 0.2,
    lineHeight: 18,
  },
  ddcErrorText: {
    color: '#ffb4ad',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 16,
    marginTop: 4,
  },
  advancedBlock: {
    borderTopColor: 'rgba(178,182,189,0.1)',
    borderTopWidth: 1,
    marginTop: 16,
    paddingTop: 16,
  },
  syncActions: {
    flexDirection: 'row',
    marginTop: 10,
  },
  syncActionButton: {
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
  advancedPathText: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 11,
    fontWeight: '500',
    letterSpacing: 0,
    lineHeight: 15,
    marginTop: 8,
  },
  customResolutionRow: {
    flexDirection: 'row',
    marginTop: 10,
  },
  customResolutionInput: {
    backgroundColor: '#15181e',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    color: '#ffffff',
    flex: 1,
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 16,
    marginRight: 8,
    minHeight: 34,
    paddingHorizontal: 8,
    paddingVertical: 6,
  },
  customResolutionQueueButton: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    justifyContent: 'center',
    minHeight: 34,
    minWidth: 62,
    paddingHorizontal: 10,
  },
});
