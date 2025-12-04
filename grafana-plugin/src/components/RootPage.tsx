import React, { useState, useEffect } from 'react';
import { AppRootProps } from '@grafana/data';
import {
  Button,
  Card,
  Field,
  Input,
  VerticalGroup,
  HorizontalGroup,
  Tag,
} from '@grafana/ui';
import { FangornSentinelAppSettings, Alert, User } from '../types';

export function RootPage({ meta }: AppRootProps<FangornSentinelAppSettings>) {
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [selectedTab, setSelectedTab] = useState<'alerts' | 'oncall' | 'settings'>('alerts');

  const apiUrl = meta.jsonData?.apiUrl || '';

  useEffect(() => {
    if (selectedTab === 'alerts') {
      loadAlerts();
    } else if (selectedTab === 'oncall') {
      loadOnCallUsers();
    }
  }, [selectedTab, apiUrl]);

  const loadAlerts = async () => {
    if (!apiUrl) {
      return;
    }
    try {
      const response = await fetch(`${apiUrl}/api/v1/alerts`);
      const data = await response.json();
      setAlerts(data.alerts || []);
    } catch (error) {
      console.error('Failed to load alerts:', error);
    }
  };

  const loadOnCallUsers = async () => {
    if (!apiUrl) {
      return;
    }
    try {
      const response = await fetch(`${apiUrl}/api/v1/oncall/current`);
      const data = await response.json();
      setUsers(data.users || []);
    } catch (error) {
      console.error('Failed to load on-call users:', error);
    }
  };

  const acknowledgeAlert = async (alertId: string) => {
    if (!apiUrl) {
      return;
    }
    try {
      await fetch(`${apiUrl}/api/v1/alerts/${alertId}/acknowledge`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
      });
      loadAlerts();
    } catch (error) {
      console.error('Failed to acknowledge alert:', error);
    }
  };

  return (
    <div style={{ padding: '20px' }}>
      <h1>Fangorn Sentinel</h1>

      <HorizontalGroup spacing="md" style={{ marginBottom: '20px' }}>
        <Button
          variant={selectedTab === 'alerts' ? 'primary' : 'secondary'}
          onClick={() => setSelectedTab('alerts')}
        >
          Alerts
        </Button>
        <Button
          variant={selectedTab === 'oncall' ? 'primary' : 'secondary'}
          onClick={() => setSelectedTab('oncall')}
        >
          On-Call
        </Button>
        <Button
          variant={selectedTab === 'settings' ? 'primary' : 'secondary'}
          onClick={() => setSelectedTab('settings')}
        >
          Settings
        </Button>
      </HorizontalGroup>

      {selectedTab === 'alerts' && <AlertsView alerts={alerts} onAcknowledge={acknowledgeAlert} />}
      {selectedTab === 'oncall' && <OnCallView users={users} />}
      {selectedTab === 'settings' && <SettingsView apiUrl={apiUrl} />}
    </div>
  );
}

function AlertsView({ alerts, onAcknowledge }: { alerts: Alert[]; onAcknowledge: (id: string) => void }) {
  return (
    <VerticalGroup spacing="md">
      <h2>Active Alerts</h2>
      {alerts.length === 0 ? (
        <p>No active alerts</p>
      ) : (
        alerts.map((alert) => (
          <Card key={alert.id}>
            <Card.Heading>{alert.title}</Card.Heading>
            <Card.Description>{alert.message}</Card.Description>
            <Card.Meta>
              <Tag name={alert.severity} colorIndex={getSeverityColor(alert.severity)} />
              <Tag name={alert.status} colorIndex={getStatusColor(alert.status)} />
              <span>Fired: {new Date(alert.firedAt).toLocaleString()}</span>
            </Card.Meta>
            {alert.status === 'firing' && (
              <Card.Actions>
                <Button variant="primary" size="sm" onClick={() => onAcknowledge(alert.id)}>
                  Acknowledge
                </Button>
              </Card.Actions>
            )}
          </Card>
        ))
      )}
    </VerticalGroup>
  );
}

function OnCallView({ users }: { users: User[] }) {
  return (
    <VerticalGroup spacing="md">
      <h2>Currently On-Call</h2>
      {users.length === 0 ? (
        <p>No users currently on-call</p>
      ) : (
        <div>
          {users.map((user) => (
            <Card key={user.id}>
              <Card.Heading>{user.name}</Card.Heading>
              <Card.Meta>
                <span>{user.email}</span>
                {user.phone && <span>{user.phone}</span>}
              </Card.Meta>
            </Card>
          ))}
        </div>
      )}
    </VerticalGroup>
  );
}

function SettingsView({ apiUrl }: { apiUrl: string }) {
  return (
    <VerticalGroup spacing="md">
      <h2>Integration Settings</h2>
      <p>Configure Grafana Alerting to send alerts to Fangorn Sentinel:</p>

      <Field label="Webhook URL">
        <Input value={`${apiUrl}/api/v1/webhooks/grafana`} readOnly />
      </Field>

      <h3>Setup Instructions</h3>
      <ol>
        <li>Go to <strong>Alerting → Contact points</strong></li>
        <li>Click <strong>Add contact point</strong></li>
        <li>Select <strong>Webhook</strong> as the type</li>
        <li>Enter the webhook URL above</li>
        <li>Set HTTP Method to <strong>POST</strong></li>
        <li>Save the contact point</li>
        <li>Update your alert rules to use this contact point</li>
      </ol>
    </VerticalGroup>
  );
}

function getSeverityColor(severity: string): number {
  switch (severity) {
    case 'critical':
      return 1; // Red
    case 'warning':
      return 3; // Orange
    case 'info':
      return 5; // Blue
    default:
      return 0;
  }
}

function getStatusColor(status: string): number {
  switch (status) {
    case 'firing':
      return 1; // Red
    case 'acknowledged':
      return 3; // Orange
    case 'resolved':
      return 9; // Green
    default:
      return 0;
  }
}
