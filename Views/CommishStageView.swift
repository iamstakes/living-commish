import SwiftUI

struct CommishStageView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var environment = environment

        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.055, blue: 0.08), Color(red: 0.13, green: 0.08, blue: 0.17)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    statusRow
                    fallbackNotice
                    responseBubble
                    reactionFeedbackControls
                    characterStage
                    inputComposer
                    scenarioCards
                    primaryActions
                    developerControls
                    eventLog
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $environment.isMemoryPresented) {
            MemoryView()
                .environment(environment)
                .presentationDetents([.medium, .large])
        }
        .onChange(of: scenePhase) { _, phase in
            environment.handleApplicationActive(phase == .active)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("LIVING COMMISH")
                    .font(.caption.weight(.black))
                    .tracking(2.4)
                    .foregroundStyle(.purple.opacity(0.9))
                Text("The league office is watching.")
                    .font(.title2.bold())
            }
            Spacer()
            Button {
                environment.isMemoryPresented = true
            } label: {
                Image(systemName: "brain.head.profile.fill")
                    .font(.title3)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Memory")
            .accessibilityIdentifier("memory-header-button")
        }
    }

    private var statusRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                StatusPill(label: "Renderer", value: environment.commish.rendererName, color: .purple)
                StatusPill(label: "Intelligence", value: environment.intelligence.providerName, color: .blue)
                StatusPill(label: "Mood", value: environment.currentEmotion.displayName, color: moodColor)
                StatusPill(label: "State", value: environment.commish.currentAction.displayName, color: .orange)
            }
        }
    }

    private var responseBubble: some View {
        Text(environment.responseLine)
            .font(.headline)
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.white, moodColor.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(alignment: .bottom) {
                Triangle()
                    .fill(moodColor.opacity(0.28))
                    .frame(width: 22, height: 12)
                    .offset(y: 9)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(moodColor.opacity(0.5), lineWidth: 1.5)
            }
            .shadow(color: moodColor.opacity(0.28), radius: 18, y: 8)
            .accessibilityLabel("Commish says: \(environment.responseLine)")
            .accessibilityIdentifier("response-bubble")
            .animation(.easeInOut(duration: 0.3), value: environment.currentEmotion)
    }

    @ViewBuilder
    private var reactionFeedbackControls: some View {
        if environment.hasRateableReaction {
            HStack(spacing: 10) {
                Text("Did that feel right?")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    environment.approveLastReaction()
                } label: {
                    Label("Yes", systemImage: "hand.thumbsup.fill")
                }
                .buttonStyle(.bordered)
                .tint(.mint)
                .accessibilityIdentifier("reaction-feedback-up")

                Menu {
                    ForEach(environment.reactionCorrectionOptions) { option in
                        Button(option.title) {
                            environment.correctLastReaction(option)
                        }
                    }
                } label: {
                    Label("Correct", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .accessibilityIdentifier("reaction-feedback-correct")
            }
        } else if let notice = environment.feedbackNotice {
            Label(notice, systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.mint)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("reaction-feedback-notice")
        }
    }

    @ViewBuilder
    private var fallbackNotice: some View {
        if let notice = environment.intelligence.fallbackNotice {
            Label(notice, systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityIdentifier("intelligence-fallback-notice")
        }
    }

    private var characterStage: some View {
        ZStack {
            Ellipse()
                .fill(moodColor.opacity(0.24))
                .frame(width: 280, height: 56)
                .blur(radius: 12)
                .offset(y: 132)

            if let rendererView = environment.commish.rendererView {
                rendererView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let frame = environment.commish.currentFrame {
                Image(uiImage: frame)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .transition(.opacity)
                    .accessibilityLabel("Commish character, \(environment.commish.currentAction.displayName) animation")
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Preloading Commish…")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 330)
        .animation(.easeInOut(duration: 0.35), value: environment.currentEmotion)
    }

    private var moodColor: Color {
        switch environment.currentEmotion {
        case .neutral: .gray
        case .curious: .cyan
        case .smug: .orange
        case .annoyed: .red
        case .disappointed: .indigo
        case .encouraging: .mint
        case .celebratory: .pink
        }
    }

    private var inputComposer: some View {
        VStack(spacing: 10) {
            TextField("Describe a Takes event…", text: Bindable(environment).inputText, axis: .vertical)
                .lineLimit(2...4)
                .textInputAutocapitalization(.sentences)
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityIdentifier("fan-event-field")

            Button {
                Task { await environment.submitCurrentEvent() }
            } label: {
                HStack {
                    if environment.isGenerating { ProgressView().tint(.white) }
                    Text(environment.isGenerating ? "Thinking on device…" : "Generate Reaction")
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "sparkles")
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(.purple.gradient, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .disabled(environment.isGenerating || environment.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier("generate-reaction-button")
        }
    }

    private var scenarioCards: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("ONE-TAP SCENARIOS")
                .font(.caption2.bold())
                .tracking(1.2)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(DemoScenario.all) { scenario in
                        Button {
                            environment.inputText = scenario.event
                            Task { await environment.submit(eventText: scenario.event) }
                        } label: {
                            VStack(alignment: .leading, spacing: 9) {
                                Image(systemName: scenario.symbol)
                                    .foregroundStyle(.purple)
                                Text(scenario.title)
                                    .font(.subheadline.bold())
                                    .multilineTextAlignment(.leading)
                                Text(scenario.event)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .frame(width: 140, height: 104, alignment: .topLeading)
                            .padding(12)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("scenario-\(scenario.id)")
                    }
                }
            }
        }
    }

    private var primaryActions: some View {
        HStack(spacing: 10) {
            Button("Story Demo", systemImage: "play.fill") { environment.runStoryDemo() }
                .buttonStyle(CompactActionButtonStyle(tint: .blue))
            Button("Memory", systemImage: "brain.head.profile") { environment.isMemoryPresented = true }
                .buttonStyle(CompactActionButtonStyle(tint: .purple))
                .accessibilityIdentifier("memory-action-button")
        }
    }

    private var developerControls: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 8) {
                    ForEach(CommishAction.allCases) { action in
                        Button(action.displayName, systemImage: action.symbolName) {
                            environment.commish.play(action)
                            environment.log("Manual animation: \(action.displayName)")
                        }
                        .buttonStyle(.bordered)
                        .tint(.purple)
                        .accessibilityIdentifier("manual-\(action.rawValue)")
                    }
                }
                Button("Demo Sequence", systemImage: "film.stack") { environment.runAnimationDemo() }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                Button("Reset Model Session", systemImage: "arrow.clockwise") { environment.resetSession() }
                    .buttonStyle(.bordered)
                Button("Reset Demo", systemImage: "trash.slash") { environment.resetDemo() }
                    .buttonStyle(.bordered)
                    .tint(.red)
                Text("Model: \(environment.modelStatus)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 12)
        } label: {
            Label("Developer Controls", systemImage: "wrench.and.screwdriver.fill")
                .font(.subheadline.bold())
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var eventLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RECENT EVENT LOG")
                .font(.caption2.bold())
                .tracking(1.2)
                .foregroundStyle(.secondary)
            if environment.logs.isEmpty {
                Text("Events will appear here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(environment.logs.prefix(6)) { entry in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(.purple).frame(width: 5, height: 5).padding(.top, 5)
                        Text(entry.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.bottom, 22)
        .accessibilityIdentifier("event-log")
    }
}

private struct StatusPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text("\(label):")
                .foregroundStyle(.secondary)
            Text(value).fontWeight(.semibold)
        }
        .font(.caption2)
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: Capsule())
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}

private struct CompactActionButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(tint.opacity(configuration.isPressed ? 0.28 : 0.16), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(tint)
    }
}
