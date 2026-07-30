import ImageIO
import SwiftUI
@preconcurrency import UIKit

struct AnimatedHostView: View {
    let host: any AnimatedHostControlling
    let height: CGFloat
    var accent: Color = .purple
    var contentScale: CGFloat = 1
    var contentOffset: CGSize = .zero
    var selectedAvatar: BaseballSticker?

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

            BaseballDiamondLines()
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
        .accessibilityIdentifier("baseball-animated-host")
    }

    @ViewBuilder
    private var renderedHost: some View {
        if let selectedAvatar,
           let resourceName = selectedAvatar.animatedAvatarResourceName,
           let resourceURL = Bundle.main.url(
                forResource: resourceName,
                withExtension: "gif",
                subdirectory: "Animations"
           ) {
            AnimatedGIFView(resourceURL: resourceURL)
                .frame(width: 340, height: 340)
                .clipped()
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
        selectedAvatar == nil ? contentScale : 1
    }

    private var resolvedContentOffset: CGSize {
        guard selectedAvatar != nil else { return contentOffset }
        return CGSize(
            width: contentOffset.width - 34,
            height: contentOffset.height - 75
        )
    }
}

private struct AnimatedGIFView: UIViewRepresentable {
    let resourceURL: URL

    func makeUIView(context: Context) -> LoopingGIFImageView {
        let imageView = LoopingGIFImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = false
        imageView.play(resourceURL)
        return imageView
    }

    func updateUIView(
        _ imageView: LoopingGIFImageView,
        context: Context
    ) {
        imageView.play(resourceURL)
    }

    static func dismantleUIView(
        _ imageView: LoopingGIFImageView,
        coordinator: Void
    ) {
        imageView.stopPlayback()
    }
}

@MainActor
private final class LoopingGIFImageView: UIImageView {
    private var activeResourceURL: URL?
    private var playbackToken = UUID()

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: UIView.noIntrinsicMetric
        )
    }

    func play(_ resourceURL: URL) {
        guard activeResourceURL != resourceURL else { return }

        stopPlayback()
        activeResourceURL = resourceURL
        let token = UUID()
        playbackToken = token

        let status = CGAnimateImageAtURLWithBlock(
            resourceURL as CFURL,
            nil
        ) { [weak self] _, frame, stop in
            guard let self,
                  self.playbackToken == token else {
                stop.pointee = true
                return
            }
            self.image = UIImage(cgImage: frame)
        }

        if status != noErr {
            activeResourceURL = nil
        }
    }

    func stopPlayback() {
        playbackToken = UUID()
        activeResourceURL = nil
        image = nil
    }
}

private struct BaseballDiamondLines: Shape {
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
