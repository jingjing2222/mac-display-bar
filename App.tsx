/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import { StyleSheet, Text, View } from 'react-native';
import NativeFoo from './specs/NativeFoo';

function App() {
  let nativeFooValue = 'NativeFoo unavailable';

  try {
    nativeFooValue = NativeFoo?.foo() ?? nativeFooValue;
  } catch (error) {
    nativeFooValue =
      error instanceof Error ? error.message : 'NativeFoo threw unknown error';
  }

  return (
    <View style={styles.container}>
      <View style={styles.nativeFooBanner}>
        <Text style={styles.title}>mac-display-bar</Text>
        <Text style={styles.nativeFooLabel}>NativeFoo.foo()</Text>
        <Text style={styles.nativeFooValue}>{nativeFooValue}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f7f8fa',
    padding: 24,
  },
  nativeFooBanner: {
    alignSelf: 'flex-start',
    backgroundColor: '#ffffff',
    borderColor: '#d0d5dd',
    borderRadius: 8,
    borderWidth: 1,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  title: {
    color: '#101828',
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 12,
  },
  nativeFooLabel: {
    color: '#344054',
    fontSize: 13,
    fontWeight: '600',
  },
  nativeFooValue: {
    color: '#175cd3',
    fontSize: 24,
    fontWeight: '700',
  },
});

export default App;
