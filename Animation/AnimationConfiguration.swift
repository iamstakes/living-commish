import Foundation

enum PlaybackMode: Sendable, Equatable {
    case loop
    case oneShotThenIdle
}
struct AnimationDefinition: Sendable, Equatable {
    let action: CommishAction
    let resourceDirectory: String
    let framesPerSecond: Double
    let playbackMode: PlaybackMode

    func duration(frameCount: Int) -> TimeInterval {
        Double(frameCount) / framesPerSecond
    }
}

enum AnimationConfiguration {
    static let definitions: [CommishAction: AnimationDefinition] = [
        .idle: .init(action: .idle, resourceDirectory: "idle", framesPerSecond: 24, playbackMode: .loop),
        .pointRight: .init(action: .pointRight, resourceDirectory: "point-right", framesPerSecond: 24, playbackMode: .oneShotThenIdle),
        .sadShrug: .init(action: .sadShrug, resourceDirectory: "sad-shrug", framesPerSecond: 24, playbackMode: .oneShotThenIdle),
        .wave: .init(action: .wave, resourceDirectory: "wave", framesPerSecond: 24, playbackMode: .oneShotThenIdle),
        .foamFinger: .init(action: .foamFinger, resourceDirectory: "foam-finger", framesPerSecond: 24, playbackMode: .oneShotThenIdle),
    ]

    static func definition(for action: CommishAction) -> AnimationDefinition {
        definitions[action]!
    }
}

enum NumericalFrameSorter {
    static func numbers(in filename: String) -> [Int] {
        filename.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
    }

    static func areInIncreasingOrder(_ lhs: URL, _ rhs: URL) -> Bool {
        let left = numbers(in: lhs.lastPathComponent)
        let right = numbers(in: rhs.lastPathComponent)
        for index in 0..<min(left.count, right.count) where left[index] != right[index] {
            return left[index] < right[index]
        }
        if left.count != right.count { return left.count < right.count }
        return lhs.lastPathComponent.localizedStandardCompare(rhs.lastPathComponent) == .orderedAscending
    }
}

struct AnimationPlaybackCursor: Equatable, Sendable {
    private(set) var action: CommishAction = .idle
    private(set) var frameIndex: Int = 0

    mutating func begin(_ action: CommishAction) {
        self.action = action
        frameIndex = 0
    }

    @discardableResult
    mutating func advance(frameCount: Int, mode: PlaybackMode) -> Bool {
        guard frameCount > 0 else { return false }
        frameIndex += 1
        if frameIndex < frameCount { return false }
        switch mode {
        case .loop:
            frameIndex = 0
            return false
        case .oneShotThenIdle:
            action = .idle
            frameIndex = 0
            return true
        }
    }
}
