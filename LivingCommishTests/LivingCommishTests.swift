import FoundationModels
import SwiftData
import XCTest
@testable import LivingCommish

final class LivingCommishTests: XCTestCase {
    @MainActor
    func testAppleFoundationModelsMinimalDiagnostic() async throws {
        guard SystemLanguageModel.default.isAvailable else {
            throw XCTSkip("Apple Foundation Models is unavailable in this test environment.")
        }

        var defaultFailure = "none"
        do {
            let session = LanguageModelSession(instructions: "Answer plainly and briefly.")
            let response = try await session.respond(to: "Reply with exactly: model works")
            XCTAssertFalse(response.content.isEmpty)
            print("Default guardrails response: \(response.content)")
            return
        } catch {
            defaultFailure = String(reflecting: error)
            print("Default guardrails failed: \(defaultFailure)")
        }

        let permissiveModel = SystemLanguageModel(
            useCase: .general,
            guardrails: .permissiveContentTransformations
        )
        do {
            let session = LanguageModelSession(model: permissiveModel, instructions: "Answer plainly and briefly.")
            let response = try await session.respond(to: "Reply with exactly: model works")
            XCTAssertFalse(response.content.isEmpty)
            print("Permissive guardrails response: \(response.content)")
        } catch {
            XCTFail(
                """
                Minimal schema-free generation failed with both supported guardrail configurations.
                Default: \(defaultFailure)
                Permissive: \(String(reflecting: error))
                """
            )
        }
    }

    func testNumericalFrameSorting() {
        let input = ["seq_0_10.png", "seq_0_2.png", "seq_0_1.png"].map { URL(fileURLWithPath: $0) }
        let result = input.sorted(by: NumericalFrameSorter.areInIncreasingOrder).map(\.lastPathComponent)
        XCTAssertEqual(result, ["seq_0_1.png", "seq_0_2.png", "seq_0_10.png"])
    }

    func testGeneratedControlLabelsAreRemovedFromSpokenLines() {
        XCTAssertEqual(
            CommishLineSanitizer.sanitize("Wave! Ohio State just raised Penn State's blood pressure."),
            "Ohio State just raised Penn State's blood pressure."
        )
        XCTAssertEqual(
            CommishLineSanitizer.sanitize("PointRight: Penn State, take notes."),
            "Penn State, take notes."
        )
        XCTAssertEqual(
            CommishLineSanitizer.sanitize("Penn State's revenge board needs an annex. PointRight"),
            "Penn State's revenge board needs an annex."
        )
        XCTAssertEqual(
            CommishLineSanitizer.sanitize("Wave goodbye to a quiet offseason."),
            "Wave goodbye to a quiet offseason."
        )
    }

    func testGeneratedRecruitingLineRejectsStrangeIdiomAndInventedUnit() {
        let event = "Ohio State just signed a 5-star recruit!"
        let strange = "Ohio State, you're a juggler. Your 5-star recruit is a ball. Penn State's offense will drop the ball."
        XCTAssertNotNil(
            CommishGeneratedLinePolicy.rejectionReason(for: strange, eventText: event)
        )
        XCTAssertNotNil(
            CommishGeneratedLinePolicy.rejectionReason(
                for: "Penn State is now in the same elite tier as Ohio State.",
                eventText: event
            )
        )
        XCTAssertNotNil(
            CommishGeneratedLinePolicy.rejectionReason(
                for: "Ohio State's five-star recruit is a blow to Penn State.",
                eventText: event
            )
        )

        let grounded = "Ohio State added elite talent; Penn State's margin for error just got smaller."
        XCTAssertNil(
            CommishGeneratedLinePolicy.rejectionReason(for: grounded, eventText: event)
        )
    }

    func testAnimationConfigurationCoversEveryAction() {
        XCTAssertEqual(Set(AnimationConfiguration.definitions.keys), Set(CommishAction.allCases))
        XCTAssertEqual(AnimationConfiguration.definition(for: .idle).playbackMode, .loop)
        XCTAssertEqual(AnimationConfiguration.definition(for: .foamFinger).playbackMode, .oneShotThenIdle)
        XCTAssertEqual(AnimationConfiguration.definition(for: .wave).framesPerSecond, 24)
    }

    func testOneShotCompletionReturnsCursorToIdle() {
        var cursor = AnimationPlaybackCursor()
        cursor.begin(.pointRight)
        for _ in 0..<2 {
            XCTAssertFalse(cursor.advance(frameCount: 3, mode: .oneShotThenIdle))
        }
        XCTAssertTrue(cursor.advance(frameCount: 3, mode: .oneShotThenIdle))
        XCTAssertEqual(cursor.action, .idle)
        XCTAssertEqual(cursor.frameIndex, 0)
    }

    @MainActor
    func testDeterministicEventMappings() async throws {
        let provider = DeterministicCommishProvider()
        let profile = FanProfile(
            favoriteTeam: "Penn State",
            rivalTeam: "Ohio State",
            preferredCommishTone: "playful",
            currentStreak: 7,
            oregonHelmetsCracked: 3,
            ohioStateHelmetsCracked: 1
        )
        let cases: [(String, CommishAction)] = [
            ("I cracked another Oregon helmet.", .foamFinger),
            ("I lost my seven-day streak.", .sadShrug),
            ("Explain why this matters.", .pointRight),
            ("Hello Commish", .wave),
            ("Something unusual happened.", .idle),
        ]
        for (event, expected) in cases {
            let fanEvent = FanEvent(text: event)
            let brief = ReactionBriefBuilder.build(for: fanEvent, profile: profile)
            let reaction = try await provider.react(to: fanEvent, brief: brief)
            XCTAssertEqual(reaction.action, expected)
            XCTAssertLessThanOrEqual(reaction.line.split(whereSeparator: { $0.isWhitespace }).count, 18)
        }
    }

    @MainActor
    func testDominantFinalProducesSpecificEmotionalReaction() async throws {
        let provider = DeterministicCommishProvider()
        let event = FanEvent(text: "Argentina was embarrassed by Spain in the World Cup Final.")
        let reaction = try await provider.react(
            to: event,
            brief: ReactionBriefBuilder.build(for: event, profile: nil)
        )

        XCTAssertEqual(reaction.action, .sadShrug)
        XCTAssertEqual(reaction.emotion, .disappointed)
        XCTAssertTrue(reaction.line.contains("Argentina"))
        XCTAssertTrue(reaction.line.contains("Spain"))
        XCTAssertFalse(reaction.line.contains("noted your take"))
        XCTAssertLessThanOrEqual(reaction.line.split(whereSeparator: { $0.isWhitespace }).count, 18)
    }

    func testMemoryCandidateRequiresValueGroundedInEvent() {
        let event = FanEvent(text: "My favorite team is Michigan.")
        let valid = CommishReaction(line: "Michigan noted.", action: .idle, emotion: .neutral, memoryDecision: .favoriteTeam, memoryValue: "Michigan")
        XCTAssertEqual(MemoryPolicy.validatedCandidate(event: event, reaction: valid)?.value, "Michigan")

        let invented = CommishReaction(line: "Noted.", action: .idle, emotion: .neutral, memoryDecision: .favoriteTeam, memoryValue: "Texas")
        XCTAssertNil(MemoryPolicy.validatedCandidate(event: event, reaction: invented))
    }

    @MainActor
    func testProfileBackedMemoryUsesSingleCanonicalProfile() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FanProfile.self,
            CommishMemory.self,
            ReactionFeedback.self,
            LearnedReactionPreference.self,
            configurations: configuration
        )
        let store = CommishMemoryStore(context: container.mainContext)
        let candidate = MemoryCandidate(category: .favoriteTeam, value: "Penn State", confidence: 1)
        XCTAssertTrue(store.save(candidate))
        XCTAssertFalse(store.save(.init(category: .favoriteTeam, value: "penn state", confidence: 1)))
        XCTAssertEqual(store.profile()?.favoriteTeam, "penn state")
        XCTAssertEqual(store.memories().count, 0)
    }

    @MainActor
    func testRecurringMemoryStillDeduplicates() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FanProfile.self,
            CommishMemory.self,
            ReactionFeedback.self,
            LearnedReactionPreference.self,
            configurations: configuration
        )
        let store = CommishMemoryStore(context: container.mainContext)
        let candidate = MemoryCandidate(category: .recurringInterest, value: "College football", confidence: 1)
        XCTAssertTrue(store.save(candidate))
        XCTAssertFalse(store.save(.init(category: .recurringInterest, value: "college football", confidence: 1)))
        XCTAssertEqual(store.memories().count, 1)
    }

    func testReactionBriefAlwaysCarriesFanPerspective() {
        let profile = FanProfile(favoriteTeam: "Penn State", rivalTeam: "Ohio State", preferredCommishTone: "playful", currentStreak: 7, oregonHelmetsCracked: 3, ohioStateHelmetsCracked: 1)
        let helmet = ReactionBriefBuilder.build(for: FanEvent(text: "I cracked another Oregon helmet."), profile: profile)
        XCTAssertEqual(helmet.favoriteTeam, "Penn State")
        XCTAssertEqual(helmet.opponent, "Oregon")
        XCTAssertEqual(helmet.opponentHelmetCount, 3)
        XCTAssertNil(helmet.currentStreak)

        let greeting = ReactionBriefBuilder.build(for: FanEvent(text: "Hello"), profile: profile)
        XCTAssertEqual(greeting.favoriteTeam, "Penn State")
        XCTAssertEqual(greeting.rivalTeam, "Ohio State")
        XCTAssertNil(greeting.currentStreak)
    }

    func testWhiteoutAttendanceProducesHighArousalCelebration() {
        let profile = FanProfile(
            favoriteTeam: "Penn State",
            rivalTeam: "Ohio State",
            preferredCommishTone: "playful",
            currentStreak: 7,
            oregonHelmetsCracked: 3,
            ohioStateHelmetsCracked: 1
        )
        let brief = ReactionBriefBuilder.build(
            for: FanEvent(text: "I’m going to the Whiteout game!!!"),
            profile: profile
        )

        XCTAssertEqual(brief.topic, .attendance)
        XCTAssertEqual(brief.signals.intent, .attendance)
        XCTAssertGreaterThanOrEqual(brief.signals.valence, 0.7)
        XCTAssertGreaterThanOrEqual(brief.signals.arousal, 0.7)
        XCTAssertTrue(brief.signals.isAnticipatory)
        XCTAssertTrue(brief.signals.isFavoriteTradition)
        XCTAssertEqual(brief.relationship, .favorite)
        XCTAssertEqual(brief.desiredAction, .foamFinger)
        XCTAssertEqual(brief.desiredEmotion, .celebratory)
    }

    @MainActor
    func testExplicitCorrectionChangesFutureSimilarReaction() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FanProfile.self,
            CommishMemory.self,
            ReactionFeedback.self,
            LearnedReactionPreference.self,
            configurations: configuration
        )
        let store = CommishMemoryStore(context: container.mainContext)
        let profile = FanProfile(
            favoriteTeam: "Penn State",
            rivalTeam: "Ohio State",
            preferredCommishTone: "playful",
            currentStreak: 7,
            oregonHelmetsCracked: 3,
            ohioStateHelmetsCracked: 1
        )
        let event = FanEvent(text: "I’m going to the Whiteout game!!!")
        let initial = ReactionBriefBuilder.build(for: event, profile: profile)
        XCTAssertEqual(initial.desiredAction, .foamFinger)
        XCTAssertEqual(initial.desiredEmotion, .celebratory)

        XCTAssertTrue(
            store.recordReactionFeedback(
                ReactionFeedbackSnapshot(
                    eventText: event.text,
                    featureKeys: initial.learningFeatureKeys,
                    predictedAction: initial.desiredAction,
                    predictedEmotion: initial.desiredEmotion,
                    providerName: "Test",
                    line: "Whiteout confirmed."
                ),
                correction: .encourage
            )
        )

        let learned = ReactionBriefBuilder.build(
            for: event,
            profile: profile,
            adjustments: store.policyAdjustments()
        )
        XCTAssertEqual(learned.desiredAction, .wave)
        XCTAssertEqual(learned.desiredEmotion, .encouraging)
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<ReactionFeedback>()).count, 1)
        XCTAssertFalse(try container.mainContext.fetch(FetchDescriptor<LearnedReactionPreference>()).isEmpty)
    }

    @MainActor
    func testRivalRecruitingProducesPersonalizedIrritation() async throws {
        let profile = FanProfile(
            favoriteTeam: "Penn State",
            rivalTeam: "Ohio State",
            preferredCommishTone: "playful",
            currentStreak: 7,
            oregonHelmetsCracked: 3,
            ohioStateHelmetsCracked: 1
        )
        let event = FanEvent(text: "Ohio State just signed a 5-star recruit!")
        let brief = ReactionBriefBuilder.build(for: event, profile: profile)

        XCTAssertEqual(brief.topic, .recruiting)
        XCTAssertEqual(brief.actor, "Ohio State")
        XCTAssertEqual(brief.relationship, .rival)
        XCTAssertEqual(brief.fanImpact, .negative)
        XCTAssertEqual(brief.desiredEmotion, .annoyed)
        XCTAssertTrue(brief.compactPrompt.contains("increasing competitive pressure on the favorite team"))

        let reaction = try await DeterministicCommishProvider().react(to: event, brief: brief)
        XCTAssertEqual(reaction.action, .pointRight)
        XCTAssertEqual(reaction.emotion, .annoyed)
        XCTAssertFalse(reaction.line.localizedCaseInsensitiveContains("juggler"))
        XCTAssertFalse(reaction.line.localizedCaseInsensitiveContains("offense"))
        XCTAssertTrue(reaction.line.contains("Ohio State"))
        XCTAssertTrue(reaction.line.contains("Penn State"))
        XCTAssertFalse(reaction.line.contains("group-chat evidence"))
        XCTAssertLessThanOrEqual(reaction.line.split(whereSeparator: { $0.isWhitespace }).count, 18)
    }

    @MainActor
    func testOpinionQuestionRequiresAReasonedPointOfView() async throws {
        let profile = FanProfile(
            favoriteTeam: "Penn State",
            rivalTeam: "Ohio State",
            preferredCommishTone: "playful",
            currentStreak: 7,
            oregonHelmetsCracked: 3,
            ohioStateHelmetsCracked: 1
        )
        let event = FanEvent(text: "Penn State's coach is great at building culture - what do you think?")
        let brief = ReactionBriefBuilder.build(for: event, profile: profile)

        XCTAssertEqual(brief.topic, .opinion)
        XCTAssertEqual(brief.relationship, .favorite)
        XCTAssertEqual(brief.desiredAction, .pointRight)

        let reaction = try await DeterministicCommishProvider().react(to: event, brief: brief)
        XCTAssertTrue(reaction.line.contains("Penn State"))
        XCTAssertFalse(reaction.line.contains("made news"))
        XCTAssertLessThanOrEqual(reaction.line.split(whereSeparator: { $0.isWhitespace }).count, 18)
    }

    func testStructuredResponseLengthEnforcement() {
        let words = Array(repeating: "word", count: 19).joined(separator: " ")
        let reaction = CommishReaction(line: words, action: .idle, emotion: .neutral, memoryDecision: .none, memoryValue: nil)
        XCTAssertThrowsError(try CommishReactionValidator.validate(reaction))
    }

    func testInvalidActionIsRejectedByRawValue() {
        XCTAssertNil(CommishAction(rawValue: "dance"))
    }

    @MainActor
    func testFoundationModelsCanBeForcedThroughLocalFallback() async throws {
        let intelligence = AdaptiveCommishIntelligenceProvider(forceLocalFallback: true)
        let event = FanEvent(text: "I lost my seven-day streak.")
        let reaction = try await intelligence.react(
            to: event,
            brief: ReactionBriefBuilder.build(for: event, profile: nil)
        )
        XCTAssertTrue(intelligence.isAvailable)
        XCTAssertEqual(intelligence.providerName, "Personalized local")
        XCTAssertEqual(reaction.action, .sadShrug)
    }

    @MainActor
    func testMissingRiveFileSelectsPngFallback() {
        let renderer = AdaptiveCommishController(bundle: .main)
        XCTAssertEqual(renderer.rendererName, "PNG fallback")
        XCTAssertEqual(renderer.fallbackReason, "commish.riv is not in the app bundle.")
    }
}
