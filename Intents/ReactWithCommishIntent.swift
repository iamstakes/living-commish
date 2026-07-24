import AppIntents
import Foundation

struct ReactWithCommishIntent: AppIntent {
    static let title: LocalizedStringResource = "React with Commish"
    static let description = IntentDescription("Open Living Commish with a short fan event ready for a private on-device reaction.")
    static let openAppWhenRun = true

    @Parameter(title: "Fan event", requestValueDialog: "What happened in Takes?")
    var eventDescription: String

    static var parameterSummary: some ParameterSummary {
        Summary("React to \(\.$eventDescription)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        UserDefaults.standard.set(eventDescription, forKey: "PendingCommishEvent")
        return .result(dialog: "Opening Living Commish for a private reaction.")
    }
}
struct LivingCommishShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ReactWithCommishIntent(),
            phrases: ["React with \(.applicationName)"],
            shortTitle: "React with Commish",
            systemImageName: "sparkles"
        )
    }
}
