import SwiftUI
@preconcurrency import UIKit

struct AnimatedHostView: View {
    let host: any AnimatedHostControlling
    let height: CGFloat
    var accent: Color = .purple
    var contentScale: CGFloat = 1
    var contentOffset: CGSize = .zero
    var selectedAvatar: CollegeFootballSticker?

    var body: some View {
        let motifSize = min(max(height * 0.72, 230), 320)

        ZStack {
            RadialGradient(
                colors: [
                    accent.opacity(0.34),
                    Color.cyan.opacity(0.1),
                    .clear,
                ],
                center: .center,
                startRadius: 10,
                endRadius: 190
            )
            .blur(radius: 8)

            CollegeFootballDiamondLines()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.14), .white.opacity(0.015)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 9])
                )
                .frame(width: motifSize, height: motifSize)
                .rotationEffect(.degrees(45))
                .offset(y: 22)

            Ellipse()
                .fill(.black.opacity(0.46))
                .frame(width: motifSize, height: 38)
                .blur(radius: 10)
                .offset(y: height * 0.37)

            renderedHost
                .padding(.horizontal, 28)
                .padding(.vertical, 2)
                .scaleEffect(resolvedContentScale, anchor: .bottom)
                .offset(resolvedContentOffset)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            selectedAvatar.map {
                "\($0.playerName) animated sticker avatar"
            } ?? host.descriptor.accessibilityName
        )
        .accessibilityValue(
            selectedAvatar == nil
                ? host.currentBehavior.displayName
                : "Selected profile avatar"
        )
        .accessibilityIdentifier("collegeFootball-animated-host")
    }

    @ViewBuilder
    private var renderedHost: some View {
        if let selectedAvatar,
           let resourceName = selectedAvatar.animatedAvatarResourceName,
           let frameURLs = Bundle.main.urls(
                forResourcesWithExtension: "png",
                subdirectory: "Animations/\(resourceName)"
           ),
           !frameURLs.isEmpty {
            AnimatedPNGSequenceView(
                frameURLs: frameURLs.sorted(
                    by: NumericalFrameSorter.areInIncreasingOrder
                )
            )
                .aspectRatio(1, contentMode: .fit)
                .transition(.opacity)
        } else {
            switch host.renderedContent {
            case .nativeView(let view):
                view
                    .aspectRatio(contentMode: .fit)
            case .imageFrame(let image):
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .transition(.opacity)
            case .unavailable:
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                    Text("Warming up your host…")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var resolvedContentScale: CGFloat {
        contentScale
    }

    private var resolvedContentOffset: CGSize {
        contentOffset
    }
}

private struct AnimatedPNGSequenceView: UIViewRepresentable {
    let frameURLs: [URL]

    func makeUIView(context: Context) -> LoopingPNGSequenceImageView {
        let imageView = LoopingPNGSequenceImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = false
        imageView.play(frameURLs)
        return imageView
    }

    func updateUIView(
        _ imageView: LoopingPNGSequenceImageView,
        context: Context
    ) {
        imageView.play(frameURLs)
    }

    static func dismantleUIView(
        _ imageView: LoopingPNGSequenceImageView,
        coordinator: Void
    ) {
        imageView.stopPlayback()
    }
}

@MainActor
private final class LoopingPNGSequenceImageView: UIImageView {
    private static let framesPerSecond = 24.0

    private var activeFrameURLs: [URL] = []
    private var playbackTask: Task<Void, Never>?
    private var playbackToken = UUID()

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: UIView.noIntrinsicMetric
        )
    }

    func play(_ frameURLs: [URL]) {
        guard !frameURLs.isEmpty,
              activeFrameURLs != frameURLs else {
            return
        }

        stopPlayback()
        activeFrameURLs = frameURLs
        let token = UUID()
        playbackToken = token
        playbackTask = Task { [weak self] in
            var index = 0
            while !Task.isCancelled {
                let frameURL = frameURLs[index]
                let frame = await Task.detached(
                    priority: .userInitiated
                ) {
                    try? PNGFrameDecoder.decode(frameURL)
                }.value

                guard !Task.isCancelled,
                      let self,
                      self.playbackToken == token else {
                    return
                }
                if let frame {
                    self.image = frame
                }

                index = (index + 1) % frameURLs.count
                try? await Task.sleep(
                    for: .seconds(1 / Self.framesPerSecond)
                )
            }
        }
    }

    func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
        playbackToken = UUID()
        activeFrameURLs = []
        image = nil
    }
}

private struct CollegeFootballDiamondLines: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: 28, height: 28))
            let inset = rect.insetBy(dx: rect.width * 0.25, dy: rect.height * 0.25)
            path.addRoundedRect(in: inset, cornerSize: CGSize(width: 12, height: 12))
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}
