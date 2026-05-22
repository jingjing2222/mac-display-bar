import { useEffect, useMemo, useState } from 'react';

import type { DisplayControlDisplay } from '../../../specs/NativeDisplayControl';

export function useSelectedDisplay(displays: Array<DisplayControlDisplay>) {
  const defaultDisplayID = useMemo(
    () =>
      displays.find((display) => display.isPrimary)?.id ??
      displays[0]?.id ??
      '',
    [displays],
  );
  const [selectedDisplayID, setSelectedDisplayID] = useState(defaultDisplayID);

  useEffect(() => {
    if (!displays.some((display) => display.id === selectedDisplayID)) {
      setSelectedDisplayID(defaultDisplayID);
    }
  }, [defaultDisplayID, displays, selectedDisplayID]);

  const selectedDisplay = useMemo(
    () =>
      displays.find((display) => display.id === selectedDisplayID) ??
      displays.find((display) => display.id === defaultDisplayID) ??
      null,
    [defaultDisplayID, displays, selectedDisplayID],
  );

  return {
    selectedDisplay,
    selectedDisplayID,
    setSelectedDisplayID,
  };
}
