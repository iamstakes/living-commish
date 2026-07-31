import Foundation

enum CollegeFootballStickerRarity: String, Equatable, Sendable {
    case rare
    case legendary

    var displayName: String {
        rawValue.uppercased()
    }
}

struct CollegeFootballSticker: Equatable, Identifiable, Sendable {
    let id: String
    let playerName: String
    let teamName: String
    let position: String
    let jerseyNumber: String
    let rarity: CollegeFootballStickerRarity
    let tagline: String
    let systemImage: String
    let portraitURL: String
    let animatedAvatarResourceName: String?
}

struct CollegeFootballQuizStory: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: String
}

struct CollegeFootballQuizQuestion: Equatable, Identifiable, Sendable {
    let id: String
    let question: String
    let answers: [String]
    let correctAnswerIndex: Int
    let fact: String
    let imageURL: String
}

struct CollegeFootballDailyDrop: Equatable, Identifiable, Sendable {
    let id: String
    let eyebrow: String
    let title: String
    let storyTitle: String
    let storyBody: String
    let landingImageURL: String
    let stories: [CollegeFootballQuizStory]
    let questions: [CollegeFootballQuizQuestion]
    let rewardSticker: CollegeFootballSticker
    let hostThought: String
}

enum CollegeFootballStickerCatalog {
    static let rashaanSalaam = CollegeFootballSticker(
        id: "sticker-rashaan-salaam-heisman",
        playerName: "Rashaan Salaam",
        teamName: "Colorado Buffaloes",
        position: "RB",
        jerseyNumber: "19",
        rarity: .rare,
        tagline: "2,055 yards. The first Colorado Heisman.",
        systemImage: "figure.american.football",
        portraitURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2016/5/12/1994_Salaam_Heisman422.jpg",
        animatedAvatarResourceName: nil
    )

    static let travisHunter = CollegeFootballSticker(
        id: "sticker-travis-hunter-heisman",
        playerName: "Travis Hunter",
        teamName: "Colorado Buffaloes",
        position: "CB / WR",
        jerseyNumber: "12",
        rarity: .legendary,
        tagline: "One player. Both sides. College football history.",
        systemImage: "figure.american.football",
        portraitURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2024/10/29/CUFB_v.Cincy_Selects_ATS-49.jpg",
        animatedAvatarResourceName: nil
    )

    static let all = [rashaanSalaam, travisHunter]
}

enum CollegeFootballDailyDropCatalog {
    static let buffsHistoryQuiz = CollegeFootballDailyDrop(
        id: "daily-drop-buffs-history",
        eyebrow: "DAILY DROP",
        title: "Buffs Quiz",
        storyTitle: "Meet the Buffs!",
        storyBody: "Win a RARE reward for taking today’s quiz.",
        landingImageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2017/2/14/Folsom_KSU_Great.jpg",
        stories: [
            CollegeFootballQuizStory(
                id: "buffs-national-title",
                title: "National Champions.",
                subtitle: "Colorado finished 11–1–1 and beat Notre Dame in the Orange Bowl to claim the 1990 national championship.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2017/2/14/Folsom_KSU_Great.jpg"
            ),
            CollegeFootballQuizStory(
                id: "buffs-folsom-field",
                title: "The Hilltop Since 1924.",
                subtitle: "Folsom Field opened as Colorado Stadium in 1924 and has been home to the Buffs ever since.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2017/2/14/Folsom_KSU_Great.jpg"
            ),
            CollegeFootballQuizStory(
                id: "buffs-first-heisman",
                title: "The First Colorado Heisman.",
                subtitle: "Rashaan Salaam ran for 2,055 yards in 1994 and became Colorado’s first Heisman Trophy winner.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2016/5/12/1994_Salaam_Heisman422.jpg"
            ),
        ],
        questions: [
            CollegeFootballQuizQuestion(
                id: "buffs-national-title-year",
                question: "Which season ended with Colorado’s first football national championship?",
                answers: ["1989", "1990", "1994", "2001"],
                correctAnswerIndex: 1,
                fact: "Colorado’s 1990 team went 11–1–1 and secured the program’s first national championship with an Orange Bowl win over Notre Dame.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2017/2/14/Folsom_KSU_Great.jpg"
            ),
            CollegeFootballQuizQuestion(
                id: "buffs-home-stadium",
                question: "What is the name of Colorado’s home football stadium?",
                answers: ["Mile High Stadium", "Folsom Field", "Canvas Stadium", "Balch Fieldhouse"],
                correctAnswerIndex: 1,
                fact: "Folsom Field opened in 1924 and has been the Buffaloes’ home for more than a century.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2017/2/14/Folsom_KSU_Great.jpg"
            ),
            CollegeFootballQuizQuestion(
                id: "buffs-first-heisman",
                question: "Who became Colorado’s first Heisman Trophy winner?",
                answers: ["Kordell Stewart", "Eric Bieniemy", "Rashaan Salaam", "Travis Hunter"],
                correctAnswerIndex: 2,
                fact: "Rashaan Salaam won the 1994 Heisman after rushing for a school-record 2,055 yards.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2016/5/12/1994_Salaam_Heisman422.jpg"
            ),
        ],
        rewardSticker: CollegeFootballStickerCatalog.rashaanSalaam,
        hostThought: "A title, a century on the hilltop, and a Heisman legend. Let’s meet the Buffs."
    )

    static let travisHunterQuiz = CollegeFootballDailyDrop(
        id: "player-quiz-travis-hunter",
        eyebrow: "LEGENDS QUIZ",
        title: "Travis Hunter Quiz",
        storyTitle: "Meet the two-way wonder.",
        storyBody: "Prove you know No. 12 and earn a LEGENDARY Travis Hunter card.",
        landingImageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2024/12/14/img_24989749_oN2iB.jpg",
        stories: [
            CollegeFootballQuizStory(
                id: "hunter-two-way",
                title: "Elite On Both Sides.",
                subtitle: "Hunter earned first-team All-America recognition on offense and defense in the same season.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2024/10/29/CUFB_v.Cincy_Selects_ATS-49.jpg"
            ),
            CollegeFootballQuizStory(
                id: "hunter-2024-numbers",
                title: "92 Catches. Four Picks.",
                subtitle: "His 2024 regular season paired 1,152 receiving yards and 14 touchdowns with four interceptions.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2023/9/6/Hunter_09022023-TCU-Selects-194.jpg"
            ),
            CollegeFootballQuizStory(
                id: "hunter-heisman",
                title: "Colorado’s Second Heisman.",
                subtitle: "Hunter won the 2024 Heisman Trophy, thirty years after Rashaan Salaam became the first Buff to win it.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2024/12/14/img_24989749_oN2iB.jpg"
            ),
        ],
        questions: [
            CollegeFootballQuizQuestion(
                id: "hunter-positions",
                question: "Which two positions did Travis Hunter play at Colorado?",
                answers: ["QB and Safety", "CB and Wide Receiver", "RB and Linebacker", "TE and Edge"],
                correctAnswerIndex: 1,
                fact: "Hunter starred at cornerback and wide receiver, playing full-time snaps on both sides of the ball.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2024/10/29/CUFB_v.Cincy_Selects_ATS-49.jpg"
            ),
            CollegeFootballQuizQuestion(
                id: "hunter-receptions",
                question: "How many regular-season catches did Hunter make in his Heisman season?",
                answers: ["72", "84", "92", "101"],
                correctAnswerIndex: 2,
                fact: "Hunter made 92 catches for 1,152 yards and 14 touchdowns during the 2024 regular season.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2023/9/6/Hunter_09022023-TCU-Selects-194.jpg"
            ),
            CollegeFootballQuizQuestion(
                id: "hunter-heisman-predecessor",
                question: "Who was Colorado’s other Heisman Trophy winner before Hunter?",
                answers: ["Rashaan Salaam", "Kordell Stewart", "Byron White", "Eric Bieniemy"],
                correctAnswerIndex: 0,
                fact: "Rashaan Salaam won Colorado’s first Heisman Trophy in 1994; Hunter became the second in 2024.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2024/12/14/img_24989749_oN2iB.jpg"
            ),
        ],
        rewardSticker: CollegeFootballStickerCatalog.travisHunter,
        hostThought: "Receiver. Corner. Heisman winner. Let’s see how well you know No. 12."
    )
}

@MainActor
protocol CollegeFootballStickerStoring {
    func loadCollectedStickerIDs() -> Set<String>
    func saveCollectedStickerIDs(_ ids: Set<String>)
    func loadAvatarStickerID() -> String?
    func saveAvatarStickerID(_ id: String?)
}

@MainActor
final class UserDefaultsCollegeFootballStickerStore: CollegeFootballStickerStoring {
    static let collectedStickerIDsKey = "collegeFootball.collectedStickerIDs"
    static let avatarStickerIDKey = "collegeFootball.avatarStickerID"

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
final class InMemoryCollegeFootballStickerStore: CollegeFootballStickerStoring {
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
