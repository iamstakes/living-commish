import MetalKit
import RiveRuntime
import SwiftUI
import UIKit

// This flow is a baseball adaptation of the production Takes World Cup quiz
// implementation at commit 403e83b62d6656ce4ec981858bc177ed6ba0a223.
// Its full-screen story, single-question quiz, Commish celebration, Rive pack
// rip, card flip, and claim interactions intentionally retain that structure.

private enum BaseballDailyQuizPhase: Equatable {
    case landing
    case stories
    case quiz
    case reward(BaseballQuizResult)
}

struct BaseballQuizResult: Equatable {
    let correct: Int
    let total: Int
    let seconds: Int
    let points: Int

    var formattedTime: String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

struct BaseballDailyDropDiscoveryCardContent: View {
    let drop: BaseballDailyDrop
    let isCollected: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            BaseballRemoteImage(
                urlString: drop.landingImageURL,
                fallbackSystemImage: "mountain.2.fill"
            )
            .saturation(0.82)
            .contrast(1.08)

            LinearGradient(
                colors: [
                    .black.opacity(0.20),
                    .black.opacity(0.34),
                    BaseballQuizPalette.background.opacity(0.98),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 7) {
                    Label(drop.eyebrow, systemImage: "sparkles")
                        .font(.system(size: 9, weight: .black))
                        .tracking(0.9)
                        .foregroundStyle(.white)

                    Spacer(minLength: 4)

                    Text(isCollected ? "COLLECTED" : "BRAND NEW")
                        .font(.system(size: 8, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            isCollected
                                ? BaseballQuizPalette.correct
                                : Color.yellow,
                            in: Capsule()
                        )
                }

                Spacer(minLength: 0)

                Text(drop.title)
                    .font(.system(size: 26, weight: .black))
                    .fontWidth(.expanded)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.75), radius: 8, y: 2)

                HStack(spacing: 6) {
                    Image(
                        systemName: isCollected
                            ? "arrow.counterclockwise"
                            : "diamond.fill"
                    )
                    Text(
                        isCollected
                            ? "Replay today’s quiz"
                            : "Win a RARE reward"
                    )
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(
                    isCollected
                        ? Color.white.opacity(0.78)
                        : Color.yellow
                )
            }
            .padding(16)
        }
        .frame(width: 230, height: 215, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(
                    isCollected
                        ? Color.mint.opacity(0.55)
                        : Color.yellow.opacity(0.62),
                    lineWidth: 1.5
                )
        }
        .shadow(
            color: (isCollected ? Color.mint : Color.yellow).opacity(0.18),
            radius: 18,
            y: 8
        )
        .accessibilityElement(children: .combine)
    }
}

struct BaseballDailyDropFullScreenView: View {
    let drop: BaseballDailyDrop
    let onCollect: (BaseballSticker) -> Void
    let onOpenCollection: () -> Void
    let onDismiss: () -> Void

    @State private var phase: BaseballDailyQuizPhase = .landing

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
    }

    var body: some View {
        ZStack {
            BaseballQuizPalette.background
                .ignoresSafeArea()

            switch phase {
            case .landing:
                BaseballQuizLandingView(
                    drop: drop,
                    onClose: onDismiss,
                    onStart: {
                        BaseballQuizHaptics.affirm()
                        phase = .stories
                    }
                )
                .transition(.opacity)

            case .stories:
                BaseballQuizStoriesView(
                    stories: drop.stories,
                    onComplete: {
                        BaseballQuizHaptics.affirm()
                        phase = .quiz
                    },
                    onClose: onDismiss
                )
                .transition(.opacity)

            case .quiz:
                BaseballQuizQuestionsView(
                    questions: drop.questions,
                    onClose: onDismiss,
                    onComplete: { result in
                        phase = .reward(result)
                    }
                )
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(
                            with: .scale(scale: 0.96)
                        ),
                        removal: .opacity
                    )
                )

            case .reward(let result):
                BaseballQuizRewardView(
                    sticker: drop.rewardSticker,
                    result: result,
                    onClaim: {
                        onCollect(drop.rewardSticker)
                        onOpenCollection()
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(
            .spring(response: 0.5, dampingFraction: 0.85),
            value: phase
        )
        .preferredColorScheme(.dark)
    }
}

private enum BaseballQuizPalette {
    static let background = Color(
        red: 0.035,
        green: 0.049,
        blue: 0.090
    )
    static let auraCore = Color(
        red: 0.514,
        green: 0.071,
        blue: 0.929
    )
    static let auraLight = Color(
        red: 0.694,
        green: 0.342,
        blue: 1
    )
    static let correct = Color(
        red: 0.24,
        green: 1,
        blue: 0.45
    )
    static let wrong = Color(
        red: 1,
        green: 0.24,
        blue: 0.24
    )
}

@MainActor
private enum BaseballQuizHaptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func affirm() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func reject() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

private struct BaseballQuizCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Close Rockies Quiz")
        .accessibilityIdentifier("daily-drop-close")
    }
}

private struct BaseballQuizLandingView: View {
    let drop: BaseballDailyDrop
    let onClose: () -> Void
    let onStart: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            BaseballQuizPalette.background
                .ignoresSafeArea()

            BaseballRemoteImage(
                urlString: drop.landingImageURL,
                fallbackSystemImage: "mountain.2.fill"
            )
            .saturation(0.78)
            .contrast(1.12)
            .scaleEffect(appeared ? 1.03 : 1.1)
            .ignoresSafeArea()
            .accessibilityHidden(true)

            LinearGradient(
                colors: [
                    .black.opacity(0.54),
                    .black.opacity(0.10),
                    BaseballQuizPalette.background.opacity(0.96),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    RockiesTheme.brightPurple.opacity(0.52),
                    .clear,
                ],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    BaseballQuizCloseButton(action: onClose)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Text("BRAND NEW")
                            .font(.system(size: 11, weight: .black))
                            .tracking(1.1)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(Color.yellow, in: Capsule())

                        Text(drop.eyebrow)
                            .font(.system(size: 11, weight: .black))
                            .tracking(1.1)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(.black.opacity(0.42), in: Capsule())
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        Text(drop.title.uppercased())
                            .font(.system(size: 13, weight: .black))
                            .tracking(2.2)
                            .foregroundStyle(Color.yellow)

                        Text(drop.storyTitle)
                            .font(.system(size: 46, weight: .black))
                            .fontWidth(.expanded)
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.78)
                            .lineLimit(1)

                        Text(drop.storyBody)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.86))
                            .lineSpacing(3)
                    }
                    .shadow(color: .black.opacity(0.75), radius: 12, y: 3)

                    HStack(spacing: 9) {
                        Image(systemName: "diamond.fill")
                            .foregroundStyle(Color.yellow)

                        Text("RARE REWARD")
                            .font(.system(size: 12, weight: .black))
                            .tracking(1)

                        Text("•")
                            .foregroundStyle(.white.opacity(0.44))

                        Text("3 questions")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.78))
                    }
                    .foregroundStyle(.white)

                    Button(action: onStart) {
                        HStack {
                            Text("Start Rockies Quiz")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 52)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            BaseballQuizPalette.auraCore,
                                            BaseballQuizPalette.auraLight,
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.24), lineWidth: 1)
                        }
                    }
                    .buttonStyle(BaseballPressableScaleStyle())
                    .accessibilityIdentifier("daily-drop-start-stories")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
            }
        }
        .onAppear {
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.85)
                    .delay(0.1)
            ) {
                appeared = true
            }
        }
    }
}

private struct BaseballQuizStoriesView: View {
    let stories: [BaseballQuizStory]
    let onComplete: () -> Void
    let onClose: () -> Void

    @State private var index = 0
    @State private var textAppeared = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            BaseballRemoteImage(
                urlString: currentStory?.imageURL ?? "",
                fallbackSystemImage: "baseball.fill"
            )
            .ignoresSafeArea()
            .id(index)
            .transition(.opacity)

            LinearGradient(
                colors: [
                    .black.opacity(0.10),
                    .clear,
                    .black.opacity(0.92),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack {
                    Color.clear
                        .frame(width: 44, height: 44)

                    Spacer()

                    HStack(spacing: 7) {
                        Image(systemName: "mountain.2.fill")
                        Text("ROCKIES QUIZ")
                    }
                    .font(.system(size: 12, weight: .black))
                    .tracking(0.9)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.7), radius: 8)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                Spacer()

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        if let story = currentStory {
                            Text(story.title.capitalized)
                                .font(.system(size: 32, weight: .regular))
                                .fontWidth(.expanded)
                                .lineSpacing(10)
                                .foregroundStyle(.white)
                                .lineLimit(3)
                                .minimumScaleFactor(0.8)
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )

                            Text(story.subtitle)
                                .font(.system(size: 18, weight: .regular))
                                .kerning(0.54)
                                .lineSpacing(10)
                                .foregroundStyle(.white.opacity(0.86))
                                .lineLimit(4)
                                .minimumScaleFactor(0.85)
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .shadow(color: .black.opacity(0.6), radius: 8, y: 2)
                    .opacity(textAppeared ? 1 : 0)
                    .offset(y: textAppeared ? 0 : 12)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("daily-drop-story-copy")

                    HStack(spacing: 6) {
                        ForEach(stories.indices, id: \.self) { storyIndex in
                            Capsule()
                                .fill(
                                    storyIndex <= index
                                        ? Color.white
                                        : Color.white.opacity(0.25)
                                )
                                .frame(height: 3)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: index)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .allowsHitTesting(false)

            HStack(spacing: 0) {
                Button(action: goBack) {
                    Color.clear
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Previous story")
                .accessibilityIdentifier("daily-drop-story-previous")

                Button(action: goForward) {
                    Color.clear
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(
                    index == stories.count - 1
                        ? "Start quiz"
                        : "Next story"
                )
                .accessibilityIdentifier("daily-drop-story-next")
            }
            .ignoresSafeArea()

            HStack {
                BaseballQuizCloseButton(action: onClose)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    if value.translation.width < -40 {
                        goForward()
                    } else if value.translation.width > 40 {
                        goBack()
                    }
                }
        )
        .onAppear(perform: animateText)
        .onChange(of: index) { _, _ in
            animateText()
        }
    }

    private var currentStory: BaseballQuizStory? {
        guard stories.indices.contains(index) else { return nil }
        return stories[index]
    }

    private func goForward() {
        BaseballQuizHaptics.tap()
        if index >= stories.count - 1 {
            onComplete()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                index += 1
            }
        }
    }

    private func goBack() {
        guard index > 0 else { return }
        BaseballQuizHaptics.tap()
        withAnimation(.easeInOut(duration: 0.25)) {
            index -= 1
        }
    }

    private func animateText() {
        textAppeared = false
        withAnimation(
            .spring(response: 0.5, dampingFraction: 0.85)
                .delay(0.05)
        ) {
            textAppeared = true
        }
    }
}

private struct BaseballQuizQuestionsView: View {
    let questions: [BaseballQuizQuestion]
    let onClose: () -> Void
    let onComplete: (BaseballQuizResult) -> Void

    @State private var questionIndex = 0
    @State private var selectedAnswerIndex: Int?
    @State private var timeRemaining = 10.0
    @State private var correctAnswers = 0
    @State private var totalElapsed = 0.0
    @State private var points = 0
    @State private var showNextButton = false
    @State private var isCelebrating = false
    @State private var celebrationID = 0

    private let secondsPerQuestion = 10.0

    var body: some View {
        ZStack(alignment: .topLeading) {
            BaseballQuizPalette.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                navigationBar
                    .padding(.horizontal, 16)

                if let question = currentQuestion {
                    BaseballTriviaQuestionView(
                        question: question,
                        selectedAnswerIndex: selectedAnswerIndex,
                        timeRemaining: timeRemaining,
                        totalTime: secondsPerQuestion,
                        onAnswerSelected: answer
                    )
                    .id(question.id)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing)
                                .combined(with: .scale(scale: 0.94))
                                .combined(with: .opacity),
                            removal: .move(edge: .leading)
                                .combined(with: .scale(scale: 0.94))
                                .combined(with: .opacity)
                        )
                    )
                }

                ZStack {
                    if showNextButton {
                        Button(action: advance) {
                            HStack(spacing: 6) {
                                Text(
                                    isLastQuestion
                                        ? "See reward"
                                        : "Next question"
                                )
                                .font(.system(size: 15, weight: .semibold))

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundStyle(.black)
                            .padding(.horizontal, 24)
                            .frame(height: 44)
                            .background(
                                Capsule()
                                    .fill(.white)
                                    .shadow(
                                        color: .white.opacity(0.3),
                                        radius: 14
                                    )
                            )
                        }
                        .buttonStyle(BaseballPressableScaleStyle())
                        .transition(
                            .move(edge: .bottom)
                                .combined(with: .opacity)
                        )
                        .accessibilityIdentifier("quiz-next-button")
                    }
                }
                .frame(height: 52)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 12)

            if isCelebrating {
                BaseballCommishCelebrationView {
                    isCelebrating = false
                }
                .id(celebrationID)
            }
        }
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8),
            value: showNextButton
        )
        .animation(
            .spring(response: 0.55, dampingFraction: 0.82),
            value: questionIndex
        )
        .task(id: questionIndex) {
            await runTimer()
        }
    }

    private var currentQuestion: BaseballQuizQuestion? {
        guard questions.indices.contains(questionIndex) else { return nil }
        return questions[questionIndex]
    }

    private var isLastQuestion: Bool {
        questionIndex >= questions.count - 1
    }

    private var navigationBar: some View {
        HStack(spacing: 12) {
            BaseballQuizCloseButton(action: onClose)

            GeometryReader { geometry in
                let count = max(questions.count, 1)
                let spacing: CGFloat = 6
                let totalSpacing = spacing * CGFloat(max(count - 1, 0))
                let segmentWidth = (
                    geometry.size.width - totalSpacing
                ) / CGFloat(count)

                HStack(spacing: spacing) {
                    ForEach(questions.indices, id: \.self) { index in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.18))
                                .frame(width: segmentWidth, height: 4)

                            Capsule()
                                .fill(progressColor(for: index))
                                .frame(
                                    width: index <= questionIndex
                                        ? segmentWidth
                                        : 0,
                                    height: 4
                                )
                        }
                    }
                }
            }
            .frame(height: 4)
        }
        .frame(height: 44)
    }

    private func progressColor(for index: Int) -> LinearGradient {
        let pending = LinearGradient(
            colors: [
                BaseballQuizPalette.auraLight,
                BaseballQuizPalette.auraCore,
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        guard index < questionIndex
                || (index == questionIndex && selectedAnswerIndex != nil),
              questions.indices.contains(index) else {
            return pending
        }

        let wasCorrect: Bool
        if index == questionIndex {
            wasCorrect = selectedAnswerIndex
                == questions[index].correctAnswerIndex
        } else {
            // Completed earlier questions contribute to the running total, but
            // their individual answers are intentionally not retained.
            wasCorrect = true
        }

        let color = wasCorrect
            ? BaseballQuizPalette.correct
            : BaseballQuizPalette.wrong
        return LinearGradient(
            colors: [color, color.opacity(0.72)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func answer(_ answerIndex: Int) {
        guard selectedAnswerIndex == nil, let question = currentQuestion else {
            return
        }

        selectedAnswerIndex = answerIndex
        totalElapsed += max(0, secondsPerQuestion - timeRemaining)

        if answerIndex == question.correctAnswerIndex {
            correctAnswers += 1
            points += 100 + Int(floor(timeRemaining)) * 5
            BaseballQuizHaptics.affirm()
            celebrationID += 1
            isCelebrating = true
        } else {
            BaseballQuizHaptics.reject()
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            showNextButton = true
        }
    }

    private func advance() {
        guard selectedAnswerIndex != nil else { return }
        BaseballQuizHaptics.tap()

        if isLastQuestion {
            onComplete(
                BaseballQuizResult(
                    correct: correctAnswers,
                    total: questions.count,
                    seconds: max(1, Int(ceil(totalElapsed))),
                    points: points
                )
            )
            return
        }

        withAnimation(
            .spring(response: 0.35, dampingFraction: 0.85)
        ) {
            showNextButton = false
        }

        withAnimation(
            .spring(response: 0.55, dampingFraction: 0.8)
        ) {
            questionIndex += 1
            selectedAnswerIndex = nil
            timeRemaining = secondsPerQuestion
            isCelebrating = false
        }
    }

    @MainActor
    private func runTimer() async {
        timeRemaining = secondsPerQuestion

        while !Task.isCancelled,
              selectedAnswerIndex == nil,
              timeRemaining > 0 {
            try? await Task.sleep(for: .milliseconds(100))
            guard !Task.isCancelled, selectedAnswerIndex == nil else {
                return
            }
            timeRemaining = max(0, timeRemaining - 0.1)
        }

        if selectedAnswerIndex == nil {
            answer(-1)
        }
    }
}

private struct BaseballTriviaQuestionView: View {
    let question: BaseballQuizQuestion
    let selectedAnswerIndex: Int?
    let timeRemaining: Double
    let totalTime: Double
    let onAnswerSelected: (Int) -> Void

    @State private var appeared = false
    @State private var imageZoom = 1.06
    @State private var timerPulse = 1.0

    private var isAnswered: Bool {
        selectedAnswerIndex != nil
    }

    var body: some View {
        GeometryReader { geometry in
            let imageHeight = max(
                280,
                min(
                    geometry.size.height * 0.62,
                    geometry.size.height - 240
                )
            )

            VStack(spacing: 12) {
                imageSection(
                    size: CGSize(
                        width: geometry.size.width,
                        height: imageHeight
                    )
                )

                VStack(spacing: 8) {
                    ForEach(question.answers.indices, id: \.self) { index in
                        answerButton(index: index)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height,
                alignment: .top
            )
            .scaleEffect(appeared ? 1 : 0.96)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(
                .spring(response: 0.55, dampingFraction: 0.82)
            ) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 0.9)) {
                imageZoom = 1
            }
            withAnimation(
                .easeInOut(duration: 0.9)
                    .repeatForever(autoreverses: true)
            ) {
                timerPulse = 1.06
            }
        }
    }

    private func imageSection(size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            BaseballRemoteImage(
                urlString: question.imageURL,
                fallbackSystemImage: "baseball.fill"
            )
            .scaleEffect(imageZoom)

            if isAnswered {
                LinearGradient(
                    colors: [
                        .black.opacity(0.75),
                        .black.opacity(0.35),
                        .clear,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: size.height * 0.42)
                .frame(
                    width: size.width,
                    height: size.height,
                    alignment: .top
                )
            }

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.5),
                    .black.opacity(0.92),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Text(question.question)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(4)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .frame(
                    width: size.width,
                    height: size.height,
                    alignment: .bottomLeading
                )

            Group {
                if isAnswered {
                    Text(question.fact)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.96))
                        .lineSpacing(2)
                        .frame(width: 216, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(
                                            .white.opacity(0.18),
                                            lineWidth: 1
                                        )
                                }
                        )
                        .transition(
                            .opacity.combined(
                                with: .scale(scale: 0.92)
                            )
                        )
                } else {
                    timerBadge
                        .transition(
                            .opacity.combined(
                                with: .scale(scale: 0.92)
                            )
                        )
                }
            }
            .padding(14)
            .animation(
                .spring(response: 0.55, dampingFraction: 0.78),
                value: isAnswered
            )
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
    }

    private var timerBadge: some View {
        let isLow = timeRemaining <= 5
        let accent = isLow
            ? BaseballQuizPalette.wrong
            : BaseballQuizPalette.correct
        let timeText = isLow
            ? String(
                format: "%.1f",
                (timeRemaining * 10).rounded(.down) / 10
            )
            : "\(Int(ceil(timeRemaining)))"

        return HStack(spacing: 6) {
            Image(systemName: "baseball.fill")
                .font(.system(size: 15, weight: .heavy))

            Text(timeText)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(.black)
                .overlay {
                    Capsule()
                        .stroke(accent.opacity(isLow ? 0.9 : 0.45), lineWidth: 1.5)
                }
        )
        .shadow(color: accent.opacity(0.4), radius: isLow ? 14 : 6)
        .scaleEffect((isLow ? 1.06 : 1) * timerPulse)
    }

    private func answerButton(index: Int) -> some View {
        let selected = selectedAnswerIndex == index
        let correct = isAnswered && index == question.correctAnswerIndex

        return Button {
            onAnswerSelected(index)
        } label: {
            Text(question.answers[index])
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(answerBackground(index: index))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            answerStroke(index: index),
                            lineWidth: selected || correct ? 2 : 1.25
                        )
                }
        }
        .buttonStyle(BaseballPressableScaleStyle())
        .disabled(isAnswered)
        .opacity(isAnswered && !selected && !correct ? 0.5 : 1)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.7),
            value: selectedAnswerIndex
        )
        .accessibilityIdentifier("quiz-answer-\(question.id)-\(index)")
    }

    private func answerBackground(index: Int) -> SwiftUI.Color {
        guard let selectedAnswerIndex else {
            return .white.opacity(0.06)
        }
        if index == question.correctAnswerIndex {
            return BaseballQuizPalette.correct.opacity(0.18)
        }
        if index == selectedAnswerIndex {
            return BaseballQuizPalette.wrong.opacity(0.18)
        }
        return .white.opacity(0.04)
    }

    private func answerStroke(index: Int) -> SwiftUI.Color {
        guard let selectedAnswerIndex else {
            return .white.opacity(0.18)
        }
        if index == question.correctAnswerIndex {
            return BaseballQuizPalette.correct
        }
        if index == selectedAnswerIndex {
            return BaseballQuizPalette.wrong
        }
        return .white.opacity(0.12)
    }
}

private struct BaseballPressableScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}

private struct BaseballRemoteImage: View {
    let urlString: String
    let fallbackSystemImage: String

    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: urlString)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    ZStack {
                        fallback
                        ProgressView().tint(.white)
                    }
                case .failure:
                    fallback
                @unknown default:
                    fallback
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipped()
        }
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [
                    RockiesTheme.brightPurple,
                    .indigo,
                    BaseballQuizPalette.background,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: fallbackSystemImage)
                .font(.system(size: 120, weight: .black))
                .foregroundStyle(.white.opacity(0.30))
        }
    }
}

// MARK: - Exact Takes Rive celebration

private final class BaseballCommishCelebrationViewModel: RiveViewModel {
    var onFinished: (() -> Void)?
    private var didFinish = false

    init() {
        super.init(
            fileName: "commish_lets_go",
            animationName: nil,
            autoPlay: true
        )
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinished?()
    }

    override func player(pausedWithModel riveModel: RiveModel?) {
        super.player(pausedWithModel: riveModel)
        finish()
    }

    override func player(stoppedWithModel riveModel: RiveModel?) {
        super.player(stoppedWithModel: riveModel)
        finish()
    }
}

private struct BaseballCommishCelebrationView: View {
    let onFinished: () -> Void

    @StateObject private var rive = BaseballCommishCelebrationViewModel()

    var body: some View {
        TransparentQuizRiveView(model: rive)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear {
                rive.onFinished = onFinished
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(4))
                    onFinished()
                }
            }
    }
}

// MARK: - Exact Takes Rive pack rip

private struct TransparentQuizRiveView: UIViewRepresentable {
    let model: RiveViewModel

    func makeUIView(context: Context) -> RiveView {
        let view = model.createRiveView()
        Self.makeTransparent(view)

        for delay in [0.0, 0.1, 0.3, 0.6, 1.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                Self.makeTransparent(view)
            }
        }
        return view
    }

    func updateUIView(_ uiView: RiveView, context: Context) {
        Self.makeTransparent(uiView)
    }

    private static func makeTransparent(_ view: UIView) {
        view.isOpaque = false
        view.backgroundColor = .clear

        if let metalView = view as? MTKView {
            metalView.clearColor = MTLClearColorMake(0, 0, 0, 0)
        }

        clearLayer(view.layer)
        view.subviews.forEach(makeTransparent)
    }

    private static func clearLayer(_ layer: CALayer) {
        layer.isOpaque = false
        if let metalLayer = layer as? CAMetalLayer {
            metalLayer.isOpaque = false
            metalLayer.framebufferOnly = false
        }
        layer.sublayers?.forEach(clearLayer)
    }
}

private final class BaseballPackRipViewModel: RiveViewModel {
    var onFinished: (() -> Void)?
    private var didFinish = false

    init() {
        super.init(
            fileName: "wc_pack_rip",
            animationName: nil,
            fit: .cover,
            autoPlay: false
        )
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinished?()
    }

    override func player(pausedWithModel riveModel: RiveModel?) {
        super.player(pausedWithModel: riveModel)
        finish()
    }

    override func player(stoppedWithModel riveModel: RiveModel?) {
        super.player(stoppedWithModel: riveModel)
        finish()
    }
}

private struct BaseballPackRipView: View {
    let onOpen: () -> Void
    let onReveal: () -> Void

    @StateObject private var rive = BaseballPackRipViewModel()
    @State private var isOpening = false
    @State private var didReveal = false

    var body: some View {
        TransparentQuizRiveView(model: rive)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture(perform: open)
            .onAppear {
                rive.onFinished = reveal
            }
            .accessibilityElement()
            .accessibilityLabel("Open reward pack")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("daily-drop-pack")
    }

    private func open() {
        guard !isOpening else { return }
        isOpening = true
        onOpen()
        rive.play()

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(8))
            reveal()
        }
    }

    private func reveal() {
        guard !didReveal else { return }
        didReveal = true
        onReveal()
    }
}

private struct BaseballQuizRewardView: View {
    let sticker: BaseballSticker
    let result: BaseballQuizResult
    let onClaim: () -> Void

    private enum Stage {
        case sealed
        case opening
        case revealed
    }

    @State private var appeared = false
    @State private var isFlipped = false
    @State private var stage: Stage = .sealed

    var body: some View {
        ZStack {
            BaseballQuizPalette.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                resultHeader
                    .padding(.top, 64)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -8)

                Spacer()

                cardArea

                VStack(spacing: 8) {
                    Text(headline)
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subhead)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .padding(.top, stage == .sealed ? 90 : 0)
                .opacity(textVisible ? 1 : 0)
                .offset(y: textVisible ? 0 : 12)

                Spacer()

                if showClaimUI {
                    claimButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .transition(
                            .opacity.combined(
                                with: .move(edge: .bottom)
                            )
                        )
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if showClaimUI, value.translation.height < -60 {
                        claim()
                    }
                }
        )
        .onAppear {
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.8)
                    .delay(0.1)
            ) {
                appeared = true
            }
        }
    }

    private var resultHeader: some View {
        VStack(spacing: 18) {
            Text("\(result.correct)/\(result.total) correct")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(.white)

            HStack(spacing: 48) {
                statColumn(title: "Time") {
                    Text(result.formattedTime)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(.white)
                }

                statColumn(title: "Points Earned") {
                    HStack(spacing: 6) {
                        Image(systemName: "circle.hexagongrid.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.cyan)

                        Text("\(result.points)")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private func statColumn<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .kerning(0.8)
                .foregroundStyle(.white.opacity(0.5))
            content()
        }
    }

    private var showClaimUI: Bool {
        appeared && stage == .revealed
    }

    private var textVisible: Bool {
        appeared && stage != .opening
    }

    private var cardArea: some View {
        ZStack {
            flippableCard
                .frame(maxWidth: 260)
                .aspectRatio(0.70, contentMode: .fit)
                .allowsHitTesting(stage == .revealed)
                .opacity(stage == .sealed ? 0 : 1)
                .accessibilityIdentifier("daily-drop-sticker-reveal")

            if stage != .revealed {
                BaseballPackRipView(
                    onOpen: {
                        BaseballQuizHaptics.tap()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            stage = .opening
                        }
                    },
                    onReveal: {
                        BaseballQuizHaptics.affirm()
                        withAnimation(
                            .spring(response: 0.5, dampingFraction: 0.85)
                        ) {
                            stage = .revealed
                        }
                    }
                )
                .frame(maxWidth: 260)
                .aspectRatio(0.70, contentMode: .fit)
                .mask(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.white)
                        .padding(10)
                        .blur(radius: 16)
                )
                .scaleEffect(1.5)
            }
        }
        .scaleEffect(appeared ? 1 : 0.7)
        .opacity(appeared ? 1 : 0)
    }

    private var flippableCard: some View {
        ZStack {
            BaseballStickerCardView(sticker: sticker, size: .large)
                .opacity(isFlipped ? 0 : 1)

            BaseballStickerBackView(sticker: sticker)
                .rotation3DEffect(
                    .degrees(180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 1 : 0)
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .shadow(color: .black.opacity(0.5), radius: 24, y: 12)
        .contentShape(Rectangle())
        .onTapGesture {
            BaseballQuizHaptics.tap()
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.8)
            ) {
                isFlipped.toggle()
            }
        }
    }

    private var headline: String {
        stage == .revealed
            ? "Say hello to your newest squad member!"
            : "The Commish is impressed!"
    }

    private var subhead: String {
        switch stage {
        case .revealed:
            "Tap the card to flip it · Swipe up to claim"
        case .sealed, .opening:
            "You absolutely nailed that quiz. You’ve unlocked a rare player card for your pack. Tap to open it!"
        }
    }

    private var claimButton: some View {
        Button(action: claim) {
            Text("Claim reward")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    BaseballQuizPalette.auraCore,
                                    BaseballQuizPalette.auraLight,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        }
        .accessibilityIdentifier("daily-drop-claim-reward")
    }

    private func claim() {
        guard showClaimUI else { return }
        BaseballQuizHaptics.affirm()
        onClaim()
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
        case .large: 314
        }
    }
}

struct BaseballStickerCardView: View {
    let sticker: BaseballSticker
    let size: BaseballStickerCardSize

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.07, blue: 0.24),
                            RockiesTheme.brightPurple,
                            Color(red: 0.03, green: 0.04, blue: 0.09),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white, .cyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size == .large ? 3 : 2
                )

            VStack(spacing: size == .large ? 10 : 5) {
                HStack {
                    Text("COLORADO")
                    Spacer()
                    Text("#\(sticker.jerseyNumber)")
                }
                .font(
                    .system(
                        size: size == .large ? 10 : 7,
                        weight: .black
                    )
                )
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.82))

                ZStack(alignment: .bottom) {
                    Circle()
                        .fill(.white.opacity(0.12))

                    AsyncImage(url: URL(string: sticker.portraitURL)) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(systemName: sticker.systemImage)
                                .font(
                                    .system(
                                        size: size == .large ? 72 : 40,
                                        weight: .black
                                    )
                                )
                                .foregroundStyle(.white.opacity(0.92))
                        }
                    }
                }
                .frame(
                    width: size == .large ? 150 : 84,
                    height: size == .large ? 150 : 84
                )
                .clipShape(Circle())

                Text(sticker.playerName.uppercased())
                    .font(
                        .system(
                            size: size == .large ? 21 : 13,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text(sticker.position)
                    .font(
                        .system(
                            size: size == .large ? 10 : 7,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white.opacity(0.70))

                Text(sticker.rarity.displayName)
                    .font(
                        .system(
                            size: size == .large ? 9 : 6,
                            weight: .black
                        )
                    )
                    .tracking(1.5)
                    .foregroundStyle(.cyan)
            }
            .padding(size == .large ? 18 : 12)
        }
        .frame(width: size.width, height: size.height)
        .shadow(
            color: RockiesTheme.brightPurple.opacity(0.38),
            radius: size == .large ? 32 : 14,
            y: size == .large ? 18 : 7
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(sticker.rarity.displayName) player card, \(sticker.playerName), \(sticker.teamName), number \(sticker.jerseyNumber)"
        )
        .accessibilityIdentifier("profile-sticker-\(sticker.id)")
    }
}

private struct BaseballStickerBackView: View {
    let sticker: BaseballSticker

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .black,
                            RockiesTheme.brightPurple,
                            .indigo,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(.white.opacity(0.8), lineWidth: 3)

            VStack(spacing: 18) {
                Image(systemName: "baseball.diamond.bases.fill")
                    .font(.system(size: 48, weight: .black))
                    .foregroundStyle(.white)

                Text(sticker.playerName)
                    .font(.title2.weight(.black))
                    .multilineTextAlignment(.center)

                Text(sticker.tagline)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.76))
                    .multilineTextAlignment(.center)

                Divider()
                    .overlay(.white.opacity(0.22))

                Text("\(sticker.teamName) · \(sticker.position)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.cyan)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .frame(width: 220, height: 314)
    }
}
