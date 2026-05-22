import { HotUpdater } from '@hot-updater/react-native';

import { MenuShell } from './src/components/MenuShell';
import { hotUpdaterBaseURL } from './src/config/hotUpdaterConfig';
import { useDisplayControl } from './src/hooks/display/useDisplayControl';

function App() {
  const control = useDisplayControl();

  return <MenuShell control={control} />;
}

export default HotUpdater.wrap({
  baseURL: hotUpdaterBaseURL,
  updateStrategy: 'appVersion',
  onError: (error) => {
    console.warn(error);
  },
})(App);
