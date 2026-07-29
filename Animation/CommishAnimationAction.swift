import Foundation

enum CommishAction: String, Codable, CaseIterable, Sendable, Identifiable {
    case idle
    case pointRight
    case sadShrug
    case wave
    case foamFinger

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .idle: "Idle"
        case .pointRight: "Point Right"
        case .sadShrug: "Sad Shrug"
        case .wave: "Wave"
        case .foamFinger: "Foam Finger"
        }
    }
}
