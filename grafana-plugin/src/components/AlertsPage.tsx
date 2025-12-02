import React, { useEffect, useState } from 'react';
import { Badge, Card, Icon, IconName, LoadingPlaceholder, VerticalGroup, HorizontalGroup, Button } from '@grafana/ui';
import { Alert } from '../types';

const severityConfig: Record<Alert['severity'], { color: 'red' | 'orange' | 'blue'; icon: IconName }> = {
  critical: { color: 'red', icon: 'exclamation-triangle' },
  warning: { color: 'orange', icon: 'exclamation-circle' },
  info: { color: 'blue', icon: 'info-circle' },
};

const statusConfig: Record<Alert['status'], { text: string; color: 'red' | 'green' | 'blue' }> = {
  firing: { text: 'Firing', color: 'red' },
  acknowledged: { text: 'Acknowledged', color: 'blue' },
  resolved: { text: 'Resolved', color: 'green' },
};

export const AlertsPage: React.FC = () => {
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // TODO: Replace with actual API call
    const mockAlerts: Alert[] = [
      {
        id: '1',
        title: 'High CPU Usage',
        message: 'Server prod-web-01 CPU usage exceeded 90%',
        severity: 'critical',
        status: 'firing',
        source: 'prometheus',
        labels: { instance: 'prod-web-01', job: 'node' },
        annotations: {},
        firedAt: new Date(Date.now() - 300000).toISOString(),
      },
      {
        id: '2',
        title: 'Disk Space Warning',
        message: 'Server prod-db-01 disk usage at 85%',
        severity: 'warning',
        status: 'acknowledged',
        source: 'grafana',
        labels: { instance: 'prod-db-01' },
        annotations: {},
        firedAt: new Date(Date.now() - 1800000).toISOString(),
        acknowledgedAt: new Date(Date.now() - 900000).toISOString(),
      },
      {
        id: '3',
        title: 'Service Health Check',
        message: 'API endpoint /health returned 200',
        severity: 'info',
        status: 'resolved',
        source: 'grafana',
        labels: {},
        annotations: {},
        firedAt: new Date(Date.now() - 7200000).toISOString(),
        resolvedAt: new Date(Date.now() - 3600000).toISOString(),
      },
    ];

    setTimeout(() => {
      setAlerts(mockAlerts);
      setLoading(false);
    }, 500);
  }, []);

  const formatTime = (isoString: string) => {
    const date = new Date(isoString);
    return date.toLocaleString();
  };

  const handleAcknowledge = (alertId: string) => {
    setAlerts(alerts.map(alert =>
      alert.id === alertId ? { ...alert, status: 'acknowledged' as const } : alert
    ));
  };

  const handleResolve = (alertId: string) => {
    setAlerts(alerts.map(alert =>
      alert.id === alertId ? { ...alert, status: 'resolved' as const } : alert
    ));
  };

  if (loading) {
    return <LoadingPlaceholder text="Loading alerts..." />;
  }

  return (
    <div>
      <h2>Alerts</h2>
      <VerticalGroup spacing="md">
        {alerts.map((alert) => {
          const severity = severityConfig[alert.severity];
          const status = statusConfig[alert.status];

          return (
            <Card key={alert.id}>
              <Card.Heading>
                <HorizontalGroup spacing="sm" align="center">
                  <Icon name={severity.icon} size="lg" style={{ color: `var(--${severity.color})` }} />
                  {alert.title}
                </HorizontalGroup>
              </Card.Heading>
              <Card.Description>{alert.message}</Card.Description>
              <Card.Meta>
                <span>Source: {alert.source}</span>
                <span>Fired: {formatTime(alert.firedAt)}</span>
              </Card.Meta>
              <Card.Tags>
                <Badge text={status.text} color={status.color} />
                <Badge text={alert.severity.toUpperCase()} color={severity.color} />
              </Card.Tags>
              <Card.Actions>
                {alert.status === 'firing' && (
                  <Button size="sm" variant="secondary" onClick={() => handleAcknowledge(alert.id)}>
                    Acknowledge
                  </Button>
                )}
                {alert.status !== 'resolved' && (
                  <Button size="sm" variant="primary" onClick={() => handleResolve(alert.id)}>
                    Resolve
                  </Button>
                )}
              </Card.Actions>
            </Card>
          );
        })}
      </VerticalGroup>
    </div>
  );
};

export default AlertsPage;
