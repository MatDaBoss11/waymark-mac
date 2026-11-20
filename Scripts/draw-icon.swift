import AppKit

let size = 1024
let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
    let tile = NSBezierPath(roundedRect: NSRect(x: 80, y: 80, width: 864, height: 864), xRadius: 190, yRadius: 190)
    NSGradient(
        starting: NSColor(srgbRed: 0.12, green: 0.28, blue: 0.23, alpha: 1),
        ending: NSColor(srgbRed: 0.26, green: 0.43, blue: 0.32, alpha: 1)
    )?.draw(in: tile, angle: 45)

    NSGraphicsContext.saveGraphicsState()
    tile.addClip()
    NSColor(srgbRed: 0.76, green: 0.86, blue: 0.72, alpha: 0.20).setStroke()
    for radius in stride(from: 130.0, through: 460, by: 55) {
        let contour = NSBezierPath(ovalIn: NSRect(x: 750 - radius, y: 720 - radius,
                                                 width: 2 * radius, height: 2 * radius))
        contour.lineWidth = 3
        contour.stroke()
    }
    NSGraphicsContext.restoreGraphicsState()

    let sign = NSBezierPath()
    sign.move(to: NSPoint(x: 300, y: 657))
    sign.line(to: NSPoint(x: 602, y: 657))
    sign.line(to: NSPoint(x: 742, y: 563))
    sign.line(to: NSPoint(x: 602, y: 469))
    sign.line(to: NSPoint(x: 300, y: 469))
    sign.close()
    NSColor(srgbRed: 0.96, green: 0.93, blue: 0.81, alpha: 1).setFill()
    sign.fill()

    let post = NSBezierPath()
    post.move(to: NSPoint(x: 424, y: 329))
    post.line(to: NSPoint(x: 424, y: 463))
    post.lineWidth = 37
    post.lineCapStyle = .round
    NSColor(srgbRed: 0.96, green: 0.93, blue: 0.81, alpha: 1).setStroke()
    post.stroke()

    NSColor(srgbRed: 0.91, green: 0.65, blue: 0.39, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 486, y: 542, width: 43, height: 43)).fill()
    return true
}

func png(at size: Int) -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Could not create icon canvas")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode the icon")
    }
    return data
}

func record(_ type: String, payload: Data) -> Data {
    var data = Data(type.utf8)
    var length = UInt32(payload.count + 8).bigEndian
    withUnsafeBytes(of: &length) { data.append(contentsOf: $0) }
    data.append(payload)
    return data
}

let sizes = [("icp4", 16), ("icp5", 32), ("icp6", 64), ("ic07", 128), ("ic08", 256), ("ic09", 512), ("ic10", 1024)]
var icons = Data()
for (type, size) in sizes {
    icons.append(record(type, payload: png(at: size)))
}
try record("icns", payload: icons).write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
