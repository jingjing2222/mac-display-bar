import Svg, { Circle, Path, Rect } from 'react-native-svg';

// Path data is adapted from Lucide icons, an open source ISC-licensed SVG set.
// Copyright (c) 2026 Lucide Icons and Contributors.
export type IconName =
  | 'check'
  | 'chevronDown'
  | 'chevronUp'
  | 'display'
  | 'download'
  | 'info'
  | 'layout'
  | 'monitorCog'
  | 'palette'
  | 'plug'
  | 'refresh'
  | 'settings'
  | 'sliders'
  | 'sparkles'
  | 'zap';

export function Icon({
  color = '#b2b6bd',
  name,
  size = 16,
  strokeWidth = 2,
}: {
  color?: string;
  name: IconName;
  size?: number;
  strokeWidth?: number;
}) {
  return (
    <Svg
      fill="none"
      height={size}
      stroke={color}
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={strokeWidth}
      viewBox="0 0 24 24"
      width={size}
    >
      <IconPaths name={name} />
    </Svg>
  );
}

function IconPaths({ name }: { name: IconName }) {
  switch (name) {
    case 'check':
      return <Path d="M20 6 9 17l-5-5" />;
    case 'chevronDown':
      return <Path d="m6 9 6 6 6-6" />;
    case 'chevronUp':
      return <Path d="m18 15-6-6-6 6" />;
    case 'display':
      return (
        <>
          <Rect height="14" rx="2" width="20" x="2" y="3" />
          <Path d="M8 21h8" />
          <Path d="M12 17v4" />
        </>
      );
    case 'download':
      return (
        <>
          <Path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
          <Path d="M7 10l5 5 5-5" />
          <Path d="M12 15V3" />
        </>
      );
    case 'info':
      return (
        <>
          <Circle cx="12" cy="12" r="10" />
          <Path d="M12 16v-4" />
          <Path d="M12 8h.01" />
        </>
      );
    case 'layout':
      return (
        <>
          <Rect height="18" rx="2" width="18" x="3" y="3" />
          <Path d="M3 9h18" />
          <Path d="M9 21V9" />
        </>
      );
    case 'monitorCog':
      return (
        <>
          <Rect height="12" rx="2" width="18" x="3" y="4" />
          <Path d="M8 20h8" />
          <Path d="M12 16v4" />
          <Circle cx="17" cy="9" r="2" />
          <Path d="M17 6v1" />
          <Path d="M17 11v1" />
          <Path d="m14.4 7.5.9.5" />
          <Path d="m18.7 10 .9.5" />
          <Path d="m14.4 10.5.9-.5" />
          <Path d="m18.7 8 .9-.5" />
        </>
      );
    case 'palette':
      return (
        <>
          <Circle cx="13.5" cy="6.5" r=".5" />
          <Circle cx="17.5" cy="10.5" r=".5" />
          <Circle cx="8.5" cy="7.5" r=".5" />
          <Circle cx="6.5" cy="12.5" r=".5" />
          <Path d="M12 2a10 10 0 0 0 0 20h1.5a2.5 2.5 0 0 0 0-5H12a5 5 0 0 1 0-10h.5A2.5 2.5 0 0 0 15 4.5 2.5 2.5 0 0 0 12.5 2H12Z" />
        </>
      );
    case 'plug':
      return (
        <>
          <Path d="M12 22v-5" />
          <Path d="M9 8V2" />
          <Path d="M15 8V2" />
          <Path d="M18 8v5a6 6 0 0 1-12 0V8Z" />
        </>
      );
    case 'refresh':
      return (
        <>
          <Path d="M3 12a9 9 0 0 1 15-6.7L21 8" />
          <Path d="M21 3v5h-5" />
          <Path d="M21 12a9 9 0 0 1-15 6.7L3 16" />
          <Path d="M3 21v-5h5" />
        </>
      );
    case 'settings':
      return (
        <>
          <Path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.38a2 2 0 0 0-.73-2.73l-.15-.09a2 2 0 0 1-1-1.74v-.51a2 2 0 0 1 1-1.72l.15-.1a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2Z" />
          <Circle cx="12" cy="12" r="3" />
        </>
      );
    case 'sliders':
      return (
        <>
          <Path d="M4 21v-7" />
          <Path d="M4 10V3" />
          <Path d="M12 21v-9" />
          <Path d="M12 8V3" />
          <Path d="M20 21v-5" />
          <Path d="M20 12V3" />
          <Path d="M2 14h4" />
          <Path d="M10 8h4" />
          <Path d="M18 16h4" />
        </>
      );
    case 'sparkles':
      return (
        <>
          <Path d="m12 3-1.9 5.8L4 11l6.1 2.2L12 19l1.9-5.8L20 11l-6.1-2.2Z" />
          <Path d="M5 3v4" />
          <Path d="M3 5h4" />
          <Path d="M19 17v4" />
          <Path d="M17 19h4" />
        </>
      );
    case 'zap':
      return <Path d="M13 2 3 14h8l-1 8 11-14h-8Z" />;
  }
}
