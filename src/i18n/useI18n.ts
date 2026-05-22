import { useMemo } from 'react';

import { appEnvironmentApi } from '../native/appEnvironmentApi';
import { strings, type Language, type TranslationKey } from './strings';

export function languageFromLocale(locale: string | undefined): Language {
  return locale?.toLowerCase().startsWith('ko') ? 'ko' : 'en';
}

function currentLocale() {
  return appEnvironmentApi.getSystemLocale();
}

export function useI18n() {
  const language = useMemo(() => languageFromLocale(currentLocale()), []);
  const table = strings[language];

  return {
    language,
    t(key: TranslationKey) {
      return table[key] ?? strings.en[key];
    },
  };
}
