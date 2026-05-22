import { useState } from 'react';

export function useTextDraft(initialValue: string) {
  const [value, setValue] = useState(initialValue);

  return {
    setValue,
    value,
  };
}
