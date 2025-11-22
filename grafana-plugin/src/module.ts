import { AppPlugin } from '@grafana/data';
import { RootPage } from './components/RootPage';
import { FangornSentinelAppSettings } from './types';

export const plugin = new AppPlugin<FangornSentinelAppSettings>()
  .setRootPage(RootPage)
  .addConfigPage({
    title: 'Configuration',
    icon: 'cog',
    body: ConfigPage,
    id: 'configuration',
  });

// Configuration page component
import React from 'react';
import { AppPluginMeta, PluginConfigPageProps } from '@grafana/data';
import { Field, Input, Button } from '@grafana/ui';

interface ConfigPageProps extends PluginConfigPageProps<AppPluginMeta<FangornSentinelAppSettings>> {}

export function ConfigPage({ plugin }: ConfigPageProps) {
  const [settings, setSettings] = React.useState<FangornSentinelAppSettings>({
    apiUrl: plugin.meta.jsonData?.apiUrl || '',
    apiKey: plugin.meta.secureJsonData?.apiKey || '',
  });

  const onSave = async () => {
    // Save configuration
    await plugin.meta.jsonData = {
      apiUrl: settings.apiUrl,
    };
    await plugin.meta.secureJsonData = {
      apiKey: settings.apiKey,
    };
    window.location.reload();
  };

  return (
    <div>
      <h3>Fangorn Sentinel Configuration</h3>
      <p>Configure your Fangorn Sentinel backend connection.</p>

      <Field label="API URL" description="URL of your Fangorn Sentinel backend">
        <Input
          value={settings.apiUrl}
          onChange={(e) => setSettings({ ...settings, apiUrl: e.currentTarget.value })}
          placeholder="https://your-fangorn-sentinel.com"
        />
      </Field>

      <Field label="API Key" description="API key for authentication">
        <Input
          type="password"
          value={settings.apiKey}
          onChange={(e) => setSettings({ ...settings, apiKey: e.currentTarget.value })}
          placeholder="Enter API key"
        />
      </Field>

      <Button onClick={onSave}>Save</Button>
    </div>
  );
}
