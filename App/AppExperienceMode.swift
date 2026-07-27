import Foundation

enum AppExperienceMode: Equatable {
    case baseballSearch
    case livingCommish

    static func resolve(arguments: [String]) -> AppExperienceMode {
        if arguments.contains("--baseball-ui-testing") {
            return .baseballSearch
        }
        if arguments.contains("--legacy-commish") || arguments.contains("--ui-testing") {
            return .livingCommish
        }
        return .baseballSearch
    }
}
