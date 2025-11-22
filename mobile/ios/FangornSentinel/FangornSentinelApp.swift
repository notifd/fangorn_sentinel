import SwiftUI
import UserNotifications

@main
struct FangornSentinelApp: App {
    @StateObject private var appState = AppState()

    init() {
        // Request critical alert permission
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge, .criticalAlert]
        ) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var alerts: [Alert] = []
    @Published var isAuthenticated = false
    @Published var deviceToken: String?

    func registerDevice(token: String, userId: Int) {
        let url = URL(string: "https://your-backend.com/api/v1/devices/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "user_id": userId,
            "platform": "ios",
            "device_token": token,
            "device_name": UIDevice.current.name,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            "os_version": UIDevice.current.systemVersion
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Device registration failed: \(error)")
                return
            }
            print("Device registered successfully")
        }.resume()
    }

    func loadAlerts() {
        // TODO: Implement GraphQL query for alerts
        // For now, mock data
        alerts = [
            Alert(
                id: 1,
                title: "High CPU Usage",
                message: "CPU usage is above 90%",
                severity: .critical,
                status: .firing,
                firedAt: Date()
            )
        ]
    }

    func acknowledgeAlert(_ alert: Alert) {
        // TODO: Implement acknowledge mutation
        print("Acknowledging alert \(alert.id)")
    }
}
