import XCTest
@testable import CollegeFootballCommish

final class AnimatedHostPlaybackTests: XCTestCase {
    func testNumericalFrameSorting() {
        let input = ["seq_0_10.png", "seq_0_2.png", "seq_0_1.png"].map {
            URL(fileURLWithPath: $0)
        }
        let result = input
            .sorted(by: NumericalFrameSorter.areInIncreasingOrder)
            .map(\.lastPathComponent)

        XCTAssertEqual(result, ["seq_0_1.png", "seq_0_2.png", "seq_0_10.png"])
    }

    func testAnimationConfigurationCoversEveryAction() {
        XCTAssertEqual(
            Set(AnimationConfiguration.definitions.keys),
            Set(CommishAction.allCases)
        )
        XCTAssertEqual(
            AnimationConfiguration.definition(for: .idle).playbackMode,
            .loop
        )
        XCTAssertEqual(
            AnimationConfiguration.definition(for: .foamFinger).playbackMode,
            .oneShotThenIdle
        )
        XCTAssertEqual(
            AnimationConfiguration.definition(for: .wave).framesPerSecond,
            24
        )
    }

    func testOneShotCompletionReturnsCursorToIdle() {
        var cursor = AnimationPlaybackCursor()
        cursor.begin(.pointRight)

        for _ in 0..<2 {
            XCTAssertFalse(
                cursor.advance(frameCount: 3, mode: .oneShotThenIdle)
            )
        }

        XCTAssertTrue(
            cursor.advance(frameCount: 3, mode: .oneShotThenIdle)
        )
        XCTAssertEqual(cursor.action, .idle)
        XCTAssertEqual(cursor.frameIndex, 0)
    }

    @MainActor
    func testMissingRiveFileSelectsPngFallback() {
        let renderer = AdaptiveCommishController(bundle: .main)

        XCTAssertEqual(renderer.rendererName, "PNG fallback")
        XCTAssertEqual(
            renderer.fallbackReason,
            "commish.riv is not in the app bundle."
        )
    }
}
