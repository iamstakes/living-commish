import SwiftUI

private enum BaseballDailyDropStage: Int, Equatable {
    case story
    case quiz
    case locked
    case pack
    case sticker

    var progressIndex: Int {
        switch self {
        case .story: 0
        case .quiz, .locked: 1
        case .pack: 2
        case .sticker: 3
        }
    }
}

private enum WorldCupPackMotionPhase: CaseIterable {
    case rest
    case liftLeft
    case swingRight
    case settle

    var rotation: Double {
        switch self {
        case .rest, .settle: 0
        case .liftLeft: -2
        case .swingRight: 2
        }
    }

    var yOffset: CGFloat {
        switch self {
        case .liftLeft: -5
        case .rest, .swingRight, .settle: 0
        }
    }
}

private struct BaseballStoryBeat {
    let kicker: String
    let title: String
    let body: String
    let color: Color
}

struct BaseballDailyDropDiscoveryCardContent: View {
    let drop: BaseballDailyDrop
    let isCollected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(drop.eyebrow, systemImage: "sparkles")
                    .font(.system(size: 9, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(.purple)

                Spacer()

                Image(
                    systemName: isCollected
                        ? "checkmark.seal.fill"
                        : "arrow.up.right"
                )
                .font(.caption.bold())
                .foregroundStyle(isCollected ? .mint : .secondary)
            }

            Spacer(minLength: 0)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                RockiesTheme.brightPurple,
                                .indigo,
                                .black,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 76, height: 72)

                Image(systemName: "baseball.fill")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.white)
            }

            Text(drop.title)
                .font(.title3.weight(.black))
                .foregroundStyle(.primary)

            Text(
                isCollected
                    ? "Replay today’s drop"
                    : "Story → quiz → pack → sticker"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(17)
        .frame(width: 230, height: 215, alignment: .leading)
        .background(
            RockiesTheme.brightPurple.opacity(0.16),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

struct BaseballDailyDropFullScreenView: View {
    let drop: BaseballDailyDrop
    let onCollect: (BaseballSticker) -> Void
    let onOpenCollection: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var wasAlreadyCollected: Bool
    @State private var stage: BaseballDailyDropStage = .story
    @State private var storyIndex = 0
    @State private var answers: [String: Int] = [:]
    @State private var packOpened = false
    @State private var stickerRotation = -90.0
    @State private var stickerOffset: CGFloat = 20
    @State private var stickerOpacity = 0.0
    @State private var didCollectSticker = false

    init(
        drop: BaseballDailyDrop,
        isAlreadyCollected: Bool,
        onCollect: @escaping (BaseballSticker) -> Void,
        onOpenCollection: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.drop = drop
        self.onCollect = onCollect
        self.onOpenCollection = onOpenCollection
        self.onDismiss = onDismiss
        _wasAlreadyCollected = State(initialValue: isAlreadyCollected)
    }

    var body: some View {
        ZStack {
            fullScreenBackground

            VStack(spacing: 0) {
                modalHeader

                ScrollView {
                    VStack(spacing: 18) {
                        flowRail

                        stageContent
                            .id(stage)
                            .transition(
                                reduceMotion
                                    ? .opacity
                                    : .asymmetric(
                                        insertion: .move(edge: .trailing)
                                            .combined(with: .opacity),
                                        removal: .move(edge: .leading)
                                            .combined(with: .opacity)
                                    )
                            )
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
        }
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("baseball-daily-drop-full-screen")
    }

    private var fullScreenBackground: some View {
        ZStack {
            Color(red: 0.027, green: 0.035, blue: 0.055)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    RockiesTheme.brightPurple.opacity(0.34),
                    .clear,
                    Color.orange.opacity(0.10),
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.cyan.opacity(0.12))
                .frame(width: 330, height: 330)
                .blur(radius: 70)
                .offset(x: -180, y: -310)

            Circle()
                .fill(Color.purple.opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: 190, y: 360)
        }
        .accessibilityHidden(true)
    }

    private var modalHeader: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.headline.weight(.black))
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Close daily baseball drop")
            .accessibilityIdentifier("daily-drop-close")

            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY’S DROP")
                    .font(.system(size: 9, weight: .black))
                    .tracking(1.8)
                    .foregroundStyle(.yellow)
                Text("Daily Baseball Drop")
                    .font(.headline.weight(.black))
                    .lineLimit(1)
            }

            Spacer()

            Label("1 sticker", systemImage: "gift.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(.purple)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(.white, in: Capsule())
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.black.opacity(0.28))
        .overlay(alignment: .bottom) {
            Divider().opacity(0.28)
        }
    }

    private var flowRail: some View {
        let steps = [
            ("Story", Color.mint),
            ("Quiz", Color.cyan),
            ("Pack", Color.yellow),
            ("Reveal", Color.purple),
        ]

        return HStack(spacing: 5) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                VStack(spacing: 6) {
                    Capsule()
                        .fill(
                            index <= stage.progressIndex
                                ? step.1
                                : Color.white.opacity(0.10)
                        )
                        .frame(height: 6)

                    Text(step.0.uppercased())
                        .font(.system(size: 8, weight: .black))
                        .tracking(0.5)
                        .foregroundStyle(
                            index == stage.progressIndex
                                ? .white
                                : .white.opacity(0.30)
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(13)
        .background(
            .white.opacity(0.045),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Daily drop progress, step \(stage.progressIndex + 1) of 4"
        )
    }

    @ViewBuilder
    private var stageContent: some View {
        switch stage {
        case .story:
            storyPanel
        case .quiz:
            quizPanel
        case .locked:
            lockedPanel
        case .pack:
            packPanel
        case .sticker:
            stickerRevealPanel
        }
    }

    private var storyPanel: some View {
        let beat = storyBeats[storyIndex]
        let isLastBeat = storyIndex == storyBeats.count - 1

        return VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [
                        beat.color.opacity(0.38),
                        RockiesTheme.brightPurple.opacity(0.20),
                        .black.opacity(0.30),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color.orange.opacity(0.22))
                    .frame(width: 210, height: 210)
                    .blur(radius: 38)
                    .offset(x: 190, y: 220)

                VStack(alignment: .leading, spacing: 0) {
                    Text(beat.kicker.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.7)
                        .foregroundStyle(.white.opacity(0.68))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.black.opacity(0.24), in: Capsule())

                    Spacer()

                    Image(systemName: storyIndex == 0 ? "baseball.fill" : "sparkles")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.bottom, 18)

                    Text(beat.title)
                        .font(.system(size: 34, weight: .black))
                        .fontWidth(.expanded)
                        .leadingTight()
                        .foregroundStyle(.white)

                    Text(beat.body)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.66))
                        .lineSpacing(4)
                        .padding(.top, 14)
                }
                .padding(22)
            }
            .frame(minHeight: 430)

            VStack(spacing: 16) {
                HStack(spacing: 7) {
                    ForEach(storyBeats.indices, id: \.self) { index in
                        Capsule()
                            .fill(
                                index <= storyIndex
                                    ? Color.yellow
                                    : Color.white.opacity(0.10)
                            )
                            .frame(height: 6)
                    }
                }

                Button {
                    if isLastBeat {
                        move(to: .quiz)
                    } else {
                        withAnimation(.easeInOut(duration: 0.24)) {
                            storyIndex += 1
                        }
                    }
                } label: {
                    Text(isLastBeat ? "Start Quiz" : "Tap Through")
                        .font(.subheadline.weight(.black))
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black)
                .background(Color.yellow, in: RoundedRectangle(cornerRadius: 17))
                .accessibilityIdentifier("daily-drop-start-quiz")
            }
            .padding(18)
            .background(.black.opacity(0.26))
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("daily-drop-story")
    }

    private var quizPanel: some View {
        VStack(spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("BLITZ QUIZ")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.8)
                        .foregroundStyle(.yellow)
                    Text("Get one right to unlock today’s pack.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.56))
                }

                Spacer()

                Text("\(answers.count) / \(drop.questions.count)")
                    .font(.caption.monospacedDigit().weight(.black))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.30), in: Capsule())
            }
            .padding(16)
            .background(
                Color.yellow.opacity(0.10),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.yellow.opacity(0.20), lineWidth: 1)
            }

            ForEach(Array(drop.questions.enumerated()), id: \.element.id) {
                index,
                question in
                quizQuestionCard(question, number: index + 1)
            }

            Button(action: submitQuiz) {
                Text(
                    answers.count == drop.questions.count
                        ? "Submit · \(score) right"
                        : "Answer all \(drop.questions.count)"
                )
                .font(.subheadline.weight(.black))
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, minHeight: 54)
            }
            .buttonStyle(.plain)
            .foregroundStyle(
                answers.count == drop.questions.count
                    ? Color.black
                    : Color.white.opacity(0.28)
            )
            .background(
                answers.count == drop.questions.count
                    ? Color.yellow
                    : Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .disabled(answers.count != drop.questions.count)
            .accessibilityIdentifier("quiz-submit-button")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("daily-drop-quiz")
    }

    private func quizQuestionCard(
        _ question: BaseballQuizQuestion,
        number: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 11) {
                Text("\(number)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black)
                    .frame(width: 29, height: 29)
                    .background(.white, in: Circle())

                Text(question.question)
                    .font(.headline.weight(.black))
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(Array(question.answers.enumerated()), id: \.offset) {
                answerIndex,
                answer in
                let selected = answers[question.id] == answerIndex

                Button {
                    answers[question.id] = answerIndex
                } label: {
                    Text(answer)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(selected ? .black : .white.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 48)
                        .background(
                            selected
                                ? Color.yellow
                                : Color.black.opacity(0.22),
                            in: RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                        )
                        .overlay {
                            RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                            .stroke(
                                selected
                                    ? Color.yellow
                                    : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                        }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(
                    "quiz-answer-\(question.id)-\(answerIndex)"
                )
            }
        }
        .padding(17)
        .background(
            .white.opacity(0.045),
            in: RoundedRectangle(cornerRadius: 23, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var lockedPanel: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 36)

            Image(systemName: "lock.fill")
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(.red)
                .frame(width: 86, height: 86)
                .background(Color.red.opacity(0.14), in: Circle())

            Text("No pack yet")
                .font(.system(size: 30, weight: .black))

            Text(
                "You finished with \(score) right. Today’s pack needs one correct answer."
            )
            .font(.body.weight(.semibold))
            .foregroundStyle(.white.opacity(0.58))
            .multilineTextAlignment(.center)

            Button(action: retryQuiz) {
                Text("Retry Quiz")
                    .font(.subheadline.weight(.black))
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, minHeight: 54)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(
                .white.opacity(0.10),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .accessibilityIdentifier("daily-drop-retry")

            Spacer(minLength: 36)
        }
        .padding(24)
        .background(
            Color.red.opacity(0.10),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.red.opacity(0.25), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("daily-drop-locked")
    }

    private var packPanel: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("PACK EARNED")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
                    .foregroundStyle(.purple.opacity(0.85))

                Text("\(score) / \(drop.questions.count) correct")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.52))
            }

            ZStack {
                RoundedRectangle(cornerRadius: 31, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 190, height: 276)
                    .shadow(
                        color: Color.purple.opacity(0.44),
                        radius: 44,
                        y: 24
                    )

                VStack {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.yellow)
                        Spacer()
                        Text("D1")
                            .foregroundStyle(.white.opacity(0.52))
                    }
                    .font(.caption.weight(.black))

                    Spacer()

                    Image(systemName: "baseball.fill")
                        .font(.system(size: 60, weight: .black))
                        .foregroundStyle(.yellow)

                    Text("BASEBALL\nPACK")
                        .font(.title2.weight(.black))
                        .multilineTextAlignment(.center)
                        .leadingTight()

                    Spacer()

                    Text("1 STICKER")
                        .font(.caption.weight(.black))
                        .tracking(1.8)
                        .foregroundStyle(.white.opacity(0.36))
                }
                .padding(22)
                .frame(width: 182, height: 268)
                .background(
                    Color(red: 0.027, green: 0.035, blue: 0.055),
                    in: RoundedRectangle(cornerRadius: 27, style: .continuous)
                )

                Capsule()
                    .fill(.white)
                    .frame(width: 148, height: 5)
                    .scaleEffect(
                        x: packOpened ? 1 : 0,
                        y: 1,
                        anchor: .leading
                    )
                    .offset(y: -83)
            }
            // Direct native port of the World Cup PackPanel:
            // 1.4s [0, -2, 2, 0] wobble, then a 0.35s rip/open.
            .phaseAnimator(
                reduceMotion
                    ? [WorldCupPackMotionPhase.rest]
                    : WorldCupPackMotionPhase.allCases
            ) { content, phase in
                content
                    .rotationEffect(
                        .degrees(packOpened ? -8 : phase.rotation)
                    )
                    .offset(y: packOpened ? -12 : phase.yOffset)
            } animation: { _ in
                .easeInOut(duration: 0.35)
            }
            .animation(.easeInOut(duration: 0.35), value: packOpened)
            .padding(.vertical, 12)

            Button(action: packButtonTapped) {
                Text(packOpened ? "Reveal Sticker" : "Swipe To Rip")
                    .font(.subheadline.weight(.black))
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
            .animation(nil, value: packOpened)
            .accessibilityIdentifier("rip-pack-button")
        }
        .padding(22)
        .background(
            Color(red: 0.071, green: 0.035, blue: 0.122),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.purple.opacity(0.25), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("daily-drop-pack")
    }

    private var stickerRevealPanel: some View {
        VStack(spacing: 20) {
            VStack(spacing: 5) {
                Text(wasAlreadyCollected ? "STICKER REPLAY" : "NEW STICKER")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
                    .foregroundStyle(.mint)

                Text("Pack reveal")
                    .font(.system(size: 30, weight: .black))
            }

            BaseballStickerCardView(
                sticker: drop.rewardSticker,
                size: .large
            )
            .rotation3DEffect(
                .degrees(stickerRotation),
                axis: (x: 0, y: 1, z: 0)
            )
            .offset(y: stickerOffset)
            .opacity(stickerOpacity)

            VStack(spacing: 8) {
                Label(
                    wasAlreadyCollected
                        ? "Already in your collection"
                        : "Added to your collection",
                    systemImage: "checkmark.seal.fill"
                )
                .font(.headline.weight(.black))
                .foregroundStyle(.mint)

                Text(drop.rewardSticker.tagline)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.56))
                    .multilineTextAlignment(.center)
            }

            Button(action: onOpenCollection) {
                Label("View Sticker Collection", systemImage: "square.grid.2x2.fill")
                    .font(.subheadline.weight(.black))
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .background(.mint, in: RoundedRectangle(cornerRadius: 18))
            .accessibilityIdentifier("daily-drop-open-collection")
        }
        .padding(24)
        .background(
            .white.opacity(0.045),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .onAppear(perform: revealSticker)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("daily-drop-sticker-reveal")
    }

    private var storyBeats: [BaseballStoryBeat] {
        [
            BaseballStoryBeat(
                kicker: "Today’s moment",
                title: drop.storyTitle,
                body: drop.storyBody,
                color: .cyan
            ),
            BaseballStoryBeat(
                kicker: "Momentum check",
                title: "One right answer opens the pack.",
                body: "No marathon. Three fast questions, one pack, one new sticker. Hit the beat and rip.",
                color: .yellow
            ),
            BaseballStoryBeat(
                kicker: "Collection chase",
                title: "\(drop.rewardSticker.playerName) is waiting.",
                body: "Finish the quiz and rip today’s pack to add the first sticker to your Living Commish collection.",
                color: .mint
            ),
        ]
    }

    private var score: Int {
        drop.questions.reduce(into: 0) { total, question in
            if answers[question.id] == question.correctAnswerIndex {
                total += 1
            }
        }
    }

    private func move(to nextStage: BaseballDailyDropStage) {
        withAnimation(.easeInOut(duration: reduceMotion ? 0 : 0.28)) {
            stage = nextStage
        }
    }

    private func submitQuiz() {
        guard answers.count == drop.questions.count else { return }
        move(
            to: score >= drop.minimumCorrectAnswers
                ? .pack
                : .locked
        )
    }

    private func retryQuiz() {
        answers = [:]
        move(to: .quiz)
    }

    private func packButtonTapped() {
        guard stage == .pack else { return }

        if !packOpened {
            withAnimation(.easeInOut(duration: reduceMotion ? 0 : 0.35)) {
                packOpened = true
            }
            return
        }

        move(to: .sticker)
    }

    private func revealSticker() {
        if !didCollectSticker {
            didCollectSticker = true
            onCollect(drop.rewardSticker)
        }

        guard !reduceMotion else {
            stickerRotation = 0
            stickerOffset = 0
            stickerOpacity = 1
            return
        }

        stickerRotation = -90
        stickerOffset = 20
        stickerOpacity = 0

        withAnimation(.easeOut(duration: 0.35)) {
            stickerRotation = 0
            stickerOffset = 0
            stickerOpacity = 1
        }
    }
}

enum BaseballStickerCardSize {
    case compact
    case large

    var width: CGFloat {
        switch self {
        case .compact: 138
        case .large: 220
        }
    }

    var height: CGFloat {
        switch self {
        case .compact: 184
        case .large: 294
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .compact: 45
        case .large: 78
        }
    }
}

struct BaseballStickerCardView: View {
    let sticker: BaseballSticker
    let size: BaseballStickerCardSize

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            RockiesTheme.brightPurple,
                            .indigo,
                            .black,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white, .cyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )

            VStack(spacing: size == .large ? 12 : 7) {
                HStack {
                    Text(sticker.rarity.displayName)
                    Spacer()
                    Text("#\(sticker.jerseyNumber)")
                }
                .font(.system(size: size == .large ? 11 : 8, weight: .black))
                .tracking(0.7)
                .foregroundStyle(.white.opacity(0.76))

                Spacer(minLength: 0)

                Image(systemName: sticker.systemImage)
                    .font(.system(size: size.iconSize, weight: .black))
                    .foregroundStyle(.white)
                    .frame(
                        width: size == .large ? 122 : 78,
                        height: size == .large ? 122 : 78
                    )
                    .background(.white.opacity(0.10), in: Circle())

                Text(sticker.playerName)
                    .font(
                        .system(
                            size: size == .large ? 20 : 15,
                            weight: .black
                        )
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(sticker.teamName) • \(sticker.position)")
                    .font(.system(size: size == .large ? 10 : 7, weight: .bold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)

                if size == .large {
                    Text(sticker.tagline)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.64))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(size == .large ? 18 : 13)
        }
        .frame(width: size.width, height: size.height)
        .shadow(
            color: RockiesTheme.brightPurple.opacity(0.38),
            radius: size == .large ? 32 : 14,
            y: size == .large ? 18 : 7
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(sticker.rarity.displayName) sticker, \(sticker.playerName), \(sticker.teamName), number \(sticker.jerseyNumber)"
        )
        .accessibilityIdentifier("profile-sticker-\(sticker.id)")
    }
}

private extension View {
    func leadingTight() -> some View {
        lineSpacing(-2)
    }
}
