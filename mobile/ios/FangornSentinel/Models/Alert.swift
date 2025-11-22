import Foundation

struct Alert: Identifiable, Codable {
    let id: Int
    let title: String
    let message: String?
    let severity: Severity
    let status: Status
    let firedAt: Date
    let acknowledgedAt: Date?
    let source: String?

    enum Severity: String, Codable {
        case critical
        case warning
        case info

        var color: String {
            switch self {
            case .critical: return "red"
            case .warning: return "orange"
            case .info: return "blue"
            }
        }
    }

    enum Status: String, Codable {
        case firing
        case acknowledged
        case resolved
    }

    init(id: Int, title: String, message: String?, severity: Severity, status: Status, firedAt: Date, acknowledgedAt: Date? = nil, source: String? = nil) {
        self.id = id
        self.title = title
        self.message = message
        self.severity = severity
        self.status = status
        self.firedAt = firedAt
        self.acknowledgedAt = acknowledgedAt
        self.source = source
    }
}
