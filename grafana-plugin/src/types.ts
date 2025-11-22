export interface FangornSentinelAppSettings {
  apiUrl?: string;
  apiKey?: string;
}

export interface Alert {
  id: number;
  title: string;
  message: string | null;
  severity: 'critical' | 'warning' | 'info';
  status: 'firing' | 'acknowledged' | 'resolved';
  source: string;
  fired_at: string;
  acknowledged_at?: string;
  resolved_at?: string;
  assigned_to_id?: number;
}

export interface User {
  id: number;
  name: string;
  email: string;
  phone?: string;
  timezone: string;
}

export interface Schedule {
  id: number;
  name: string;
  timezone: string;
  current_on_call?: User[];
}
