import SwiftUI

struct AnimatedHostView: View {
    let host: any AnimatedHostControlling
    let height: CGFloat
    var accent: Color = .purple

    var body: some View {
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
                .frame(width: 230, height: 230)
                .rotationEffect(.degrees(45))
                .offset(y: 22)

            Ellipse()
                .fill(.black.opacity(0.46))
                .frame(width: 230, height: 38)
                .blur(radius: 10)
                .offset(y: height * 0.37)

            renderedHost
                .padding(.horizontal, 28)
                .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(host.descriptor.accessibilityName)
        .accessibilityValue(host.currentBehavior.displayName)
        .accessibilityIdentifier("baseball-animated-host")
    }

    @ViewBuilder
    private var renderedHost: some View {
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
