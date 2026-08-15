import SwiftUI

/// Deterministic RNG so a given element's "hand-drawn wobble" stays stable
/// across redraws instead of flickering every frame (a seed is stored per
/// DrawingElement and fed in here).
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed)) &+ 0x9E3779B97F4A7C15
        if state == 0 { state = 0x9E3779B97F4A7C15 }
    }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

/// Renders "perfect" geometry (lines, rectangles, ellipses) the way
/// Excalidraw / rough.js do: each edge is stroked twice with slight random
/// offsets and a gentle curve instead of a straight segment, so it reads as
/// hand-sketched rather than computer-drawn. Freehand pen strokes don't need
/// this treatment -- they're already irregular because a human drew them.
enum RoughRenderer {
    /// One wobbly pass between two points. `passSeed` differs per overlapping
    /// pass so the two strokes don't sit exactly on top of each other.
    private static func wobblyStroke(from a: CGPoint, to b: CGPoint, passSeed: Int) -> Path {
        var rng = SeededGenerator(seed: passSeed)
        let dist = max(hypot(b.x - a.x, b.y - a.y), 1)
        let jitter = min(max(dist * 0.018, 1.2), 5)

        func offset(_ p: CGPoint, scale: CGFloat) -> CGPoint {
            CGPoint(
                x: p.x + CGFloat.random(in: -jitter...jitter, using: &rng) * scale,
                y: p.y + CGFloat.random(in: -jitter...jitter, using: &rng) * scale
            )
        }

        let start = offset(a, scale: 0.6)
        let end = offset(b, scale: 0.6)
        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        let control = offset(mid, scale: 1.0)

        var path = Path()
        path.move(to: start)
        path.addQuadCurve(to: end, control: control)
        return path
    }

    /// A rough line between two points, both overlapping passes combined.
    static func roughLine(from a: CGPoint, to b: CGPoint, seed: Int) -> Path {
        var path = Path()
        path.addPath(wobblyStroke(from: a, to: b, passSeed: seed))
        path.addPath(wobblyStroke(from: a, to: b, passSeed: seed &+ 7919))
        return path
    }

    /// A rough closed/open polyline through a sequence of points (used for
    /// rectangles as 4 edges, and as the basis for the ellipse below).
    static func roughPolyline(points: [CGPoint], closed: Bool, seed: Int) -> Path {
        guard points.count >= 2 else { return Path() }
        var path = Path()
        var pts = points
        if closed { pts.append(points[0]) }
        for i in 0..<(pts.count - 1) {
            path.addPath(roughLine(from: pts[i], to: pts[i + 1], seed: seed &+ i * 131))
        }
        return path
    }

    static func roughRectangle(_ rect: CGRect, seed: Int) -> Path {
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY),
        ]
        return roughPolyline(points: corners, closed: true, seed: seed)
    }

    /// Unlike rectangles/lines, an ellipse can't be built from a handful of
    /// independently-jittered straight segments (roughPolyline) without
    /// reading as a many-sided polygon instead of a circle -- each segment's
    /// own random curve breaks tangent continuity with its neighbors. This
    /// instead samples many closely-spaced points around the true ellipse
    /// with a small proportional wobble, then threads one continuous
    /// quad-curve spline through them (each curve's endpoint is the
    /// midpoint of consecutive samples -- the standard smooth-through-
    /// points trick), stroked twice for the sketchy double-pass look.
    static func roughEllipse(_ rect: CGRect, seed: Int) -> Path {
        var path = Path()
        path.addPath(wobblyEllipsePass(rect, seed: seed))
        path.addPath(wobblyEllipsePass(rect, seed: seed &+ 6151))
        return path
    }

    private static func wobblyEllipsePass(_ rect: CGRect, seed: Int) -> Path {
        let steps = 48
        var rng = SeededGenerator(seed: seed)
        let cx = rect.midX, cy = rect.midY
        let rx = rect.width / 2, ry = rect.height / 2
        let wobble = min(rect.width, rect.height) * 0.012

        var points: [CGPoint] = []
        for i in 0..<steps {
            let t = (CGFloat(i) / CGFloat(steps)) * 2 * .pi
            let r = CGFloat.random(in: -wobble...wobble, using: &rng)
            points.append(CGPoint(x: cx + (rx + r) * cos(t), y: cy + (ry + r) * sin(t)))
        }

        var path = Path()
        path.move(to: points[0])
        for i in 1...points.count {
            let cur = points[i % points.count]
            let prev = points[i - 1]
            let mid = CGPoint(x: (prev.x + cur.x) / 2, y: (prev.y + cur.y) / 2)
            path.addQuadCurve(to: mid, control: prev)
        }
        path.closeSubpath()
        return path
    }

    /// Line plus a small V arrowhead at the end, all in the same sketchy style.
    static func roughArrow(from a: CGPoint, to b: CGPoint, seed: Int) -> Path {
        var path = Path()
        path.addPath(roughLine(from: a, to: b, seed: seed))

        let angle = atan2(b.y - a.y, b.x - a.x)
        let headLength: CGFloat = min(max(hypot(b.x - a.x, b.y - a.y) * 0.22, 10), 22)
        let headAngle: CGFloat = .pi / 7

        let left = CGPoint(x: b.x - headLength * cos(angle - headAngle), y: b.y - headLength * sin(angle - headAngle))
        let right = CGPoint(x: b.x - headLength * cos(angle + headAngle), y: b.y - headLength * sin(angle + headAngle))

        path.addPath(roughLine(from: b, to: left, seed: seed &+ 41))
        path.addPath(roughLine(from: b, to: right, seed: seed &+ 43))
        return path
    }

    /// Freehand pen: smooth the raw drag points (Catmull-Rom-ish averaging)
    /// so cursor micro-jitter doesn't look noisy, then stroke as one path.
    /// No added wobble -- real hand movement is already irregular.
    static func smoothedFreehand(points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 1 else {
            if let p = points.first {
                path.move(to: p)
                path.addLine(to: p)
            }
            return path
        }
        path.move(to: points[0])
        for i in 1..<points.count {
            let prev = points[i - 1]
            let cur = points[i]
            let mid = CGPoint(x: (prev.x + cur.x) / 2, y: (prev.y + cur.y) / 2)
            path.addQuadCurve(to: mid, control: prev)
        }
        path.addLine(to: points[points.count - 1])
        return path
    }
}
