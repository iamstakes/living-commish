import Foundation

enum BaseballStickerRarity: String, Equatable, Sendable {
    case base
    case rare
    case legendary

    var displayName: String {
        rawValue.uppercased()
    }
}

struct BaseballSticker: Equatable, Identifiable, Sendable {
    let id: String
    let playerName: String
    let teamName: String
    let position: String
    let jerseyNumber: String
    let rarity: BaseballStickerRarity
    let tagline: String
    let systemImage: String
}

struct BaseballQuizQuestion: Equatable, Identifiable, Sendable {
    let id: String
    let question: String
    let answers: [String]
    let correctAnswerIndex: Int
    let fact: String
}

struct BaseballDailyDrop: Equatable, Identifiable, Sendable {
    let id: String
    let eyebrow: String
    let title: String
    let storyTitle: String
    let storyBody: String
    let questions: [BaseballQuizQuestion]
    let minimumCorrectAnswers: Int
    let rewardSticker: BaseballSticker
    let hostThought: String
}

enum BaseballStickerCatalog {
    static let hunterGoodman = BaseballSticker(
        id: "sticker-hunter-goodman-three-homer",
        playerName: "Hunter Goodman",
        teamName: "Colorado Rockies",
        position: "C / 1B",
        jerseyNumber: "15",
        rarity: .rare,
        tagline: "Three homers. One unforgettable afternoon.",
        systemImage: "figure.baseball"
    )

    static let all = [hunterGoodman]
}

enum BaseballDailyDropCatalog {
    static let hunterGoodmanThreeHomer = BaseballDailyDrop(
        id: "daily-drop-goodman-three-homer",
        eyebrow: "DAILY BASEBALL DROP",
        title: "Goodman goes deep",
        storyTitle: "Three swings changed the afternoon.",
        storyBody: "Hunter Goodman’s 30th home run was also his third homer of the game. Read the moment, answer three quick questions, and rip a pack for his first Living Commish sticker.",
        questions: [
            BaseballQuizQuestion(
                id: "goodman-player",
                question: "Which Rockies player hit three home runs in the featured game?",
                answers: ["Hunter Goodman", "Kris Bryant", "Ezequiel Tovar"],
                correctAnswerIndex: 0,
                fact: "Goodman’s 30th home run was his third homer of the game."
            ),
            BaseballQuizQuestion(
                id: "rockies-city",
                question: "The Rockies play their home games in which city?",
                answers: ["Phoenix", "Denver", "Salt Lake City"],
                correctAnswerIndex: 1,
                fact: "The Colorado Rockies play at Coors Field in Denver."
            ),
            BaseballQuizQuestion(
                id: "rockies-division",
                question: "Which division includes the Colorado Rockies?",
                answers: ["NL Central", "AL West", "NL West"],
                correctAnswerIndex: 2,
                fact: "Colorado competes in the National League West."
            ),
        ],
        minimumCorrectAnswers: 1,
        rewardSticker: BaseballStickerCatalog.hunterGoodman,
        hostThought: "Three quick questions. One pack. Let’s see what you know."
    )
}

@MainActor
protocol BaseballStickerStoring {
    func loadCollectedStickerIDs() -> Set<String>
    func saveCollectedStickerIDs(_ ids: Set<String>)
}

@MainActor
final class UserDefaultsBaseballStickerStore: BaseballStickerStoring {
    static let collectedStickerIDsKey = "baseball.collectedStickerIDs"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadCollectedStickerIDs() -> Set<String> {
        Set(
            defaults.stringArray(
                forKey: Self.collectedStickerIDsKey
            ) ?? []
        )
    }

    func saveCollectedStickerIDs(_ ids: Set<String>) {
        defaults.set(ids.sorted(), forKey: Self.collectedStickerIDsKey)
    }
}

@MainActor
final class InMemoryBaseballStickerStore: BaseballStickerStoring {
    private var collectedStickerIDs: Set<String>

    init(collectedStickerIDs: Set<String> = []) {
        self.collectedStickerIDs = collectedStickerIDs
    }

    func loadCollectedStickerIDs() -> Set<String> {
        collectedStickerIDs
    }

    func saveCollectedStickerIDs(_ ids: Set<String>) {
        collectedStickerIDs = ids
    }
}
