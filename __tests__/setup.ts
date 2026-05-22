import { vi } from 'vitest';

vi.mock('react-native-svg', async () => {
  const React = await import('react');
  const createSvgComponent =
    (type: string) =>
    ({ children, ...props }: { children?: React.ReactNode }) =>
      React.createElement(type, props, children);

  return {
    Circle: createSvgComponent('Circle'),
    Path: createSvgComponent('Path'),
    Rect: createSvgComponent('Rect'),
    default: createSvgComponent('Svg'),
  };
});
