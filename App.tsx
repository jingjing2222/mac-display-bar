/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import {
  StatusBar,
  StyleSheet,
  Text,
  useColorScheme,
  View,
} from 'react-native';
import {
  SafeAreaProvider,
  useSafeAreaInsets,
} from 'react-native-safe-area-context';
import NativeFoo from './specs/NativeFoo';

function App() {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <SafeAreaProvider>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <AppContent />
    </SafeAreaProvider>
  );
}

function AppContent() {
  const safeAreaInsets = useSafeAreaInsets();
  const nativeFooValue = NativeFoo?.foo() ?? 'NativeFoo unavailable';

  return (
    <View
      style={[
        styles.container,
        {
          paddingTop: safeAreaInsets.top,
          paddingBottom: safeAreaInsets.bottom,
        },
      ]}
    >
      <View style={styles.nativeFooBanner}>
        <Text style={styles.nativeFooLabel}>NativeFoo.foo()</Text>
        <Text style={styles.nativeFooValue}>{nativeFooValue}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  nativeFooBanner: {
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  nativeFooLabel: {
    fontSize: 13,
    fontWeight: '600',
  },
  nativeFooValue: {
    fontSize: 24,
    fontWeight: '700',
  },
});

export default App;
