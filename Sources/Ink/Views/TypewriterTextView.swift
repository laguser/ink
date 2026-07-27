import SwiftUI
import AppKit

struct TypewriterTextView: NSViewRepresentable {
    let viewModel: EditorViewModel
    let windowWidth: CGFloat
    let isSpellCheckEnabled: Bool
    let fontSize: Double
    let fontName: String
    let lineHeight: Double

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsetsZero
        scrollView.scrollsDynamically = true

        let textView = TypewriterCoreTextView()
        textView.wantsLayer = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.usesFontPanel = false
        textView.usesFindBar = false
        textView.allowsUndo = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainerInset = NSSize(width: 8, height: 8)

        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = isSpellCheckEnabled
        textView.isContinuousSpellCheckingEnabled = isSpellCheckEnabled
        textView.isGrammarCheckingEnabled = isSpellCheckEnabled
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.smartInsertDeleteEnabled = false

        textView.selectedTextAttributes = [
            .backgroundColor: NSColor.selectedTextBackgroundColor,
            .foregroundColor: NSColor.black
        ]
        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        scrollView.documentView = textView

        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? TypewriterCoreTextView else { return }

        if textView.string != viewModel.text && !context.coordinator.isUpdating {
            context.coordinator.isUpdating = true
            textView.string = viewModel.text
            applyTypography(textView, fontSize: fontSize)
            if viewModel.cursorPosition <= viewModel.text.count {
                textView.setSelectedRange(NSRange(location: viewModel.cursorPosition, length: 0))
            }
            context.coordinator.isUpdating = false
        }

        let font: NSFont = NSFont(name: fontName, size: fontSize)
            ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.font = font
        textView.textColor = .inkText
        textView.window?.makeFirstResponder(textView)
        textView.needsDisplay = true

        applyTypography(textView, fontSize: fontSize)
    }

    private func applyTypography(_ textView: NSTextView, fontSize: CGFloat) {
        let ps = NSMutableParagraphStyle()
        let lh = fontSize * viewModel.lineHeight
        ps.minimumLineHeight = lh
        ps.maximumLineHeight = lh

        textView.defaultParagraphStyle = ps
        textView.typingAttributes[.paragraphStyle] = ps

        if let storage = textView.textStorage, storage.length > 0 {
            storage.addAttribute(.paragraphStyle, value: ps, range: NSRange(location: 0, length: storage.length))
        }
    }
}

// MARK: – Coordinator

extension TypewriterTextView {
    final class Coordinator: NSObject, NSTextViewDelegate {
        let viewModel: EditorViewModel
        weak var textView: NSTextView?
        var isUpdating = false

        init(viewModel: EditorViewModel) {
            self.viewModel = viewModel
        }

        @MainActor
        func handleKeyEvent(_ event: NSEvent) -> Bool {
            guard viewModel.showSuggestions else { return false }
            switch event.keyCode {
            case 48: // Tab
                viewModel.selectNextSuggestion()
                return true
            case 36: // Enter / Return
                return viewModel.applySelectedSuggestion()
            case 53: // Escape
                viewModel.dismissSuggestions()
                return true
            default:
                return false
            }
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn range: NSRange, replacementString: String?) -> Bool {
            guard let replacement = replacementString else { return true }

            if (replacement == "\t" || replacement == "\n" || replacement == "\u{1b}") && viewModel.showSuggestions {
                switch replacement {
                case "\t":  viewModel.selectNextSuggestion(); return false
                case "\n":  return !viewModel.applySelectedSuggestion()
                case "\u{1b}": viewModel.dismissSuggestions(); return false
                default: break
                }
            }

            let transformed = PluginManager.shared.transformReplacement(replacement, range: range, text: textView.string)
            if transformed != replacement {
                textView.replaceCharacters(in: range, with: transformed)
                textView.setSelectedRange(NSRange(location: range.location + (transformed as NSString).length, length: 0))
                viewModel.onCharacterTyped(replacement)
                viewModel.onTextChanged(textView.string, cursor: range.location + (transformed as NSString).length)
                return false
            }

            if replacement.isEmpty {
                viewModel.onDelete()
            } else {
                viewModel.onCharacterTyped(replacement)
            }
            return true
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let tv = notification.object as? NSTextView else { return }
            viewModel.onTextChanged(tv.string, cursor: tv.selectedRange().location)
            let rect = tv.firstRect(forCharacterRange: NSRange(location: tv.selectedRange().location, length: 0), actualRange: nil)
            let windowRect = tv.window?.convertFromScreen(rect) ?? .zero
            let viewRect = tv.convert(windowRect, from: nil)
            viewModel.updateSuggestions(cursorRect: viewRect)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isUpdating, let tv = notification.object as? NSTextView else { return }
            viewModel.cursorPosition = tv.selectedRange().location
            let selectedWord = selectedWord(in: tv)
            PluginManager.shared.highlightSelection(word: selectedWord, in: tv.textStorage)
            PluginManager.shared.updateFocus(in: tv, cursor: tv.selectedRange().location)
        }

        private func selectedWord(in tv: NSTextView) -> String? {
            let range = tv.selectedRange()
            guard range.length > 0 else { return nil }
            let text = (tv.string as NSString)
            let wordRange = text.doubleRange(for: range)
            guard wordRange.length > 0 else { return nil }
            return text.substring(with: wordRange)
        }
    }
}

// MARK: – Core Text View

final class TypewriterCoreTextView: NSTextView {
    override func keyDown(with event: NSEvent) {
        if let coordinator = delegate as? TypewriterTextView.Coordinator,
           coordinator.handleKeyEvent(event) {
            return
        }
        super.keyDown(with: event)
    }

    override func insertText(_ string: Any, replacementRange: NSRange) {
        super.insertText(string, replacementRange: replacementRange)
        animateTyping()
        let loc = replacementRange.location + ((string as? NSString)?.length ?? 0)
        PluginManager.shared.emitParticles(at: self, cursor: loc)
    }

    private func animateTyping() {
        guard let layer = superview?.layer ?? self.layer else { return }

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0.92
        fade.toValue = 1.0
        fade.duration = 0.04
        fade.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let move = CABasicAnimation(keyPath: "transform.translation.y")
        move.fromValue = 1.0
        move.toValue = 0.0
        move.duration = 0.04
        move.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let group = CAAnimationGroup()
        group.animations = [fade, move]
        group.duration = 0.04
        group.isRemovedOnCompletion = true

        layer.add(group, forKey: "typingAnimation")
    }
}

extension NSString {
    func doubleRange(for range: NSRange) -> NSRange {
        let len = length
        let charSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        var start = range.location
        while start > 0 {
            let c = character(at: start - 1)
            if let scalar = UnicodeScalar(c), charSet.contains(scalar) { start -= 1 }
            else { break }
        }
        var end = range.location + range.length
        while end < len {
            let c = character(at: end)
            if let scalar = UnicodeScalar(c), charSet.contains(scalar) { end += 1 }
            else { break }
        }
        return NSRange(location: start, length: end - start)
    }
}


