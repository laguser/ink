import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = false
        webView.allowsBackForwardNavigationGestures = false
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(htmlPage, baseURL: nil)
    }

    private var htmlPage: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: -apple-system, "SF Mono", Menlo, monospace;
                font-size: 15px;
                line-height: 1.7;
                color: #1d1d1f;
                padding: 24px 60px;
                max-width: 800px;
                background: #fafaf8;
            }
            h1 { font-size: 1.8em; margin: 0.8em 0 0.4em; font-weight: 700; }
            h2 { font-size: 1.4em; margin: 0.7em 0 0.3em; font-weight: 600; }
            h3 { font-size: 1.2em; margin: 0.6em 0 0.3em; font-weight: 600; }
            p { margin: 0.6em 0; }
            ul, ol { margin: 0.5em 0; padding-left: 1.8em; }
            li { margin: 0.2em 0; }
            code {
                font-family: "SF Mono", Menlo, monospace;
                background: #e8e8e4;
                padding: 0.15em 0.4em;
                border-radius: 3px;
                font-size: 0.9em;
            }
            pre {
                background: #e8e8e4;
                padding: 12px 16px;
                border-radius: 6px;
                overflow-x: auto;
                margin: 0.6em 0;
            }
            pre code { background: none; padding: 0; border-radius: 0; }
            blockquote {
                border-left: 3px solid #c0c0c0;
                margin: 0.6em 0;
                padding: 4px 16px;
                color: #555;
            }
            a { color: #007aff; text-decoration: none; }
            a:hover { text-decoration: underline; }
            hr { border: none; border-top: 1px solid #d0d0d0; margin: 1em 0; }
            img { max-width: 100%; border-radius: 4px; margin: 0.5em 0; }
            table { border-collapse: collapse; margin: 0.6em 0; width: 100%; }
            th, td { border: 1px solid #d0d0d0; padding: 6px 10px; text-align: left; }
            th { background: #e8e8e4; font-weight: 600; }
            strong { font-weight: 700; }
            em { font-style: italic; }
        </style>
        </head>
        <body>\(renderedHTML)</body>
        </html>
        """
    }

    private var renderedHTML: String {
        let escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return markdownToHTML(escaped)
    }

    private func markdownToHTML(_ md: String) -> String {
        var html = md

        html = html.replacingOccurrences(of: "\\n", with: "\n")

        html = applyBlockPattern(html, pattern: #"^### (.+)$"#, template: "<h3>$1</h3>")
        html = applyBlockPattern(html, pattern: #"^## (.+)$"#, template: "<h2>$1</h2>")
        html = applyBlockPattern(html, pattern: #"^# (.+)$"#, template: "<h1>$1</h1>")

        html = applyBlockPattern(html, pattern: #"^> (.+)$"#, template: "<blockquote><p>$1</p></blockquote>")

        html = applyBlockPattern(html, pattern: #"^-{3,}$"#, template: "<hr>")

        html = applyBlockPattern(html, pattern: #"^```(\w*)\n([\s\S]*?)```"#, multiline: true) { groups in
            let code = groups[2].trimmingCharacters(in: .newlines)
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            return "<pre><code>\(code)</code></pre>"
        }

        html = applyBlockPattern(html, pattern: #"^`([^`]+)`$"#, template: "<code>$1</code>")

        html = convertInline(html)

        html = applyBlockPattern(html, pattern: #"^(\d+)\. (.+)$"#, template: "<li>$2</li>")
        html = applyBlockPattern(html, pattern: #"^[-*] (.+)$"#, template: "<li>$1</li>")

        html = wrapLists(html)

        let lines = html.components(separatedBy: "\n")
        var result: [String] = []
        var inParagraph = false
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if inParagraph { result.append("</p>"); inParagraph = false }
                continue
            }
            if trimmed.hasPrefix("<h") || trimmed.hasPrefix("<li") || trimmed.hasPrefix("<pre") ||
               trimmed.hasPrefix("<blockquote") || trimmed.hasPrefix("<hr") || trimmed.hasPrefix("<ul") ||
               trimmed.hasPrefix("<ol") || trimmed == "</ul>" || trimmed == "</ol>" || trimmed == "</li>" {
                if inParagraph { result.append("</p>"); inParagraph = false }
                result.append(line)
                continue
            }
            if !inParagraph { result.append("<p>"); inParagraph = true }
            result.append(line)
        }
        if inParagraph { result.append("</p>") }
        return result.joined(separator: "\n")
    }

    private func applyBlockPattern(_ text: String, pattern: String, template: String) -> String {
        text.split(separator: "\n").map { line in
            let s = String(line)
            if let r = s.range(of: pattern, options: .regularExpression) {
                let matched = s[s.startIndex..<r.lowerBound] + s[r]
                let cap = String(matched) as NSString
                guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines),
                      let match = regex.firstMatch(in: String(matched), range: NSRange(matched.startIndex..., in: matched))
                else { return s }
                var result = template
                for i in 1..<match.numberOfRanges {
                    let range = match.range(at: i)
                    if range.location != NSNotFound {
                        let capture = cap.substring(with: range)
                        result = result.replacingOccurrences(of: "$\(i)", with: capture)
                    }
                }
                return result
            }
            return s
        }.joined(separator: "\n")
    }

    private func applyBlockPattern(_ text: String, pattern: String, multiline: Bool, transform: ([String]) -> String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return text }
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        var result = text
        var offset = 0
        regex.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match else { return }
            var groups: [String] = []
            for i in 0..<match.numberOfRanges {
                let r = match.range(at: i)
                if r.location != NSNotFound {
                    groups.append(nsText.substring(with: r))
                }
            }
            let replacement = transform(groups)
            let matchRange = NSRange(location: match.range.location + offset, length: match.range.length)
            let nsResult = result as NSString
            result = nsResult.replacingCharacters(in: matchRange, with: replacement)
            offset += (replacement as NSString).length - match.range.length
        }
        return result
    }

    private func convertInline(_ text: String) -> String {
        var r = text
        r = inlineReplace(r, pattern: #"\*\*\*(.+?)\*\*\*"#, template: "<strong><em>$1</em></strong>")
        r = inlineReplace(r, pattern: #"\*\*(.+?)\*\*"#, template: "<strong>$1</strong>")
        r = inlineReplace(r, pattern: #"\*(.+?)\*"#, template: "<em>$1</em>")
        r = inlineReplace(r, pattern: #"`([^`]+)`"#, template: "<code>$1</code>")
        r = inlineReplace(r, pattern: #"\[([^\]]+)\]\(([^)]+)\)"#, template: "<a href=\"$2\">$1</a>")
        r = inlineReplace(r, pattern: #"!\[([^\]]*)\]\(([^)]+)\)"#, template: "<img src=\"$2\" alt=\"$1\">")
        r = inlineReplace(r, pattern: #"~~(.+?)~~"#, template: "<del>$1</del>")
        return r
    }

    private func inlineReplace(_ text: String, pattern: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: template)
    }

    private func wrapLists(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        var result: [String] = []
        var inList = false
        var listType = ""
        for line in lines {
            if line.hasPrefix("<li") {
                if !inList {
                    listType = isOrderedItem(line) ? "ol" : "ul"
                    result.append("<\(listType)>")
                    inList = true
                }
                result.append(line)
            } else {
                if inList { result.append("</\(listType)>"); inList = false }
                result.append(line)
            }
        }
        if inList { result.append("</\(listType)>") }
        return result.joined(separator: "\n")
    }

    private func isOrderedItem(_ line: String) -> Bool {
        let s = line.trimmingCharacters(in: .whitespaces)
        return s.hasPrefix("<li") && s.range(of: "<li>\\d+\\.", options: .regularExpression) != nil
    }
}
