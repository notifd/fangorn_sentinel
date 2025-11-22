import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            AlertListView()
        }
        .onAppear {
            appState.loadAlerts()
        }
    }
}

struct AlertListView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List(appState.alerts) { alert in
            NavigationLink(destination: AlertDetailView(alert: alert)) {
                AlertRowView(alert: alert)
            }
        }
        .navigationTitle("Alerts")
        .refreshable {
            appState.loadAlerts()
        }
    }
}

struct AlertRowView: View {
    let alert: Alert

    var body: some View {
        HStack(spacing: 12) {
            // Severity indicator
            Circle()
                .fill(severityColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let message = alert.message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Text(alert.firedAt.relativeTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if alert.status == .firing {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }

    var severityColor: Color {
        switch alert.severity {
        case .critical: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

struct AlertDetailView: View {
    @EnvironmentObject var appState: AppState
    let alert: Alert

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Circle()
                        .fill(severityColor)
                        .frame(width: 20, height: 20)

                    Text(alert.title)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                // Message
                if let message = alert.message {
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    MetadataRow(label: "Severity", value: alert.severity.rawValue.capitalized)
                    MetadataRow(label: "Status", value: alert.status.rawValue.capitalized)
                    MetadataRow(label: "Fired At", value: alert.firedAt.formatted())
                    if let source = alert.source {
                        MetadataRow(label: "Source", value: source)
                    }
                }

                // Actions
                if alert.status == .firing {
                    Button(action: {
                        appState.acknowledgeAlert(alert)
                    }) {
                        Text("Acknowledge Alert")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Alert Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    var severityColor: Color {
        switch alert.severity {
        case .critical: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Extensions
extension Date {
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
