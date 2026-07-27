import SwiftUI

struct PaperView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(PaperBackground())
    }
}

struct PaperBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> PaperTextureNSView {
        PaperTextureNSView()
    }

    func updateNSView(_ nsView: PaperTextureNSView, context: Context) {}
}

final class PaperTextureNSView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { nil }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let rect = bounds
        ctx.setFillColor(CGColor(red: 250/255, green: 250/255, blue: 248/255, alpha: 1))
        ctx.fill(rect)
        drawPaperFibers(in: ctx, rect: rect)
        drawVignette(in: ctx, rect: rect)
    }

    private func drawPaperFibers(in ctx: CGContext, rect: CGRect) {
        let scale = max(rect.width, rect.height) / 800
        let fiberCount = Int(120 * scale)
        for _ in 0..<fiberCount {
            let x = CGFloat.random(in: rect.minX...rect.maxX)
            let y = CGFloat.random(in: rect.minY...rect.maxY)
            let w = CGFloat.random(in: 4...20) * scale
            let h: CGFloat = 0.3 * scale
            let angle = CGFloat.random(in: 0...(.pi))
            ctx.saveGState()
            ctx.translateBy(x: x, y: y)
            ctx.rotate(by: angle)
            ctx.setFillColor(CGColor(gray: 0, alpha: CGFloat.random(in: 0.02...0.07)))
            ctx.fillEllipse(in: CGRect(x: -w/2, y: -h/2, width: w, height: h))
            ctx.restoreGState()
        }
    }

    private func drawVignette(in ctx: CGContext, rect: CGRect) {
        let colors: [CGColor] = [
            CGColor(gray: 0, alpha: 0.06),
            CGColor(gray: 0, alpha: 0)
        ]
        let locations: [CGFloat] = [0.75, 1.0]
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceGray(),
            colors: colors as CFArray,
            locations: locations
        ) else { return }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(rect.width, rect.height) * 0.75
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: .drawsAfterEndLocation)
    }
}
