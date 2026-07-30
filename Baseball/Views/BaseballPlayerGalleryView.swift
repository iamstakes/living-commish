import SwiftUI

struct BaseballPlayerGalleryExperienceView: View {
    let player: BaseballPlayerCard
    let isQuizRewardCollected: Bool
    let onCollect: (BaseballSticker) -> Void
    let onOpenCollection: (BaseballSticker) -> Void
    let onDismiss: () -> Void

    @State private var isTakingQuiz = false

    var body: some View {
        Group {
            if isTakingQuiz, let quiz = player.quiz {
                BaseballDailyDropFullScreenView(
                    drop: quiz,
                    onCollect: onCollect,
                    onOpenCollection: {
                        onOpenCollection(quiz.rewardSticker)
                    },
                    onDismiss: onDismiss
                )
            } else {
                BaseballPlayerGalleryView(
                    player: player,
                    isQuizRewardCollected: isQuizRewardCollected,
                    onStartQuiz: {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            isTakingQuiz = true
                        }
                    },
                    onDismiss: onDismiss
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct BaseballPlayerGalleryView: View {
    let player: BaseballPlayerCard
    let isQuizRewardCollected: Bool
    let onStartQuiz: () -> Void
    let onDismiss: () -> Void

    @State private var selectedImageID: String?
    @State private var appeared = false

    private let philliesRed = Color(
        red: 0.91,
        green: 0.08,
        blue: 0.18
    )

    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.025, blue: 0.045)
                .ignoresSafeArea()

            if let selectedImage {
                BaseballGalleryRemoteImage(urlString: selectedImage.imageURL)
                    .scaleEffect(1.12)
                    .blur(radius: 42)
                    .opacity(0.20)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            LinearGradient(
                colors: [
                    philliesRed.opacity(0.20),
                    .clear,
                    .black.opacity(0.72),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                galleryHeader

                gallery

                thumbnailStrip

                quizButton
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
        }
        .onAppear {
            selectedImageID = selectedImageID ?? player.gallery.first?.id
            withAnimation(
                .spring(response: 0.55, dampingFraction: 0.86)
            ) {
                appeared = true
            }
        }
    }

    private var galleryHeader: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.34), in: Circle())
            }
            .accessibilityLabel("Close Mike Schmidt gallery")
            .accessibilityIdentifier("player-gallery-close")

            VStack(alignment: .leading, spacing: 2) {
                Text("THE SCHMIDT ARCHIVE")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.4)
                    .foregroundStyle(philliesRed)

                Text(player.name)
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)
            }

            Spacer()

            Text("\(selectedIndex + 1) / \(max(player.gallery.count, 1))")
                .font(.caption.monospacedDigit().weight(.black))
                .foregroundStyle(.white.opacity(0.72))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white.opacity(0.09), in: Capsule())
        }
    }

    private var gallery: some View {
        TabView(selection: $selectedImageID) {
            ForEach(player.gallery) { galleryImage in
                BaseballGalleryPhotoCard(image: galleryImage)
                    .tag(Optional(galleryImage.id))
                    .accessibilityIdentifier(
                        "player-gallery-image-\(galleryImage.id)"
                    )
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.24), value: selectedImageID)
    }

    private var thumbnailStrip: some View {
        HStack(spacing: 9) {
            ForEach(player.gallery) { galleryImage in
                Button {
                    withAnimation(.easeInOut(duration: 0.24)) {
                        selectedImageID = galleryImage.id
                    }
                } label: {
                    BaseballGalleryRemoteImage(
                        urlString: galleryImage.imageURL
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 10,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 10,
                            style: .continuous
                        )
                        .stroke(
                            selectedImageID == galleryImage.id
                                ? philliesRed
                                : .white.opacity(0.16),
                            lineWidth: selectedImageID == galleryImage.id
                                ? 3
                                : 1
                        )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show \(galleryImage.title)")
                .accessibilityIdentifier(
                    "player-gallery-thumbnail-\(galleryImage.id)"
                )
            }
        }
        .frame(height: 54)
    }

    @ViewBuilder
    private var quizButton: some View {
        if player.quiz != nil {
            Button(action: onStartQuiz) {
                HStack(spacing: 13) {
                    Image(
                        systemName: isQuizRewardCollected
                            ? "arrow.counterclockwise"
                            : "sparkles"
                    )
                    .font(.headline.weight(.black))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            isQuizRewardCollected
                                ? "Replay the Mike Schmidt Quiz"
                                : "Take the Mike Schmidt Quiz"
                        )
                        .font(.headline.weight(.black))

                        Text(
                            isQuizRewardCollected
                                ? "Your LEGENDARY card is collected"
                                : "Earn a LEGENDARY Mike Schmidt card"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.76))
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.headline.weight(.black))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    LinearGradient(
                        colors: [
                            philliesRed,
                            Color(red: 0.58, green: 0.02, blue: 0.08),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                    .stroke(.white.opacity(0.22), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("player-gallery-start-quiz")
        }
    }

    private var selectedImage: BaseballPlayerGalleryImage? {
        player.gallery.first { $0.id == selectedImageID }
            ?? player.gallery.first
    }

    private var selectedIndex: Int {
        guard let selectedImageID else { return 0 }
        return player.gallery.firstIndex {
            $0.id == selectedImageID
        } ?? 0
    }
}

private struct BaseballGalleryPhotoCard: View {
    let image: BaseballPlayerGalleryImage

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            BaseballGalleryRemoteImage(urlString: image.imageURL)

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.16),
                    .black.opacity(0.94),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 7) {
                Text(image.title)
                    .font(.system(size: 27, weight: .black))
                    .foregroundStyle(.white)

                Text(image.caption)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(image.sourceName.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .tracking(0.9)
                    .foregroundStyle(.white.opacity(0.58))
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.36), radius: 24, y: 12)
        .accessibilityElement(children: .combine)
    }
}

private struct BaseballGalleryRemoteImage: View {
    let urlString: String

    var body: some View {
        GeometryReader { proxy in
            AsyncImage(url: URL(string: urlString)) { phase in
                switch phase {
                case .success(let image):
                    ZStack {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: proxy.size.width,
                                height: proxy.size.height
                            )
                            .blur(radius: 20)
                            .opacity(0.48)

                        image
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: proxy.size.width,
                                height: proxy.size.height
                            )
                    }
                    .background(Color.black.opacity(0.36))

                case .empty:
                    placeholder
                        .overlay {
                            ProgressView()
                                .tint(.white)
                        }

                case .failure:
                    placeholder

                @unknown default:
                    placeholder
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.60, green: 0.02, blue: 0.08),
                    .black,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 52, weight: .black))
                .foregroundStyle(.white.opacity(0.34))
        }
    }
}
