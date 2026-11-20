import AppKit

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGColor {
    CGColor(srgbRed: red, green: green, blue: blue, alpha: 1)
}

func drawIcon(pixels: Int) -> CGImage {
    let context = CGContext(
        data: nil, width: pixels, height: pixels, bitsPerComponent: 8,
        bytesPerRow: pixels * 4, space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    let scale = CGFloat(pixels) / 1024
    context.scaleBy(x: scale, y: scale)
    let tile = CGPath(
        roundedRect: CGRect(x: 56, y: 56, width: 912, height: 912),
        cornerWidth: 222, cornerHeight: 222, transform: nil
    )
    context.addPath(tile)
    context.clip()

    let colors: [CGColor] = [color(0.06, 0.12, 0.29), color(0.14, 0.25, 0.63)]
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: nil)!
    context.drawLinearGradient(
        gradient, start: CGPoint(x: 90, y: 80), end: CGPoint(x: 894, y: 944),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )

    let mint = color(0.56, 1.0, 0.85)
    context.setStrokeColor(mint)
    context.setLineWidth(76)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.move(to: CGPoint(x: 300, y: 334))
    context.addLine(to: CGPoint(x: 425, y: 334))
    context.addQuadCurve(to: CGPoint(x: 524, y: 408), control: CGPoint(x: 484, y: 334))
    context.addLine(to: CGPoint(x: 680, y: 659))
    context.strokePath()
    context.move(to: CGPoint(x: 535, y: 660))
    context.addLine(to: CGPoint(x: 702, y: 660))
    context.addLine(to: CGPoint(x: 702, y: 493))
    context.strokePath()
    context.setFillColor(mint)
    context.fillEllipse(in: CGRect(x: 249, y: 283, width: 102, height: 102))

    return context.makeImage()!
}

let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)" + (scale == 1 ? "" : "@2x")
        let bitmap = NSBitmapImageRep(cgImage: drawIcon(pixels: points * scale))
        let png = bitmap.representation(using: .png, properties: [:])!
        try png.write(to: directory.appendingPathComponent(name + ".png"))
    }
}
