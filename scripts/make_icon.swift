import AppKit

let sizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]
let iconsetPath = "AppIcon.iconset"

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let corner = size * 0.22

    let bgPath = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.20, green: 0.47, blue: 0.98, alpha: 1.0),
        NSColor(calibratedRed: 0.35, green: 0.20, blue: 0.90, alpha: 1.0)
    ])
    gradient?.draw(in: bgPath, angle: -60)

    // Clipboard glyph: rounded rect + clip + checkmark
    let glyphScale = size * 0.5
    let glyphRect = NSRect(x: (size - glyphScale) / 2, y: (size - glyphScale) / 2 - size*0.03, width: glyphScale, height: glyphScale)
    let glyphPath = NSBezierPath(roundedRect: glyphRect, xRadius: size*0.06, yRadius: size*0.06)
    NSColor.white.withAlphaComponent(0.95).setFill()
    glyphPath.fill()

    let clipW = glyphScale * 0.42
    let clipH = glyphScale * 0.16
    let clipRect = NSRect(x: (size - clipW)/2, y: glyphRect.maxY - clipH*0.5, width: clipW, height: clipH)
    let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: clipH*0.4, yRadius: clipH*0.4)
    gradient?.draw(in: clipPath, angle: -60)

    // Checkmark
    let check = NSBezierPath()
    let cx = glyphRect.midX
    let cy = glyphRect.midY - glyphScale*0.06
    let s = glyphScale * 0.22
    check.move(to: NSPoint(x: cx - s, y: cy))
    check.line(to: NSPoint(x: cx - s*0.25, y: cy - s*0.8))
    check.line(to: NSPoint(x: cx + s*1.1, y: cy + s*0.7))
    check.lineWidth = max(2, size * 0.045)
    check.lineCapStyle = .round
    check.lineJoinStyle = .round
    let checkColor = NSColor(calibratedRed: 0.20, green: 0.47, blue: 0.98, alpha: 1.0)
    checkColor.setStroke()
    check.stroke()

    image.unlockFocus()
    return image
}

try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

func save(_ image: NSImage, name: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { return }
    let url = URL(fileURLWithPath: "\(iconsetPath)/\(name)")
    try? png.write(to: url)
}

let mapping: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]

for (name, px) in mapping {
    let img = drawIcon(size: CGFloat(px))
    save(img, name: name)
}
print("done")
