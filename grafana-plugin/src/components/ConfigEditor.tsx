import React, { ChangeEvent } from 'react';
import { PluginConfigPageProps, AppPluginMeta } from '@grafana/data';
import { Field, Input, SecretInput, Button, VerticalGroup, Alert } from '@grafana/ui';
import { FangornSentinelAppSettings } from '../types';

interface Props extends PluginConfigPageProps<AppPluginMeta<FangornSentinelAppSettings>> {}

export const ConfigEditor: React.FC<Props> = ({ plugin }) => {
  const { enabled, jsonData } = plugin.meta;
  const [apiUrl, setApiUrl] = React.useState(jsonData?.apiUrl || '');
  const [apiKey, setApiKey] = React.useState('');
  const [isApiKeySet, setIsApiKeySet] = React.useState(!!jsonData?.apiKey);

  const onApiUrlChange = (event: ChangeEvent<HTMLInputElement>) => {
    setApiUrl(event.target.value);
  };

  const onApiKeyChange = (event: ChangeEvent<HTMLInputElement>) => {
    setApiKey(event.target.value);
  };

  const onResetApiKey = () => {
    setApiKey('');
    setIsApiKeySet(false);
  };

  const onSave = async () => {
    // Save configuration
    // This would typically use the Grafana backend to persist settings
    console.log('Saving configuration:', { apiUrl, apiKey: apiKey ? '***' : undefined });
  };

  return (
    <div>
      <h3>Fangorn Sentinel Configuration</h3>

      {!enabled && (
        <Alert title="Plugin not enabled" severity="warning">
          Enable this plugin to start using Fangorn Sentinel.
        </Alert>
      )}

      <VerticalGroup spacing="md">
        <Field label="API URL" description="The URL of your Fangorn Sentinel API server">
          <Input
            value={apiUrl}
            onChange={onApiUrlChange}
            placeholder="https://sentinel.example.com/api"
            width={60}
          />
        </Field>

        <Field label="API Key" description="API key for authenticating with the Fangorn Sentinel API">
          <SecretInput
            isConfigured={isApiKeySet}
            value={apiKey}
            onChange={onApiKeyChange}
            onReset={onResetApiKey}
            placeholder="Enter API key"
            width={60}
          />
        </Field>

        <Button onClick={onSave} variant="primary">
          Save Configuration
        </Button>
      </VerticalGroup>

      <div style={{ marginTop: '2rem' }}>
        <h4>Getting Started</h4>
        <ol>
          <li>Deploy the Fangorn Sentinel backend server</li>
          <li>Enter the API URL above (e.g., https://sentinel.example.com/api)</li>
          <li>Generate an API key from the Fangorn Sentinel admin panel</li>
          <li>Enter the API key above and save</li>
          <li>Navigate to the Alerts page to view your alerts</li>
        </ol>
      </div>
    </div>
  );
};

export default ConfigEditor;
