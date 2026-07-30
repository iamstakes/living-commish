@preconcurrency import UIKit
import ImageIO

enum FramePreloaderError: LocalizedError {
    case missingDirectory(String)
    case unreadableFrame(String)

    var errorDescription: String? {
        switch self {
        case .missingDirectory(let directory): "No PNG frames were found in Animations/\(directory)."
        case .unreadableFrame(let filename): "Could not decode animation frame \(filename)."
        }
    }
}

enum FramePreloader {
    static func loadAll(bundle: Bundle = .main) throws -> [CommishAction: [UIImage]] {
        var result: [CommishAction: [UIImage]] = [:]
        for action in CommishAction.allCases {
            let definition = AnimationConfiguration.definition(for: action)
            let subdirectory = "Animations/\(definition.resourceDirectory)"
            guard let urls = bundle.urls(forResourcesWithExtension: "png", subdirectory: subdirectory),
                  !urls.isEmpty else {
                throw FramePreloaderError.missingDirectory(definition.resourceDirectory)
            }
            result[action] = try urls
                .sorted(by: NumericalFrameSorter.areInIncreasingOrder)
                .map(PNGFrameDecoder.decode)
        }
        return result
    }
}

enum PNGFrameDecoder {
    static func decode(_ url: URL) throws -> UIImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let sourceImage = CGImageSourceCreateImageAtIndex(
                source,
                0,
                nil
              ),
              let context = CGContext(
                data: nil,
                width: sourceImage.width,
                height: sourceImage.height,
                bitsPerComponent: 8,
                bytesPerRow: sourceImage.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ),
              context.drawAndCreate(sourceImage),
              let decodedImage = context.makeImage() else {
            throw FramePreloaderError.unreadableFrame(
                url.lastPathComponent
            )
        }
        return UIImage(cgImage: decodedImage)
    }
}

private extension CGContext {
    @discardableResult
    func drawAndCreate(_ image: CGImage) -> Bool {
        setBlendMode(.copy)
        draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return true
    }
}
