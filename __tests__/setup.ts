import { vi } from 'vitest';

Object.defineProperty(globalThis, 'navigator', {
  configurable: true,
  value: { product: 'ReactNative' },
});

globalThis.requestAnimationFrame = (callback: (time: number) => void) => {
  return setTimeout(() => callback(Date.now()), 0) as unknown as number;
};

globalThis.cancelAnimationFrame = (id: number) => {
  clearTimeout(id);
};

vi.mock('@legendapp/list', async () => {
  const React = await import('react');

  return {
    LegendList({
      data,
      renderItem,
      ...props
    }: {
      data: Array<unknown>;
      renderItem: (params: { item: unknown; index: number }) => React.ReactNode;
    }) {
      return React.createElement(
        'LegendList',
        props,
        data.map((item, index) => renderItem({ index, item })),
      );
    },
  };
});

vi.mock('@shopify/flash-list', async () => {
  const React = await import('react');

  return {
    FlashList({
      data,
      renderItem,
      ...props
    }: {
      data: Array<unknown>;
      renderItem: (params: { item: unknown; index: number }) => React.ReactNode;
    }) {
      return React.createElement(
        'FlashList',
        props,
        data.map((item, index) => renderItem({ index, item })),
      );
    },
  };
});

vi.mock('overlay-kit', async () => {
  const React = await import('react');
  const state = {
    controller: null as
      | null
      | ((props: {
          close: () => void;
          isOpen: boolean;
          overlayId: string;
          unmount: () => void;
        }) => React.ReactNode),
    id: 'test-overlay',
    isOpen: false,
    listeners: new Set<() => void>(),
  };
  const notify = () => {
    state.listeners.forEach((listener) => listener());
  };
  const close = () => {
    state.isOpen = false;
    notify();
  };
  const unmount = () => {
    state.controller = null;
    notify();
  };

  return {
    OverlayProvider({ children }: { children?: React.ReactNode }) {
      const [, rerender] = React.useReducer((value) => value + 1, 0);

      React.useEffect(() => {
        const listener = () => rerender();
        state.controller = null;
        state.isOpen = false;
        state.listeners.add(listener);

        return () => {
          state.listeners.delete(listener);
        };
      }, []);

      const overlayNode = state.controller
        ? state.controller({
            close,
            isOpen: state.isOpen,
            overlayId: state.id,
            unmount,
          })
        : null;

      return React.createElement(React.Fragment, null, children, overlayNode);
    },
    overlay: {
      close,
      closeAll: close,
      open(controller: NonNullable<typeof state.controller>): typeof state.id {
        state.controller = controller;
        state.isOpen = true;
        notify();

        return state.id;
      },
      unmount,
      unmountAll: unmount,
    },
  };
});

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
