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

    static let mikeSchmidt = BaseballSticker(
        id: "sticker-mike-schmidt-hall-of-fame",
        playerName: "Mike Schmidt",
        teamName: "Philadelphia Phillies",
        position: "3B",
        jerseyNumber: "20",
        rarity: .legendary,
        tagline: "548 home runs. Ten Gold Gloves. One unforgettable Phillie.",
        systemImage: "figure.baseball",
        portraitURL: "https://img.mlbstatic.com/mlb-photos/image/upload/w_768,q_auto:best/v1/people/121836/headshot/67/current",
        animatedAvatarResourceName: nil
    )

    static let all = [hunterGoodman, mikeSchmidt]
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

    static let mikeSchmidtQuiz = BaseballDailyDrop(
        id: "player-quiz-mike-schmidt",
        eyebrow: "LEGENDS QUIZ",
        title: "Mike Schmidt Quiz",
        storyTitle: "Meet Michael Jack.",
        storyBody: "Prove you know No. 20 and earn a LEGENDARY Mike Schmidt card.",
        landingImageURL: "https://baseballhall.org/sites/default/files/styles/fullscreen_image_popup/public/Schmidt%20hero.jpg.jpeg?itok=BBedRApQ",
        stories: [
            BaseballQuizStory(
                id: "schmidt-four-homer-game",
                title: "Four Homers. One Borrowed Bat.",
                subtitle: "On April 17, 1976, Schmidt borrowed Tony Taylor’s bat and homered in four straight at-bats at Wrigley Field.",
                imageURL: "https://baseballhall.org/sites/default/files/styles/fullscreen_image_popup/public/Schmidt%20Mike%20PA73-1044_Bat_NBLMcWilliams.jpg.jpeg?itok=jqry5n1M"
            ),
            BaseballQuizStory(
                id: "schmidt-1980",
                title: "The Year He Had It All.",
                subtitle: "In 1980, Schmidt hit 48 homers, won NL MVP and World Series MVP, and delivered Philadelphia’s first championship.",
                imageURL: "https://baseballhall.org/sites/default/files/styles/fullscreen_image_popup/public/Schmidt%20hero.jpg.jpeg?itok=BBedRApQ"
            ),
            BaseballQuizStory(
                id: "schmidt-500",
                title: "No. 500 Won The Game.",
                subtitle: "Schmidt’s 500th homer was a go-ahead, three-run shot in the ninth inning at Pittsburgh on April 18, 1987.",
                imageURL: "https://img.mlbstatic.com/mlb-images/image/private/t_2x1/t_w1536/mlb/hr45cmr7p9qjbkyv3l46.jpg"
            ),
        ],
        questions: [
            BaseballQuizQuestion(
                id: "schmidt-four-homer-game",
                question: "How many home runs did Mike Schmidt hit at Wrigley Field on April 17, 1976?",
                answers: ["Two", "Four", "Three", "Five"],
                correctAnswerIndex: 1,
                fact: "Schmidt homered in four straight at-bats as Philadelphia rallied from 12–1 down to win 18–16.",
                imageURL: "https://baseballhall.org/sites/default/files/styles/fullscreen_image_popup/public/Schmidt%20Mike%20PA73-1044_Bat_NBLMcWilliams.jpg.jpeg?itok=jqry5n1M"
            ),
            BaseballQuizQuestion(
                id: "schmidt-1980-homers",
                question: "How many home runs did Schmidt hit during his MVP season in 1980?",
                answers: ["44", "52", "48", "40"],
                correctAnswerIndex: 2,
                fact: "Schmidt’s career-high 48 homers helped carry the Phillies to their first World Series championship.",
                imageURL: "https://baseballhall.org/sites/default/files/styles/fullscreen_image_popup/public/Schmidt%20hero.jpg.jpeg?itok=BBedRApQ"
            ),
            BaseballQuizQuestion(
                id: "schmidt-career-homers",
                question: "How many career home runs did Mike Schmidt hit?",
                answers: ["548", "512", "536", "500"],
                correctAnswerIndex: 0,
                fact: "Schmidt retired in 1989 with 548 home runs, all of them as a Philadelphia Phillie.",
                imageURL: "https://img.mlbstatic.com/mlb-images/image/private/t_2x1/t_w1536/mlb/hr45cmr7p9qjbkyv3l46.jpg"
            ),
        ],
        minimumCorrectAnswers: 1,
        rewardSticker: BaseballStickerCatalog.mikeSchmidt,
        hostThought: "Four homers, ten Gold Gloves, 548 career bombs. Let’s see what you know about Michael Jack."
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
