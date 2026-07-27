import AppKit
import PDFKit

enum ExportFormat {
    case txt, pdf, markdown
}

struct ExportService {
    static func export(text: String, format: ExportFormat) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        switch format {
        case .txt:
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "Untitled.txt"
        case .pdf:
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "Untitled.pdf"
        case .markdown:
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "Untitled.md"
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }

        switch format {
        case .txt:
            try? text.write(to: url, atomically: true, encoding: .utf8)
        case .markdown:
            try? text.write(to: url, atomically: true, encoding: .utf8)
        case .pdf:
            generatePDF(text: text, to: url)
        }
    }

    private static func generatePDF(text: String, to url: URL) {
        let font = NSFont.monospacedSystemFont(ofSize: 22, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(red: 27/255, green: 27/255, blue: 27/255, alpha: 1)
        ]
        let attributed = NSAttributedString(string: text, attributes: attrs)
        let textRect = CGRect(x: 72, y: 72, width: 612 - 144, height: 792 - 144)

        let frameSetter = CTFramesetterCreateWithAttributedString(attributed)
        let path = CGPath(rect: textRect, transform: nil)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)

        let data = NSMutableData()
        let consumer = CGDataConsumer(data: data)!
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)

        guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return }

        ctx.beginPDFPage(nil)
        ctx.setFillColor(CGColor(red: 250/255, green: 250/255, blue: 248/255, alpha: 1))
        ctx.fill(mediaBox)
        CTFrameDraw(frame, ctx)
        ctx.endPDFPage()
        ctx.closePDF()

        try? data.write(to: url, options: .atomic)
    }
}
