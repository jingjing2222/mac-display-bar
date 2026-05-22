/**
 * @format
 */

import React from 'react';
import ReactTestRenderer from 'react-test-renderer';
import { vi } from 'vitest';

vi.mock('@hot-updater/react-native', () => ({
  HotUpdater: {
    wrap: () => (Component: React.ComponentType) => Component,
  },
}));

import App from '../App';

test('renders correctly', async () => {
  await ReactTestRenderer.act(() => {
    ReactTestRenderer.create(<App />);
  });
});
