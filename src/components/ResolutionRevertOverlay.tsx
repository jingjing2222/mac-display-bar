import { useCallback, useEffect, useRef, useState } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

import type { DisplayControlMode } from '../../specs/NativeDisplayControl';
import type { TranslationKey } from '../i18n/strings';
import { Icon } from './Icon';
import { ModeSummary } from './ModeSummary';

const font = {
  family: 'Inter',
} as const;

const timeoutSeconds = 30;

type KeyboardViewProps = {
  focusable: true;
  keyDownEvents: Array<{ key: 'Enter' | 'Escape' }>;
  onKeyDown: (event: { nativeEvent: { key: string } }) => void;
};

type KeyboardTextInputProps = {
  submitKeyEvents: Array<{ key: 'Enter' }>;
};

export function ResolutionRevertOverlay({
  onClose,
  onRevert,
  previousMode,
  t,
}: {
  onClose: () => void;
  onRevert: () => void;
  previousMode: DisplayControlMode;
  t: (key: TranslationKey) => string;
}) {
  const [seconds, setSeconds] = useState(timeoutSeconds);
  const closedRef = useRef(false);
  const keyboardInputRef = useRef<TextInput>(null);

  const keepCurrentMode = useCallback(() => {
    if (closedRef.current) {
      return;
    }

    closedRef.current = true;
    onClose();
  }, [onClose]);

  const revertToPreviousMode = useCallback(() => {
    if (closedRef.current) {
      return;
    }

    closedRef.current = true;
    onRevert();
    onClose();
  }, [onClose, onRevert]);

  const handleKey = useCallback(
    (key: string) => {
      if (key === 'Enter') {
        revertToPreviousMode();
        return;
      }

      if (key === 'Escape') {
        keepCurrentMode();
      }
    },
    [keepCurrentMode, revertToPreviousMode],
  );

  useEffect(() => {
    const frame = requestAnimationFrame(() => {
      keyboardInputRef.current?.focus();
    });

    return () => cancelAnimationFrame(frame);
  }, []);

  useEffect(() => {
    const interval = setInterval(() => {
      setSeconds((value) => {
        if (value <= 1) {
          clearInterval(interval);
          revertToPreviousMode();

          return 0;
        }

        return value - 1;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [revertToPreviousMode]);

  const keyboardProps: KeyboardViewProps = {
    focusable: true,
    keyDownEvents: [{ key: 'Enter' }, { key: 'Escape' }],
    onKeyDown: (event) => handleKey(event.nativeEvent.key),
  };
  const keyboardInputProps: KeyboardTextInputProps = {
    submitKeyEvents: [{ key: 'Enter' }],
  };

  return (
    <View {...keyboardProps} style={styles.root}>
      <Pressable style={styles.backdrop} onPress={keepCurrentMode} />
      <TextInput
        {...keyboardInputProps}
        autoFocus
        caretHidden
        contextMenuHidden
        onKeyPress={(event) => handleKey(event.nativeEvent.key)}
        onSubmitEditing={revertToPreviousMode}
        ref={keyboardInputRef}
        style={styles.keyboardInput}
        submitBehavior="submit"
        value=""
      />
      <View style={styles.dialog}>
        <View style={styles.header}>
          <View style={styles.iconBox}>
            <Icon color="#b2b6bd" name="refresh" size={18} />
          </View>
          <View style={styles.headerText}>
            <Text style={styles.title}>{t('resolutionRevertTitle')}</Text>
            <Text style={styles.subtitle}>
              {seconds}
              {t('resolutionRevertSeconds')}
            </Text>
          </View>
        </View>
        <Text style={styles.body}>{t('resolutionRevertBody')}</Text>
        <View style={styles.previousMode}>
          <Text style={styles.previousLabel}>
            {t('resolutionPreviousMode')}
          </Text>
          <ModeSummary mode={previousMode} t={t} />
        </View>
        <View style={styles.actions}>
          <Pressable
            accessibilityLabel={t('resolutionRevertAction')}
            accessibilityRole="button"
            onPress={revertToPreviousMode}
            style={({ pressed }) => [
              styles.primaryButton,
              pressed && styles.primaryButtonPressed,
            ]}
          >
            <Text style={styles.primaryText}>
              {t('resolutionRevertAction')}
            </Text>
          </Pressable>
          <Pressable
            accessibilityLabel={t('resolutionKeepAction')}
            accessibilityRole="button"
            onPress={keepCurrentMode}
            style={({ pressed }) => [
              styles.secondaryButton,
              pressed && styles.secondaryButtonPressed,
            ]}
          >
            <Text style={styles.secondaryText}>
              {t('resolutionKeepAction')}
            </Text>
          </Pressable>
        </View>
      </View>
    </View>
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
    backgroundColor: 'rgba(0,0,0,0.68)',
    bottom: 0,
    left: 0,
    position: 'absolute',
    right: 0,
    top: 0,
  },
  keyboardInput: {
    height: 1,
    left: 0,
    opacity: 0,
    position: 'absolute',
    top: 0,
    width: 1,
  },
  dialog: {
    backgroundColor: '#15181e',
    borderColor: 'rgba(178,182,189,0.18)',
    borderRadius: 8,
    borderWidth: 1,
    left: 18,
    padding: 14,
    position: 'absolute',
    right: 18,
    top: 156,
  },
  header: {
    alignItems: 'center',
    flexDirection: 'row',
    marginBottom: 12,
  },
  iconBox: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    height: 38,
    justifyContent: 'center',
    width: 38,
  },
  headerText: {
    flex: 1,
    marginLeft: 10,
    minWidth: 0,
  },
  title: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 16,
    fontWeight: '700',
    lineHeight: 21,
  },
  subtitle: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 12,
    fontWeight: '700',
    lineHeight: 16,
    marginTop: 2,
  },
  body: {
    color: '#b2b6bd',
    fontFamily: font.family,
    fontSize: 13,
    fontWeight: '600',
    lineHeight: 19,
    marginBottom: 12,
  },
  previousMode: {
    backgroundColor: '#000000',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    minHeight: 70,
    padding: 10,
  },
  previousLabel: {
    color: '#656a76',
    fontFamily: font.family,
    fontSize: 11,
    fontWeight: '700',
    lineHeight: 14,
    marginBottom: 5,
    textTransform: 'uppercase',
  },
  actions: {
    flexDirection: 'row',
    marginTop: 12,
  },
  primaryButton: {
    alignItems: 'center',
    backgroundColor: '#ffffff',
    borderRadius: 8,
    flex: 1,
    justifyContent: 'center',
    minHeight: 42,
  },
  primaryButtonPressed: {
    backgroundColor: '#e8eaed',
  },
  primaryText: {
    color: '#000000',
    fontFamily: font.family,
    fontSize: 14,
    fontWeight: '700',
    lineHeight: 18,
  },
  secondaryButton: {
    alignItems: 'center',
    backgroundColor: '#1f232b',
    borderColor: '#252830',
    borderRadius: 8,
    borderWidth: 1,
    flex: 1,
    justifyContent: 'center',
    marginLeft: 8,
    minHeight: 42,
  },
  secondaryButtonPressed: {
    backgroundColor: '#3b3d45',
  },
  secondaryText: {
    color: '#ffffff',
    fontFamily: font.family,
    fontSize: 14,
    fontWeight: '700',
    lineHeight: 18,
  },
});
