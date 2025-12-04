import { AppRootProps } from '@grafana/data';

export interface FangornSentinelAppSettings {
  apiUrl?: string;
  apiKey?: string;
}

export interface Alert {
  id: string;
  title: string;
  message?: string;
  severity: 'critical' | 'warning' | 'info';
  status: 'firing' | 'acknowledged' | 'resolved';
  source: string;
  sourceId?: string;
  labels: Record<string, string>;
  annotations: Record<string, string>;
  firedAt: string;
  acknowledgedAt?: string;
  resolvedAt?: string;
  assignedToId?: string;
}

export interface User {
  id: string;
  name: string;
  email: string;
  phone?: string;
  timezone: string;
}

export interface Team {
  id: string;
  name: string;
  slug: string;
}

export interface Schedule {
  id: string;
  name: string;
  description?: string;
  timezone: string;
  teamId?: string;
  rotations: Rotation[];
  currentOnCall?: User[];
}

export interface Rotation {
  id: string;
  name: string;
  type: 'daily' | 'weekly' | 'custom';
  startTime?: string;
  durationHours: number;
  participants: string[];
  rotationStartDate: string;
}

export interface EscalationPolicy {
  id: string;
  name: string;
  description?: string;
  teamId?: string;
  steps: EscalationStep[];
}

export interface EscalationStep {
  id: string;
  stepNumber: number;
  waitMinutes: number;
  notifyUsers: string[];
  notifySchedules: string[];
  channels: NotificationChannel[];
}

export type NotificationChannel = 'push' | 'sms' | 'phone' | 'email' | 'slack';

export type AppProps = AppRootProps<FangornSentinelAppSettings>;
