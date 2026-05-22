import { useEffect } from 'react';

export function useIntervalEffect(
  callback: () => void,
  intervalMilliseconds: number | null,
) {
  useEffect(() => {
    if (intervalMilliseconds == null) {
      return;
    }

    const intervalID = setInterval(callback, intervalMilliseconds);

    return () => clearInterval(intervalID);
  }, [callback, intervalMilliseconds]);
}
