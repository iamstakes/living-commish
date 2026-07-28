import Foundation
import Observation
import SwiftUI

struct BaseballTeamChoice: Equatable, Identifiable, Sendable {
    let id: String
    let city: String
    let name: String
    let abbreviation: String
    let division: String

    static let coloradoRockies = BaseballTeamChoice(
        id: "colorado-rockies",
        city: "Colorado",
        name: "Rockies",
        abbreviation: "CR",
        division: "NL West"
    )
}

@MainActor
@Observable
final class BaseballOnboardingState {
    static let selectedTeamKey = "baseball.selectedTeam"
    static let completionVersionKey = "baseball.onboardingVersion"
    static let currentVersion = 1

    private(set) var selectedTeamID: String?
    private(set) var hasCompletedOnboarding: Bool

    @ObservationIgnored private let defaults: UserDefaults

    init(
        defaults: UserDefaults = .standard,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        self.defaults = defaults

        if arguments.contains("--baseball-onboarding-ui-testing") {
            defaults.removeObject(forKey: Self.selectedTeamKey)
            defaults.removeObject(forKey: Self.completionVersionKey)
            selectedTeamID = nil
            hasCompletedOnboarding = false
        } else if arguments.contains("--baseball-ui-testing") {
            selectedTeamID = BaseballTeamChoice.coloradoRockies.id
            hasCompletedOnboarding = true
        } else {
            let storedTeamID = defaults.string(forKey: Self.selectedTeamKey)
            let storedVersion = defaults.integer(
                forKey: Self.completionVersionKey
            )
            selectedTeamID = storedTeamID
            hasCompletedOnboarding =
                storedTeamID != nil
                && storedVersion >= Self.currentVersion
        }
    }

    var selectedTeam: BaseballTeamChoice? {
        guard selectedTeamID == BaseballTeamChoice.coloradoRockies.id else {
            return nil
        }
        return .coloradoRockies
    }

    func selectTeam(_ team: BaseballTeamChoice) {
        selectedTeamID = team.id
    }

    @discardableResult
    func complete() -> Bool {
        guard let selectedTeamID else { return false }
        defaults.set(selectedTeamID, forKey: Self.selectedTeamKey)
        defaults.set(Self.currentVersion, forKey: Self.completionVersionKey)
        hasCompletedOnboarding = true
        return true
    }
}

enum RockiesTheme {
    static var purple: Color {
        Color(red: 0.31, green: 0.14, blue: 0.48)
    }

    static var brightPurple: Color {
        Color(red: 0.51, green: 0.25, blue: 0.72)
    }

    static var midnight: Color {
        Color(red: 0.025, green: 0.025, blue: 0.055)
    }

    static var silver: Color {
        Color(red: 0.76, green: 0.78, blue: 0.83)
    }
}

struct BaseballExperienceRootView: View {
    @Environment(BaseballSearchEnvironment.self) private var environment
    @Environment(BaseballOnboardingState.self) private var onboarding

    var body: some View {
        Group {
            if onboarding.hasCompletedOnboarding {
                BaseballSearchHomeView()
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            } else {
                BaseballOnboardingView(
                    host: environment.host,
                    onboarding: onboarding
                )
                .transition(.opacity)
            }
        }
        .animation(
            .spring(response: 0.55, dampingFraction: 0.88),
            value: onboarding.hasCompletedOnboarding
        )
    }
}

private struct BaseballOnboardingView: View {
    enum Step {
        case team
        case confirmation
    }

    let host: any AnimatedHostControlling
    let onboarding: BaseballOnboardingState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: Step = .team

    var body: some View {
        ZStack {
            RockiesChromeBackground()

            Group {
                switch step {
                case .team:
                    teamPicker
                        .transition(stepTransition)
                case .confirmation:
                    confirmation
                        .transition(stepTransition)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("baseball-onboarding")
        .onAppear {
            host.perform(.greet)
        }
    }

    private var teamPicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            onboardingBrand(step: "1 OF 2")

            Spacer(minLength: 18)

            Text("Who do you\nride with?")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .fontWidth(.expanded)
                .tracking(-1.6)
                .accessibilityIdentifier("onboarding-team-title")

            Text("Your team changes what leads, what matters, and how the Commish reacts.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            Spacer(minLength: 22)

            RockiesTeamSelectionCard(
                team: .coloradoRockies,
                host: host,
                isSelected: onboarding.selectedTeamID
                    == BaseballTeamChoice.coloradoRockies.id,
                onSelect: {
                    onboarding.selectTeam(.coloradoRockies)
                    host.perform(.celebrate)
                }
            )

            Text("MORE CLUBS COMING SOON")
                .font(.system(size: 9, weight: .black))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.42))
                .frame(maxWidth: .infinity)
                .padding(.top, 14)

            Spacer(minLength: 18)

            Button {
                guard onboarding.selectedTeam != nil else { return }
                host.perform(.celebrate)
                withAnimation(
                    reduceMotion
                        ? nil
                        : .spring(response: 0.48, dampingFraction: 0.86)
                ) {
                    step = .confirmation
                }
            } label: {
                HStack {
                    Text("Make it mine")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.headline.weight(.black))
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 58)
            }
            .buttonStyle(.glassProminent)
            .tint(RockiesTheme.brightPurple)
            .disabled(onboarding.selectedTeam == nil)
            .accessibilityIdentifier("onboarding-continue")
        }
    }

    private var confirmation: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                onboardingStepPill("2 OF 2")
            }
            .zIndex(2)

            AnimatedHostView(
                host: host,
                height: 330,
                accent: RockiesTheme.brightPurple,
                contentScale: 1.38,
                contentOffset: CGSize(width: 18, height: 0)
            )
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("onboarding-rockies-host")

            Text("Welcome to\naltitude.")
                .font(.system(size: 45, weight: .black, design: .rounded))
                .fontWidth(.expanded)
                .tracking(-1.5)
                .accessibilityIdentifier("onboarding-confirmation-title")

            Text("The Rockies now lead your scores, standings, stories, and rivalry watch.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.70))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 9)

            HStack(spacing: 8) {
                onboardingPill("ROCKIES FIRST", systemImage: "mountain.2.fill")
                onboardingPill("COORS CONTEXT", systemImage: "mappin.and.ellipse")
            }
            .padding(.top, 16)

            Spacer(minLength: 18)

            Button {
                host.perform(.greet)
                onboarding.complete()
            } label: {
                HStack {
                    Text("Meet my Commish")
                    Spacer()
                    Image(systemName: "sparkles")
                }
                .font(.headline.weight(.black))
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 58)
            }
            .buttonStyle(.glassProminent)
            .tint(RockiesTheme.brightPurple)
            .accessibilityIdentifier("onboarding-finish")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-confirmation")
    }

    private func onboardingBrand(step: String) -> some View {
        HStack {
            HStack(spacing: 9) {
                Text("CR")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(RockiesTheme.purple.gradient, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(RockiesTheme.silver.opacity(0.55), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 1) {
                    Text("LIVING COMMISH")
                        .font(.caption2.weight(.black))
                        .tracking(1.1)
                    Text("Built around your club")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            onboardingStepPill(step)
        }
    }

    private func onboardingStepPill(_ step: String) -> some View {
        Text(step)
            .font(.caption2.monospacedDigit().weight(.black))
            .foregroundStyle(RockiesTheme.silver)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .glassEffect(.clear, in: Capsule())
    }

    private func onboardingPill(
        _ title: String,
        systemImage: String
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 9, weight: .black))
            .tracking(0.55)
            .foregroundStyle(.white.opacity(0.78))
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(.white.opacity(0.07), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.09), lineWidth: 1)
            }
    }

    private var stepTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
    }
}

private struct RockiesTeamSelectionCard: View {
    let team: BaseballTeamChoice
    let host: any AnimatedHostControlling
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                RockiesTheme.brightPurple.opacity(0.98),
                                RockiesTheme.purple,
                                Color.black.opacity(0.92),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RockiesPinstripes(opacity: 0.16, spacing: 18)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                    )

                RockiesMountainRange()
                    .fill(.black.opacity(0.36))
                    .frame(height: 118)
                    .frame(maxHeight: .infinity, alignment: .bottom)

                AnimatedHostView(
                    host: host,
                    height: 228,
                    accent: RockiesTheme.silver,
                    contentScale: 1.13,
                    contentOffset: CGSize(width: 24, height: 7)
                )
                .frame(width: 206)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .bottomTrailing
                )
                .offset(x: 38, y: 10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(team.city.uppercased())
                        .font(.caption.weight(.black))
                        .tracking(1.5)
                        .foregroundStyle(RockiesTheme.silver)
                    Text(team.name)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .fontWidth(.expanded)
                    Text("\(team.division.uppercased())  •  DENVER")
                        .font(.system(size: 9, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.62))

                    Spacer()

                    Text(team.abbreviation)
                        .font(.title2.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(.black.opacity(0.48), in: Circle())
                        .overlay {
                            Circle()
                                .stroke(
                                    RockiesTheme.silver.opacity(0.70),
                                    lineWidth: 1.5
                                )
                        }
                }
                .padding(22)

                Image(
                    systemName: isSelected
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.title2.weight(.bold))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.68))
                .padding(18)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topTrailing
                )
            }
            .frame(maxWidth: .infinity, minHeight: 250, maxHeight: 250)
            .contentShape(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(
                    isSelected
                        ? Color.white.opacity(0.88)
                        : RockiesTheme.silver.opacity(0.28),
                    lineWidth: isSelected ? 2 : 1
                )
        }
        .shadow(
            color: RockiesTheme.brightPurple.opacity(isSelected ? 0.42 : 0.24),
            radius: isSelected ? 24 : 16,
            y: 10
        )
        .accessibilityLabel(
            "\(team.city) \(team.name), \(team.division)"
        )
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityIdentifier("onboarding-team-\(team.id)")
    }
}

struct RockiesChromeBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.018, green: 0.026, blue: 0.052),
                    Color(red: 0.115, green: 0.045, blue: 0.17),
                    RockiesTheme.midnight,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(RockiesTheme.brightPurple.opacity(0.22))
                .frame(width: 360, height: 360)
                .blur(radius: 82)
                .offset(x: 170, y: -290)

            RockiesPinstripes(opacity: 0.075, spacing: 22)

            RockiesMountainRange()
                .fill(RockiesTheme.purple.opacity(0.18))
                .frame(height: 260)
                .offset(y: 140)
                .frame(maxHeight: .infinity, alignment: .bottom)

            RockiesMountainRange()
                .stroke(
                    RockiesTheme.silver.opacity(0.12),
                    style: StrokeStyle(lineWidth: 1, lineJoin: .round)
                )
                .frame(height: 225)
                .offset(x: 28, y: 130)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rockies purple pinstripe and mountain theme")
        .accessibilityIdentifier("rockies-chrome-background")
    }
}

private struct RockiesPinstripes: View {
    let opacity: Double
    let spacing: CGFloat

    var body: some View {
        Canvas { context, size in
            var path = Path()
            for x in stride(from: 0, through: size.width, by: spacing) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            context.stroke(
                path,
                with: .color(RockiesTheme.silver.opacity(opacity)),
                lineWidth: 0.7
            )
        }
    }
}

private struct RockiesMountainRange: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(
                to: CGPoint(x: rect.minX, y: rect.maxY * 0.76)
            )
            path.addLine(
                to: CGPoint(x: rect.width * 0.17, y: rect.maxY * 0.46)
            )
            path.addLine(
                to: CGPoint(x: rect.width * 0.28, y: rect.maxY * 0.68)
            )
            path.addLine(
                to: CGPoint(x: rect.width * 0.48, y: rect.maxY * 0.22)
            )
            path.addLine(
                to: CGPoint(x: rect.width * 0.62, y: rect.maxY * 0.56)
            )
            path.addLine(
                to: CGPoint(x: rect.width * 0.76, y: rect.maxY * 0.36)
            )
            path.addLine(
                to: CGPoint(x: rect.maxX, y: rect.maxY * 0.74)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
