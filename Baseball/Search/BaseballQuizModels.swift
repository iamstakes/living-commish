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
    let landingImageURL: String
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
    static let rockiesOriginsQuiz = BaseballDailyDrop(
        id: "daily-drop-rockies-origins",
        eyebrow: "DAILY DROP",
        title: "Rockies Quiz",
        storyTitle: "Meet the Rox!",
        storyBody: "Win a RARE reward for taking today’s quiz.",
        landingImageURL: "https://wp-cpr.s3.amazonaws.com/uploads/2019/06/rockies-mile-high-stadium1_0-1.jpg",
        stories: [
            BaseballQuizStory(
                id: "rockies-first-selection",
                title: "The Very First Rockie.",
                subtitle: "Colorado used the first pick in the 1992 Expansion Draft on right-hander David Nied.",
                imageURL: "https://img.mlbstatic.com/mlb-images/image/private/ar_9:16,g_auto,q_auto:good,w_900,c_fill,f_jpg/mlb/fzdcf30t9wxcpjkf8l9k"
            ),
            BaseballQuizStory(
                id: "rockies-first-home-game",
                title: "80,227 Fans. One New Home.",
                subtitle: "On April 9, 1993, the Rockies debuted at Mile High Stadium—and beat Montreal 11–4.",
                imageURL: "https://wp-cpr.s3.amazonaws.com/uploads/2019/06/rockies-mile-high-stadium1_0-1.jpg"
            ),
            BaseballQuizStory(
                id: "rockies-first-home-run",
                title: "The First Rockies Homer.",
                subtitle: "Dante Bichette launched the franchise’s first home run at Shea Stadium on April 7, 1993.",
                imageURL: "https://img.mlbstatic.com/mlb-photos/image/upload/w_768,q_auto:best/v1/people/110974/headshot/67/current"
            ),
        ],
        questions: [
            BaseballQuizQuestion(
                id: "rockies-first-selection",
                question: "Who was the first player Colorado selected in the 1992 Expansion Draft?",
                answers: [
                    "David Nied",
                    "Dante Bichette",
                    "Andrés Galarraga",
                    "Eric Young",
                ],
                correctAnswerIndex: 0,
                fact: "The Rockies made right-hander David Nied the first pick of the 1992 Expansion Draft.",
                imageURL: "https://img.mlbstatic.com/mlb-images/image/private/ar_16:9,g_auto,q_auto:good,w_1536,c_fill,f_jpg/mlb/fzdcf30t9wxcpjkf8l9k"
            ),
            BaseballQuizQuestion(
                id: "rockies-first-home-ballpark",
                question: "Where did the Rockies play their first home game?",
                answers: [
                    "Coors Field",
                    "Mile High Stadium",
                    "Bears Stadium",
                    "Shea Stadium",
                ],
                correctAnswerIndex: 1,
                fact: "A crowd of 80,227 packed Mile High Stadium for Colorado’s first home game on April 9, 1993.",
                imageURL: "https://wp-cpr.s3.amazonaws.com/uploads/2019/06/rockies-mile-high-stadium1_0-1.jpg"
            ),
            BaseballQuizQuestion(
                id: "rockies-first-home-run",
                question: "Who hit the first home run in Rockies history?",
                answers: [
                    "Eric Young",
                    "Andrés Galarraga",
                    "Dante Bichette",
                    "Charlie Hayes",
                ],
                correctAnswerIndex: 2,
                fact: "Dante Bichette hit the franchise’s first homer at Shea Stadium on April 7, 1993.",
                imageURL: "https://img.mlbstatic.com/mlb-images/image/private/ar_16:9,g_auto,q_auto:good,w_1536,c_fill,f_jpg/mlb/fcfhgkkwv82l6xat3mzv"
            ),
        ],
        minimumCorrectAnswers: 1,
        rewardSticker: BaseballStickerCatalog.hunterGoodman,
        hostThought: "Three Rockies firsts. One rare reward. Let’s meet the Rox."
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
