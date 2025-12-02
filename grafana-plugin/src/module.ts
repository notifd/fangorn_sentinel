import { AppPlugin } from '@grafana/data';
import { RootPage } from './components/RootPage';
import { ConfigEditor } from './components/ConfigEditor';
import { FangornSentinelAppSettings } from './types';

export const plugin = new AppPlugin<FangornSentinelAppSettings>()
  .setRootPage(RootPage)
  .addConfigPage({
    title: 'Configuration',
    icon: 'cog',
    body: ConfigEditor,
    id: 'configuration',
  });
