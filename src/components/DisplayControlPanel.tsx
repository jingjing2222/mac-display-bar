import { useEffect, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

import type {
  DisplayControlColorProfile,
  DisplayControlDisplay,
} from '../../specs/NativeDisplayControl';
import type { useDisplayControl } from '../hooks/display/useDisplayControl';
import { useDisplayTabs } from '../hooks/display/useDisplayTabs';
import type { TranslationKey } from '../i18n/strings';
import { ControlSlider } from './ControlSlider';
import { Icon, type IconName } from './Icon';
import { modeLabel, ResolutionPicker } from './ResolutionPicker';
import { SegmentedTabs } from './SegmentedTabs';
import { StableLegendList } from './StableLegendList';

const font = {
  family: 'Inter',
} as const;

type DisplayControlState = ReturnType<typeof useDisplayControl>;
type DisplayActions = DisplayControlState['actions'];

export function DisplayControlPanel({
  control,
  display,
  t,
}: {
  control: DisplayControlState;
  display: DisplayControlDisplay | null;
  t: (key: TranslationKey) => string;
}) {
  const { activeTab, setActiveTab, tabs } = useDisplayTabs();

  if (!display) {
    return null;
  }

  return (
    <View>
      <View style={styles.sectionTitleRow}>
        <Icon color="#2b89ff" name="sliders" size={16} />
        <Text style={styles.sectionTitle}>{t('quickAdjust')}</Text>
      </View>
      <QuickControls actions={control.actions} display={display} t={t} />
      <SegmentedTabs
        activeTab={activeTab}
        onChange={setActiveTab}
        t={t}
        tabs={tabs}
      />
      {activeTab === 'display' ? (
        <DisplayPanel actions={control.actions} display={display} t={t} />
      ) : null}
      {activeTab === 'color' ? (
        <ColorPanel actions={control.actions} display={display} t={t} />
      ) : null}
      {activeTab === 'arrange' ? (
        <ArrangementPanel
          actions={control.actions}
          display={display}
          displayCount={control.snapshot.displays.length}
          t={t}
        />
      ) : null}
      {activeTab === 'input' ? (
        <InputPanel actions={control.actions} display={display} t={t} />
      ) : null}
      {activeTab === 'advanced' ? (
        <AdvancedDisplayPanel control={control} display={display} t={t} />
      ) : null}
    </View>
  );
}

function QuickControls({
  actions,
  display,
  t,
}: {
  actions: DisplayActions;
  display: DisplayControlDisplay;
  t: (key: TranslationKey) => string;
}) {
  const brightnessValue =
    display.brightnessControl === 'native'
      ? display.nativeBrightness
      : display.supportsDdc
        ? display.ddc.brightness / 100
        : 0;

  return (
    <View>
      {display.supportsBrightness || display.supportsDdc ? (
        <ControlSlider
          label={t('brightness')}
          onChange={(value) =>
            display.brightnessControl === 'native'
              ? actions.setNativeBrightness(display.id, value)
              : actions.setDdcControl(display.id, 0x10, Math.round(value * 100))
          }
          presets={[0.25, 0.5, 0.75, 1]}
          value={brightnessValue}
        />
      ) : (
        <Notice text={t('noNativeBrightness')} />
      )}
      {display.supportsSoftwareDimming ? (
        <ControlSlider
          label={t('dimming')}
          onChange={(value) => actions.setSoftwareDimming(display.id, value)}
          presets={[0, 0.25, 0.5, 0.8]}
          value={display.softwareDimming}
        />
      ) : null}
      <ResolutionPicker
        display={display}
        onFavorite={(modeID) => actions.saveFavoriteMode(display.id, modeID)}
        onRemoveFavorite={(modeID) =>
          actions.removeFavoriteMode(display.id, modeID)
        }
        onSelect={(modeID) => actions.setDisplayMode(display.id, modeID)}
        t={t}
      />
    </View>
  );
}

function DisplayPanel({
  actions,
  display,
  t,
}: {
  actions: DisplayActions;
  display: DisplayControlDisplay;
  t: (key: TranslationKey) => string;
}) {
  return (
    <View style={styles.panel}>
      <Metric
        label={t('resolution')}
        value={modeLabel(display.currentMode, t)}
      />
      <Metric
        label={t('refreshRate')}
        value={`${display.currentMode.refreshRate}Hz`}
      />
      <Metric label={t('connection')} value={connectionLabel(display, t)} />
      {display.brightnessError ? (
        <Notice text={display.brightnessError} />
      ) : null}
      <ActionRow>
        <ActionButton
          icon="refresh"
          label={t('refreshNow')}
          onPress={actions.refreshSnapshot}
        />
      </ActionRow>
    </View>
  );
}

function ColorPanel({
  actions,
  display,
  t,
}: {
  actions: DisplayActions;
  display: DisplayControlDisplay;
  t: (key: TranslationKey) => string;
}) {
  const currentProfile = display.colorProfiles.find(
    (profile) => profile.isCurrent,
  );

  return (
    <View style={styles.panel}>
      <Metric
        label={t('colorHdr')}
        value={display.hdr.isActive ? t('hdrOn') : t('hdrOff')}
      />
      <Metric
        label={t('xdrHeadroom')}
        value={`${display.hdr.currentHeadroom.toFixed(1)} / ${display.hdr.potentialHeadroom.toFixed(1)}`}
      />
      <View style={styles.itemHeader}>
        <View style={styles.itemTextBlock}>
          <Text style={styles.itemTitle}>
            {currentProfile?.name ?? t('noColorProfile')}
          </Text>
          <Text style={styles.itemMeta}>
            {display.colorProfiles.length} {t('colorProfile')}
          </Text>
        </View>
        <ActionButton
          icon="refresh"
          label={t('reset')}
          onPress={() => actions.resetColorProfile(display.id)}
          small
        />
      </View>
      {display.colorProfiles.length > 0 ? (
        <StableLegendList
          data={display.colorProfiles}
          estimatedItemSize={132}
          horizontal
          keyExtractor={(profile) => profile.id}
          renderItem={({ item: profile }) => (
            <ProfileChip
              onSelect={(profileID) =>
                actions.setColorProfile(display.id, profileID)
              }
              profile={profile}
            />
          )}
          showsHorizontalScrollIndicator={false}
          style={styles.horizontalList}
        />
      ) : (
        <Notice text={t('noColorProfiles')} />
      )}
      {display.colorProfileError ? (
        <Notice text={display.colorProfileError} />
      ) : null}
    </View>
  );
}

function ArrangementPanel({
  actions,
  display,
  displayCount,
  t,
}: {
  actions: DisplayActions;
  display: DisplayControlDisplay;
  displayCount: number;
  t: (key: TranslationKey) => string;
}) {
  const step = 100;
  const canMoveDisplay = displayCount > 1;
  const moves = [
    { label: t('moveUp'), x: display.frame.x, y: display.frame.y - step },
    { label: t('moveLeft'), x: display.frame.x - step, y: display.frame.y },
    { label: t('moveRight'), x: display.frame.x + step, y: display.frame.y },
    { label: t('moveDown'), x: display.frame.x, y: display.frame.y + step },
  ];

  return (
    <View style={styles.panel}>
      <Metric
        label={t('arrangement')}
        value={`${Math.round(display.frame.x)}, ${Math.round(display.frame.y)}`}
      />
      {!canMoveDisplay ? <Notice text={t('arrangementMultipleOnly')} /> : null}
      <ActionRow>
        {moves.map((move) => (
          <ActionButton
            disabled={!canMoveDisplay}
            key={move.label}
            icon="layout"
            label={move.label}
            onPress={() => actions.setDisplayOrigin(display.id, move.x, move.y)}
          />
        ))}
      </ActionRow>
      <ActionRow>
        {[0, 90, 180, 270].map((rotation) => (
          <ActionButton
            key={rotation}
            icon="refresh"
            label={`${rotation}`}
            onPress={() => actions.setDisplayRotation(display.id, rotation)}
            selected={Math.round(display.rotation) === rotation}
          />
        ))}
      </ActionRow>
    </View>
  );
}

function InputPanel({
  actions,
  display,
  t,
}: {
  actions: DisplayActions;
  display: DisplayControlDisplay;
  t: (key: TranslationKey) => string;
}) {
  if (!display.supportsDdc) {
    return (
      <View style={styles.panel}>
        <Notice text={t('noDdc')} />
      </View>
    );
  }

  return (
    <View style={styles.panel}>
      <ControlSlider
        label={t('contrast')}
        onChange={(value) =>
          actions.setDdcControl(display.id, 0x12, Math.round(value * 100))
        }
        presets={[0.25, 0.5, 0.75, 1]}
        value={display.ddc.contrast / 100}
      />
      <ControlSlider
        label={t('volume')}
        onChange={(value) =>
          actions.setDdcControl(display.id, 0x62, Math.round(value * 100))
        }
        presets={[0, 0.25, 0.5, 0.75]}
        value={display.ddc.volume / 100}
      />
      <Text style={styles.itemTitle}>{t('inputSource')}</Text>
      <StableLegendList
        data={inputOptions}
        estimatedItemSize={82}
        horizontal
        keyExtractor={(option) => `${option.value}`}
        renderItem={({ item: option }) => (
          <ActionButton
            icon="plug"
            label={option.label}
            onPress={() =>
              actions.setDdcControl(display.id, 0x60, option.value)
            }
            selected={Math.round(display.ddc.inputSource) === option.value}
            small
          />
        )}
        showsHorizontalScrollIndicator={false}
        style={styles.horizontalList}
      />
      {display.ddc.lastError ? <Notice text={display.ddc.lastError} /> : null}
    </View>
  );
}

function AdvancedDisplayPanel({
  control,
  display,
  t,
}: {
  control: DisplayControlState;
  display: DisplayControlDisplay;
  t: (key: TranslationKey) => string;
}) {
  const actions = control.actions;
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
  const panelDraft = useMemo(
    () => ({
      height: `${
        display.advanced.nativePanelOverrideHeight ||
        display.advanced.nativePanelHeight ||
        display.currentMode.height
      }`,
      width: `${
        display.advanced.nativePanelOverrideWidth ||
        display.advanced.nativePanelWidth ||
        display.currentMode.width
      }`,
    }),
    [
      display.advanced.nativePanelHeight,
      display.advanced.nativePanelOverrideHeight,
      display.advanced.nativePanelOverrideWidth,
      display.advanced.nativePanelWidth,
      display.currentMode.height,
      display.currentMode.width,
    ],
  );
  const [customWidth, setCustomWidth] = useState(modeDraft.width);
  const [customHeight, setCustomHeight] = useState(modeDraft.height);
  const [customRefreshRate, setCustomRefreshRate] = useState(
    modeDraft.refreshRate,
  );
  const [customIsHiDpi, setCustomIsHiDpi] = useState(true);
  const [panelWidth, setPanelWidth] = useState(panelDraft.width);
  const [panelHeight, setPanelHeight] = useState(panelDraft.height);
  const [virtualWidth, setVirtualWidth] = useState(modeDraft.width);
  const [virtualHeight, setVirtualHeight] = useState(modeDraft.height);
  const [virtualRefreshRate, setVirtualRefreshRate] = useState(
    modeDraft.refreshRate,
  );
  const [virtualIsHiDpi, setVirtualIsHiDpi] = useState(true);

  useEffect(() => {
    setCustomWidth(modeDraft.width);
    setCustomHeight(modeDraft.height);
    setCustomRefreshRate(modeDraft.refreshRate);
    setVirtualWidth(modeDraft.width);
    setVirtualHeight(modeDraft.height);
    setVirtualRefreshRate(modeDraft.refreshRate);
  }, [display.id, modeDraft.height, modeDraft.refreshRate, modeDraft.width]);

  useEffect(() => {
    setPanelWidth(panelDraft.width);
    setPanelHeight(panelDraft.height);
  }, [display.id, panelDraft.height, panelDraft.width]);

  const customResolutionDraft = {
    height: positiveNumberFromInput(customHeight, display.currentMode.height),
    isHiDpi: customIsHiDpi,
    refreshRate: positiveNumberFromInput(
      customRefreshRate,
      display.currentMode.refreshRate || 60,
    ),
    width: positiveNumberFromInput(customWidth, display.currentMode.width),
  };
  const panelResolutionDraft = {
    height: positiveNumberFromInput(
      panelHeight,
      display.advanced.nativePanelHeight || display.currentMode.height,
    ),
    width: positiveNumberFromInput(
      panelWidth,
      display.advanced.nativePanelWidth || display.currentMode.width,
    ),
  };
  const virtualDisplayDraft = {
    height: positiveNumberFromInput(virtualHeight, display.currentMode.height),
    isHiDpi: virtualIsHiDpi,
    refreshRate: positiveNumberFromInput(
      virtualRefreshRate,
      display.currentMode.refreshRate || 60,
    ),
    width: positiveNumberFromInput(virtualWidth, display.currentMode.width),
  };
  const flexibleScalingIsActive = display.advanced.flexibleScalingEnabled;
  const displayIdentityKeys = new Set(
    [
      display.identity.uuid,
      `${display.identity.vendorID}:${display.identity.modelID}:${display.identity.serialNumber}`,
    ].filter((identityKey) => identityKey.length > 0),
  );
  const virtualDisplaysForSelectedDisplay =
    control.snapshot.virtualDisplays.filter(
      (virtualDisplay) =>
        virtualDisplay.targetDisplayID === display.id ||
        displayIdentityKeys.has(virtualDisplay.targetIdentityKey),
    );
  const pipWindowsForSelectedDisplay = control.snapshot.pipWindows.filter(
    (pipWindow) => pipWindow.displayID === display.id,
  );

  return (
    <View style={styles.panel}>
      <Metric
        label={t('displayInfo')}
        value={`${display.identity.productName} / ${display.identity.transport}`}
      />
      <Text style={styles.rawText}>UUID {display.identity.uuid || 'n/a'}</Text>
      <Text style={styles.rawText}>
        Vendor {display.identity.vendorID} / Model {display.identity.modelID} /
        Serial {display.identity.serialNumber || 'n/a'}
      </Text>
      <Text style={styles.itemTitle}>{t('displayInfo')}</Text>
      <ActionRow>
        <ActionButton
          icon="download"
          label={t('exportInfo')}
          onPress={() => actions.exportEdid(display.id)}
        />
      </ActionRow>
      <Text style={styles.itemTitle}>{t('compatibilitySettings')}</Text>
      {display.advanced.overrideBundleStatus !== 'No bundle' ? (
        <Notice
          text={`${display.advanced.overrideBundleStatus}${
            display.advanced.overridePendingReboot ? ` / ${t('pcRestart')}` : ''
          }${
            display.advanced.overrideLastError
              ? ` / ${display.advanced.overrideLastError}`
              : ''
          }`}
        />
      ) : null}
      <ActionRow>
        <ActionButton
          icon="settings"
          label={t('prepareSettings')}
          onPress={() => actions.queueEdidOverride(display.id)}
        />
        <ActionButton
          icon="settings"
          label={t('clearSettings')}
          onPress={() => actions.clearEdidOverride(display.id)}
        />
      </ActionRow>
      <ActionRow>
        <ActionButton
          icon="settings"
          label={t('installSettings')}
          onPress={() => actions.installDisplayOverride(display.id)}
        />
        <ActionButton
          icon="settings"
          label={t('removeSettings')}
          onPress={() => actions.removeDisplayOverride(display.id)}
        />
        <ActionButton
          disabled={!display.advanced.overridePendingReinitialize}
          icon="settings"
          label={t('reinitializeDisplay')}
          onPress={() => actions.reinitializeDisplay(display.id)}
        />
      </ActionRow>
      <Text style={styles.itemTitle}>{t('flexibleScaling')}</Text>
      <Text style={styles.itemMeta}>
        {display.advanced.flexibleScalingStatus} / {t('nativePanelResolution')}{' '}
        {display.advanced.nativePanelWidth} x{' '}
        {display.advanced.nativePanelHeight}
        {display.advanced.nativePanelResolutionStatus
          ? ` / ${display.advanced.nativePanelResolutionStatus}`
          : ''}
      </Text>
      <ActionRow>
        <ActionButton
          icon="sliders"
          label={t('enable')}
          onPress={() => actions.setFlexibleScalingEnabled(display.id, true)}
          selected={flexibleScalingIsActive}
        />
        <ActionButton
          icon="sliders"
          label={t('disable')}
          onPress={() => actions.setFlexibleScalingEnabled(display.id, false)}
          selected={!display.advanced.flexibleScalingEnabled}
        />
      </ActionRow>
      <View style={styles.inputRow}>
        <SmallInput
          accessibilityLabel={t('width')}
          onChangeText={setPanelWidth}
          value={panelWidth}
        />
        <SmallInput
          accessibilityLabel={t('height')}
          onChangeText={setPanelHeight}
          value={panelHeight}
        />
        <ActionButton
          icon="display"
          label={t('setPanelResolution')}
          onPress={() =>
            actions.setNativePanelResolutionOverride(
              display.id,
              panelResolutionDraft,
            )
          }
          small
        />
        <ActionButton
          icon="settings"
          label={t('clearPanelResolution')}
          onPress={() => actions.clearNativePanelResolutionOverride(display.id)}
          small
        />
      </View>
      <Text style={styles.itemTitle}>{t('settingsFile')}</Text>
      <ActionRow>
        <ActionButton
          icon="download"
          label={t('createFile')}
          onPress={() => actions.writeOverrideBundle(display.id)}
        />
      </ActionRow>
      <Text style={styles.itemTitle}>{t('extraBrightness')}</Text>
      {!display.supportsHdr ? (
        <Notice text={t('extraBrightnessUnsupported')} />
      ) : null}
      <ActionRow>
        <ActionButton
          disabled={!display.supportsHdr}
          icon="zap"
          label={t('enable')}
          onPress={() => actions.enableXdrUpscale(display.id)}
          selected={display.advanced.xdrUpscaleState === 'enabled'}
        />
        <ActionButton
          icon="zap"
          label={t('disable')}
          onPress={() => actions.disableXdrUpscale(display.id)}
          selected={display.advanced.xdrUpscaleState === 'disabled'}
        />
      </ActionRow>
      <ActionRow>
        <ActionButton
          icon="plug"
          label={t('sleep')}
          onPress={() => actions.softDisconnectDisplay(display.id)}
        />
        <ActionButton
          icon="plug"
          label={t('wake')}
          onPress={() => actions.reconnectDisplay(display.id)}
        />
      </ActionRow>

      <Text style={styles.itemTitle}>{t('virtualDisplay')}</Text>
      <View style={styles.inputRow}>
        <SmallInput
          accessibilityLabel={`${t('virtualDisplay')} ${t('width')}`}
          onChangeText={setVirtualWidth}
          value={virtualWidth}
        />
        <SmallInput
          accessibilityLabel={`${t('virtualDisplay')} ${t('height')}`}
          onChangeText={setVirtualHeight}
          value={virtualHeight}
        />
        <SmallInput
          accessibilityLabel={`${t('virtualDisplay')} ${t('hz')}`}
          onChangeText={setVirtualRefreshRate}
          value={virtualRefreshRate}
        />
        <ActionButton
          icon="sparkles"
          label={t('hidpi')}
          onPress={() => setVirtualIsHiDpi((value) => !value)}
          selected={virtualIsHiDpi}
          small
        />
      </View>
      <ActionRow>
        <ActionButton
          icon="display"
          label={t('createVirtualDisplay')}
          onPress={() =>
            actions.createVirtualDisplay(display.id, virtualDisplayDraft)
          }
        />
      </ActionRow>
      {virtualDisplaysForSelectedDisplay.length > 0 ? (
        <StableLegendList
          data={virtualDisplaysForSelectedDisplay}
          estimatedItemSize={58}
          keyExtractor={(virtualDisplay) => virtualDisplay.id}
          renderItem={({ item: virtualDisplay }) => (
            <View style={styles.itemHeader}>
              <View style={styles.itemTextBlock}>
                <Text style={styles.itemTitle}>{virtualDisplay.name}</Text>
                <Text style={styles.itemMeta}>
                  {virtualDisplay.width} x {virtualDisplay.height} /{' '}
                  {virtualDisplay.isHiDpi ? 'HiDPI' : '1x'} /{' '}
                  {virtualDisplay.status}
                  {virtualDisplay.mirrorStatus
                    ? ` / ${virtualDisplay.mirrorStatus}`
                    : ''}
                  {virtualDisplay.lastError
                    ? ` / ${virtualDisplay.lastError}`
                    : ''}
                </Text>
              </View>
              <ActionButton
                icon="display"
                label={t('mirrorVirtualDisplay')}
                onPress={() =>
                  actions.mirrorVirtualDisplayToTarget(virtualDisplay.id)
                }
                small
              />
              <ActionButton
                icon="display"
                label={t('stopVirtualMirror')}
                onPress={() =>
                  actions.stopVirtualDisplayMirroring(virtualDisplay.id)
                }
                small
              />
              <ActionButton
                icon="settings"
                label={t('removeVirtualDisplay')}
                onPress={() => actions.removeVirtualDisplay(virtualDisplay.id)}
                small
              />
            </View>
          )}
          scrollEnabled={virtualDisplaysForSelectedDisplay.length > 3}
          style={[
            styles.inlineList,
            {
              height: inlineListHeight(
                virtualDisplaysForSelectedDisplay.length,
                58,
              ),
            },
          ]}
        />
      ) : (
        <Notice text={t('noVirtualDisplays')} />
      )}

      <Text style={styles.itemTitle}>{t('pictureInPicture')}</Text>
      <ActionRow>
        <ActionButton
          icon="display"
          label={t('openPip')}
          onPress={() => actions.openDisplayPip(display.id)}
        />
      </ActionRow>
      {pipWindowsForSelectedDisplay.length > 0 ? (
        <StableLegendList
          data={pipWindowsForSelectedDisplay}
          estimatedItemSize={112}
          keyExtractor={(pipWindow) => pipWindow.id}
          renderItem={({ item: pipWindow }) => (
            <View style={styles.pipItem}>
              <View style={styles.itemHeader}>
                <View style={styles.itemTextBlock}>
                  <Text style={styles.itemTitle}>{pipWindow.name}</Text>
                  <Text style={styles.itemMeta}>
                    {Math.round(pipWindow.width)} x{' '}
                    {Math.round(pipWindow.height)} / {pipWindow.fps}fps /{' '}
                    {pipWindow.status}
                    {pipWindow.filter
                      ? ` / ${pipFilterLabel(pipWindow.filter, t)}`
                      : ''}
                    {pipWindow.lastError ? ` / ${pipWindow.lastError}` : ''}
                  </Text>
                </View>
                <ActionButton
                  icon="settings"
                  label={t('closePip')}
                  onPress={() => actions.closeDisplayPip(pipWindow.id)}
                  small
                />
              </View>
              <Text style={styles.itemMeta}>{t('videoFilter')}</Text>
              <ActionRow>
                {pipFilterOptions.map((option) => (
                  <ActionButton
                    key={option.value}
                    label={t(option.key)}
                    onPress={() =>
                      actions.setPipWindowFilter(pipWindow.id, option.value)
                    }
                    selected={pipWindow.filter === option.value}
                    small
                  />
                ))}
              </ActionRow>
            </View>
          )}
          scrollEnabled={pipWindowsForSelectedDisplay.length > 3}
          style={[
            styles.inlineList,
            {
              height: inlineListHeight(
                pipWindowsForSelectedDisplay.length,
                112,
              ),
            },
          ]}
        />
      ) : (
        <Notice text={t('noPipWindows')} />
      )}

      <Text style={styles.itemTitle}>{t('customResolution')}</Text>
      <View style={styles.inputRow}>
        <SmallInput
          accessibilityLabel={t('width')}
          onChangeText={setCustomWidth}
          value={customWidth}
        />
        <SmallInput
          accessibilityLabel={t('height')}
          onChangeText={setCustomHeight}
          value={customHeight}
        />
        <SmallInput
          accessibilityLabel={t('hz')}
          onChangeText={setCustomRefreshRate}
          value={customRefreshRate}
        />
        <ActionButton
          icon="sparkles"
          label={t('hidpi')}
          onPress={() => setCustomIsHiDpi((value) => !value)}
          selected={customIsHiDpi}
          small
        />
      </View>
      <ActionRow>
        <ActionButton
          icon="display"
          label={t('queue')}
          onPress={() =>
            actions.addCustomResolution(display, customResolutionDraft)
          }
        />
      </ActionRow>
      {display.advanced.customResolutions.length > 0 ? (
        <StableLegendList
          data={display.advanced.customResolutions}
          estimatedItemSize={58}
          keyExtractor={(request) => request.id}
          renderItem={({ item: request }) => (
            <View style={styles.itemHeader}>
              <View style={styles.itemTextBlock}>
                <Text style={styles.itemTitle}>
                  {request.width} x {request.height}
                </Text>
                <Text style={styles.itemMeta}>{request.status}</Text>
              </View>
              <ActionButton
                icon="settings"
                label={t('remove')}
                onPress={() =>
                  actions.removeCustomResolution(display.id, request.id)
                }
                small
              />
            </View>
          )}
          scrollEnabled={display.advanced.customResolutions.length > 3}
          style={[
            styles.inlineList,
            {
              height: inlineListHeight(
                display.advanced.customResolutions.length,
                58,
              ),
            },
          ]}
        />
      ) : null}
      <AutomationPanel control={control} t={t} />
    </View>
  );
}

function AutomationPanel({
  control,
  t,
}: {
  control: DisplayControlState;
  t: (key: TranslationKey) => string;
}) {
  const {
    actions,
    presetName,
    setPresetName,
    setSyncGroupName,
    snapshot,
    syncGroupName,
  } = control;

  return (
    <View style={styles.automation}>
      <Text style={styles.itemTitle}>{t('presets')}</Text>
      <View style={styles.inputRow}>
        <TextInput
          onChangeText={setPresetName}
          placeholder={t('presetName')}
          placeholderTextColor="#656a76"
          style={styles.textInput}
          value={presetName}
        />
        <ActionButton
          icon="download"
          label={t('save')}
          onPress={actions.savePreset}
          small
        />
      </View>
      {snapshot.presets.length > 0 ? (
        <StableLegendList
          data={snapshot.presets}
          estimatedItemSize={58}
          keyExtractor={(preset) => preset.name}
          renderItem={({ item: preset }) => (
            <View style={styles.itemHeader}>
              <View style={styles.itemTextBlock}>
                <Text style={styles.itemTitle}>{preset.name}</Text>
                <Text style={styles.itemMeta}>{preset.displayCount}</Text>
              </View>
              <ActionButton
                icon="check"
                label={t('apply')}
                onPress={() => actions.applyPreset(preset.name)}
                small
              />
              <ActionButton
                icon="settings"
                label={t('delete')}
                onPress={() => actions.deletePreset(preset.name)}
                small
              />
            </View>
          )}
          scrollEnabled={snapshot.presets.length > 3}
          style={[
            styles.inlineList,
            { height: inlineListHeight(snapshot.presets.length, 58) },
          ]}
        />
      ) : null}

      <Text style={styles.itemTitle}>{t('syncLayout')}</Text>
      <View style={styles.inputRow}>
        <TextInput
          onChangeText={setSyncGroupName}
          placeholder={t('groupName')}
          placeholderTextColor="#656a76"
          style={styles.textInput}
          value={syncGroupName}
        />
        <ActionButton
          icon="download"
          label={t('saveGroup')}
          onPress={actions.saveSyncGroup}
          small
        />
      </View>
      <ActionRow>
        <ActionButton
          icon="settings"
          label={t('protect')}
          onPress={actions.saveProtectedLayout}
        />
        <ActionButton
          icon="refresh"
          label={t('restore')}
          onPress={actions.restoreProtectedLayout}
        />
        <ActionButton
          icon="settings"
          label={t('clear')}
          onPress={actions.clearProtectedLayout}
        />
      </ActionRow>
      {snapshot.syncGroups.length > 0 ? (
        <StableLegendList
          data={snapshot.syncGroups}
          estimatedItemSize={58}
          keyExtractor={(group) => group.id}
          renderItem={({ item: group }) => (
            <View style={styles.itemHeader}>
              <View style={styles.itemTextBlock}>
                <Text style={styles.itemTitle}>{group.name}</Text>
                <Text style={styles.itemMeta}>{group.displayIDs.length}</Text>
              </View>
              <ActionButton
                icon="check"
                label={t('apply')}
                onPress={() => actions.applySyncGroup(group.id)}
                small
              />
              <ActionButton
                icon="settings"
                label={t('delete')}
                onPress={() => actions.deleteSyncGroup(group.id)}
                small
              />
            </View>
          )}
          scrollEnabled={snapshot.syncGroups.length > 3}
          style={[
            styles.inlineList,
            { height: inlineListHeight(snapshot.syncGroups.length, 58) },
          ]}
        />
      ) : null}

      <Text style={styles.itemTitle}>{t('appSettings')}</Text>
      <ActionRow>
        <ActionButton
          icon="refresh"
          label={t('autoRefresh')}
          onPress={() =>
            actions.setSettings(
              !snapshot.settings.autoRefresh,
              snapshot.settings.refreshIntervalSeconds,
              snapshot.settings.showAdvancedMetadata,
            )
          }
          selected={snapshot.settings.autoRefresh}
        />
        <ActionButton
          icon="info"
          label={t('details')}
          onPress={() =>
            actions.setSettings(
              snapshot.settings.autoRefresh,
              snapshot.settings.refreshIntervalSeconds,
              !snapshot.settings.showAdvancedMetadata,
            )
          }
          selected={snapshot.settings.showAdvancedMetadata}
        />
      </ActionRow>
      <ActionRow>
        {[5, 15, 30, 60].map((seconds) => (
          <ActionButton
            key={seconds}
            label={`${seconds}s`}
            onPress={() =>
              actions.setSettings(
                snapshot.settings.autoRefresh,
                seconds,
                snapshot.settings.showAdvancedMetadata,
              )
            }
            selected={snapshot.settings.refreshIntervalSeconds === seconds}
          />
        ))}
      </ActionRow>
    </View>
  );
}

function ProfileChip({
  onSelect,
  profile,
}: {
  onSelect: (profileID: string) => void;
  profile: DisplayControlColorProfile;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={() => onSelect(profile.id)}
      style={({ pressed }) => [
        styles.chip,
        profile.isCurrent && styles.chipSelected,
        pressed && styles.actionPressed,
      ]}
    >
      <Text
        style={[styles.chipText, profile.isCurrent && styles.chipTextSelected]}
      >
        {profile.name}
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

function Notice({ text }: { text: string }) {
  return (
    <View style={styles.notice}>
      <Text style={styles.noticeText}>{text}</Text>
    </View>
  );
}

function ActionRow({ children }: { children: ReactNode }) {
  return <View style={styles.actionRow}>{children}</View>;
}

function ActionButton({
  disabled,
  icon,
  label,
  onPress,
  selected,
  small,
}: {
  disabled?: boolean;
  icon?: IconName;
  label: string;
  onPress: () => void;
  selected?: boolean;
  small?: boolean;
}) {
  return (
    <Pressable
      accessibilityState={{ disabled, selected }}
      accessibilityRole="button"
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.action,
        small && styles.actionSmall,
        selected && styles.actionSelected,
        pressed && !disabled && styles.actionPressed,
        disabled && styles.actionDisabled,
      ]}
    >
      {icon ? (
        <Icon
          color={selected ? '#ffffff' : disabled ? '#656a76' : '#b2b6bd'}
          name={icon}
          size={13}
        />
      ) : null}
      <Text
        style={[
          styles.actionText,
          icon && styles.actionTextWithIcon,
          selected && styles.actionTextSelected,
          disabled && styles.actionTextDisabled,
        ]}
      >
        {label}
      </Text>
    </Pressable>
  );
}

function SmallInput({
  accessibilityLabel,
  onChangeText,
  value,
}: {
  accessibilityLabel: string;
  onChangeText: (value: string) => void;
  value: string;
}) {
  return (
    <TextInput
      accessibilityLabel={accessibilityLabel}
      onChangeText={onChangeText}
      style={styles.smallInput}
      value={value}
    />
  );
}

function connectionLabel(
  display: DisplayControlDisplay,
  t: (key: TranslationKey) => string,
) {
  if (display.isAsleep) {
    return t('asleep');
  }

  if (!display.isActive) {
    return t('inactive');
  }

  return display.isBuiltin ? t('builtIn') : t('external');
}

function positiveNumberFromInput(value: string, fallback: number) {
  const parsed = Number(value.replace(/[^0-9.]/g, ''));

  if (!Number.isFinite(parsed) || parsed <= 0) {
    return Math.max(fallback, 1);
  }

  return parsed;
}

function inlineListHeight(itemCount: number, itemHeight: number) {
  return Math.min(Math.max(itemCount, 1), 3) * itemHeight;
}

function pipFilterLabel(filter: string, t: (key: TranslationKey) => string) {
  const option = pipFilterOptions.find(
    (candidate) => candidate.value === filter,
  );
  return option == null ? t('filterNone') : t(option.key);
}

const inputOptions = [
  { label: 'VGA', value: 1 },
  { label: 'DVI', value: 3 },
  { label: 'DP1', value: 15 },
  { label: 'DP2', value: 16 },
  { label: 'HDMI1', value: 17 },
  { label: 'HDMI2', value: 18 },
  { label: 'USB-C', value: 27 },
];

const pipFilterOptions: Array<{
  key: TranslationKey;
  value: string;
}> = [
  { key: 'filterNone', value: 'none' },
  { key: 'filterMono', value: 'mono' },
  { key: 'filterInvert', value: 'invert' },
  { key: 'filterWarm', value: 'warm' },
  { key: 'filterVibrant', value: 'vibrant' },
];

const styles = StyleSheet.create({
  sectionTitle: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 15,
    fontWeight: '600',
    letterSpacing: 0,
    lineHeight: 20,
    marginLeft: 7,
  },
  sectionTitleRow: {
    alignItems: 'center',
    flexDirection: 'row',
    marginBottom: 10,
  },
  panel: {
    backgroundColor: '#15181e',
    borderColor: 'rgba(178,182,189,0.1)',
    borderRadius: 8,
    borderWidth: 1,
    padding: 12,
  },
  metric: {
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    marginBottom: 8,
    padding: 10,
  },
  metricLabel: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 11,
    fontWeight: '600',
    letterSpacing: 0.6,
    lineHeight: 14,
    marginBottom: 4,
    textTransform: 'uppercase',
  },
  metricValue: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    lineHeight: 18,
  },
  itemHeader: {
    alignItems: 'center',
    flexDirection: 'row',
    marginTop: 8,
  },
  pipItem: {
    marginTop: 8,
  },
  itemTextBlock: {
    flex: 1,
    minWidth: 0,
    paddingRight: 8,
  },
  itemTitle: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    lineHeight: 18,
    marginTop: 8,
  },
  itemMeta: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '500',
    lineHeight: 16,
  },
  horizontalList: {
    height: 44,
    marginTop: 8,
  },
  inlineList: {
    marginTop: 4,
  },
  chip: {
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    justifyContent: 'center',
    marginRight: 8,
    minHeight: 40,
    paddingHorizontal: 10,
  },
  chipSelected: {
    backgroundColor: '#2b89ff',
    borderColor: '#2b89ff',
  },
  chipText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    lineHeight: 15,
  },
  chipTextSelected: {
    color: '#ffffff',
  },
  notice: {
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    marginBottom: 8,
    padding: 10,
  },
  noticeText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    lineHeight: 16,
  },
  actionRow: {
    flexDirection: 'row',
    marginTop: 8,
  },
  action: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'center',
    marginRight: 8,
    minHeight: 34,
    paddingHorizontal: 8,
  },
  actionSmall: {
    flex: 0,
    minWidth: 62,
  },
  actionSelected: {
    backgroundColor: '#2b89ff',
    borderColor: '#2b89ff',
  },
  actionPressed: {
    backgroundColor: '#3b3d45',
  },
  actionDisabled: {
    opacity: 0.45,
  },
  actionText: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    lineHeight: 15,
  },
  actionTextSelected: {
    color: '#ffffff',
  },
  actionTextDisabled: {
    color: '#656a76',
  },
  actionTextWithIcon: {
    marginLeft: 5,
  },
  rawText: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 11,
    fontWeight: '500',
    lineHeight: 15,
    marginTop: 4,
  },
  inputRow: {
    alignItems: 'center',
    flexDirection: 'row',
    marginTop: 8,
  },
  smallInput: {
    backgroundColor: '#15181e',
    borderColor: '#252830',
    borderRadius: 6,
    borderWidth: 1,
    color: '#ffffff',
    flex: 1,
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '600',
    lineHeight: 16,
    marginRight: 8,
    minHeight: 34,
    minWidth: 0,
    paddingHorizontal: 8,
    paddingVertical: 6,
  },
  textInput: {
    backgroundColor: '#15181e',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    color: '#ffffff',
    flex: 1,
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '500',
    lineHeight: 18,
    marginRight: 8,
    minHeight: 40,
    minWidth: 0,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  automation: {
    borderTopColor: 'rgba(178,182,189,0.1)',
    borderTopWidth: 1,
    marginTop: 14,
    paddingTop: 10,
  },
});
