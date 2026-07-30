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
    let portraitURL: String
    let animatedAvatarResourceName: String?
}

struct BaseballQuizStory: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: String
}

struct BaseballQuizQuestion: Equatable, Identifiable, Sendable {
    let id: String
    let question: String
    let answers: [String]
    let correctAnswerIndex: Int
    let fact: String
    let imageURL: String
}

struct BaseballDailyDrop: Equatable, Identifiable, Sendable {
    let id: String
    let eyebrow: String
    let title: String
    let storyTitle: String
    let storyBody: String
    let stories: [BaseballQuizStory]
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
        systemImage: "figure.baseball",
        portraitURL: "https://img.mlbstatic.com/mlb-photos/image/upload/w_426,q_auto:best/v1/people/696100/headshot/67/current",
        animatedAvatarResourceName: "hunter-goodman-avatar"
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
        stories: [
            BaseballQuizStory(
                id: "goodman-three-homers",
                title: "Three Swings. Three Homers.",
                subtitle: "Hunter Goodman turned a long afternoon into a place in Rockies history.",
                imageURL: "https://img.mlbstatic.com/mlb-images/image/upload/t_2x1/t_w1536/mlb/xqkkbneysjnvpbny2p7u.jpg"
            ),
            BaseballQuizStory(
                id: "goodman-thirty",
                title: "Number 30 Was The Exclamation Point.",
                subtitle: "His third blast of the game also made him the first Rockies catcher to reach 30.",
                imageURL: "https://img.mlbstatic.com/mlb-images/image/upload/t_2x1/t_w1536/v1782613141/mlb/d7pu6iwnksqssb7rffau.jpg"
            ),
            BaseballQuizStory(
                id: "goodman-collection",
                title: "Now Put Him In Your Collection.",
                subtitle: "Three questions stand between you and a Hunter Goodman player card.",
                imageURL: "https://img.mlbstatic.com/mlb-images/image/upload/t_2x1/t_w1536/mlb/xqkkbneysjnvpbny2p7u.jpg"
            ),
        ],
        questions: [
            BaseballQuizQuestion(
                id: "goodman-player",
                question: "Which Rockies player hit three home runs in the featured game?",
                answers: [
                    "Hunter Goodman",
                    "Kris Bryant",
                    "Ezequiel Tovar",
                    "Jordan Beck",
                ],
                correctAnswerIndex: 0,
                fact: "Goodman’s 30th home run was his third homer of the game.",
                imageURL: "https://img.mlbstatic.com/mlb-images/image/upload/t_2x1/t_w1536/mlb/xqkkbneysjnvpbny2p7u.jpg"
            ),
            BaseballQuizQuestion(
                id: "rockies-city",
                question: "The Rockies play their home games in which city?",
                answers: ["Phoenix", "Denver", "Salt Lake City", "Albuquerque"],
                correctAnswerIndex: 1,
                fact: "The Colorado Rockies play at Coors Field in Denver.",
                imageURL: "https://img.mlbstatic.com/mlb-images/image/upload/t_1x1/t_w1024/mlb/kjn9vfcy1ry12lgqtczi.jpg"
            ),
            BaseballQuizQuestion(
                id: "rockies-division",
                question: "Which division includes the Colorado Rockies?",
                answers: ["NL Central", "AL West", "NL West", "AL Central"],
                correctAnswerIndex: 2,
                fact: "Colorado competes in the National League West.",
                imageURL: "https://img.mlbstatic.com/mlb-images/image/upload/t_2x1/t_w1536/v1782613141/mlb/d7pu6iwnksqssb7rffau.jpg"
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
    func loadAvatarStickerID() -> String?
    func saveAvatarStickerID(_ id: String?)
}

@MainActor
final class UserDefaultsBaseballStickerStore: BaseballStickerStoring {
    static let collectedStickerIDsKey = "baseball.collectedStickerIDs"
    static let avatarStickerIDKey = "baseball.avatarStickerID"

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

    func loadAvatarStickerID() -> String? {
        defaults.string(forKey: Self.avatarStickerIDKey)
    }

    func saveAvatarStickerID(_ id: String?) {
        if let id {
            defaults.set(id, forKey: Self.avatarStickerIDKey)
        } else {
            defaults.removeObject(forKey: Self.avatarStickerIDKey)
        }
    }
}

@MainActor
final class InMemoryBaseballStickerStore: BaseballStickerStoring {
    private var collectedStickerIDs: Set<String>
    private var avatarStickerID: String?

    init(
        collectedStickerIDs: Set<String> = [],
        avatarStickerID: String? = nil
    ) {
        self.collectedStickerIDs = collectedStickerIDs
        self.avatarStickerID = avatarStickerID
    }

    func loadCollectedStickerIDs() -> Set<String> {
        collectedStickerIDs
    }

    func saveCollectedStickerIDs(_ ids: Set<String>) {
        collectedStickerIDs = ids
    }

    func loadAvatarStickerID() -> String? {
        avatarStickerID
    }

    func saveAvatarStickerID(_ id: String?) {
        avatarStickerID = id
    }
}
