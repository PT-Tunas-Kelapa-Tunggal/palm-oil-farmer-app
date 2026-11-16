import CoreGraphics
import Foundation

extension CGImage {
    /// Makes near-black orthomosaic no-data pixels transparent while keeping
    /// dark satellite imagery intact with a narrow, feathered transition.
    func removingBlackNoData(threshold: UInt8 = 8, featherEnd: UInt8 = 36) -> CGImage? {
        let pixelSize = 4
        let bytesPerRow = width * pixelSize
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        )

        let rendered = pixels.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(
                data: bytes.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo.rawValue
            ) else { return false }
            context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard rendered else { return nil }

        let transitionWidth = max(Int(featherEnd) - Int(threshold), 1)
        for offset in stride(from: 0, to: pixels.count, by: pixelSize) {
            let brightness = max(pixels[offset], pixels[offset + 1], pixels[offset + 2])
            let alpha: Int
            if brightness <= threshold {
                alpha = 0
            } else if brightness >= featherEnd {
                alpha = 255
            } else {
                alpha = (Int(brightness) - Int(threshold)) * 255 / transitionWidth
            }

            if alpha < 255 {
                pixels[offset] = UInt8(Int(pixels[offset]) * alpha / 255)
                pixels[offset + 1] = UInt8(Int(pixels[offset + 1]) * alpha / 255)
                pixels[offset + 2] = UInt8(Int(pixels[offset + 2]) * alpha / 255)
                pixels[offset + 3] = UInt8(alpha)
            }
        }

        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}
