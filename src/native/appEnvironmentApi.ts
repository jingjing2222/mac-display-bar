import NativeDisplayControl from '../../specs/NativeDisplayControl';

export const fallbackLocale = 'en-US';

export const appEnvironmentApi = {
  getSystemLocale() {
    return NativeDisplayControl?.getSystemLocale() ?? fallbackLocale;
  },
};
