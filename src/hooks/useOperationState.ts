import { useCallback, useState } from 'react';

const messageFromError = (error: unknown) =>
  error instanceof Error ? error.message : 'Unknown error';

export function useOperationState<TValue>(initialValue: TValue) {
  const [value, setValue] = useState(initialValue);
  const [error, setError] = useState<string | null>(null);

  const run = useCallback(
    (operation: () => TValue, options?: { resetOnError?: boolean }) => {
      try {
        const nextValue = operation();

        setValue(nextValue);
        setError(null);
      } catch (caughtError) {
        if (options?.resetOnError) {
          setValue(initialValue);
        }

        setError(messageFromError(caughtError));
      }
    },
    [initialValue],
  );

  return {
    error,
    run,
    setError,
    setValue,
    value,
  };
}
