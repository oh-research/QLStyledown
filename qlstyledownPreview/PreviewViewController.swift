//
//  PreviewViewController.swift
//  qlstyledownPreview
//
//  Created by SeminOH on 3/18/26.
//

import Cocoa
import Quartz
import WebKit

class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate {

    private var webView: WKWebView!

    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let config = WKWebViewConfiguration()
        config.preferences.setValue(false, forKey: "javaScriptCanOpenWindowsAutomatically")

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        view.addSubview(webView)
    }

    // MARK: - Preview

    func preparePreviewOfFile(at url: URL) async throws {
        let rawMarkdown = try readMarkdownFile(at: url)
        let (frontmatter, markdown) = parseFrontmatter(rawMarkdown)

        guard let data = markdown.data(using: .utf8) else {
            throw PreviewError.encodingFailed
        }

        let bundle = Bundle(for: type(of: self))
        let mdParentDir = url.deletingLastPathComponent()

        let html = try assembleHTML(
            bundle: bundle,
            base64: data.base64EncodedString(),
            userCSS: loadUserCSS(frontmatter: frontmatter, mdDirectory: mdParentDir)
        )

        let tempHTML = FileManager.default.temporaryDirectory
            .appendingPathComponent(".qlstyledown-preview.html")
        try html.write(to: tempHTML, atomically: true, encoding: .utf8)
        webView.loadFileURL(tempHTML, allowingReadAccessTo: FileManager.default.temporaryDirectory)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            try? FileManager.default.removeItem(at: tempHTML)
        }
    }

    // MARK: - HTML 조립

    private func assembleHTML(bundle: Bundle, base64: String, userCSS: String) throws -> String {
        guard let template = loadResource(bundle: bundle, name: "template", ext: "html") else {
            throw PreviewError.templateNotFound
        }
        guard let defaultCSS = loadResource(bundle: bundle, name: "default", ext: "css") else {
            throw PreviewError.cssNotFound
        }
        guard let markdownItJS = loadResource(bundle: bundle, name: "markdown-it.min", ext: "js") else {
            throw PreviewError.jsNotFound
        }

        let highlightCSS = buildHighlightCSS(bundle: bundle)

        let substitutions: [(String, String, EscapeType)] = [
            ("{{DEFAULT_CSS}}", defaultCSS, .style),
            ("{{HIGHLIGHT_CSS}}", highlightCSS, .style),
            ("{{USER_CSS}}", userCSS, .style),
            ("{{KATEX_CSS}}", loadResource(bundle: bundle, name: "katex.min", ext: "css") ?? "", .style),
            ("{{MARKDOWN_IT_JS}}", markdownItJS, .script),
            ("{{HIGHLIGHT_JS}}", loadResource(bundle: bundle, name: "highlight.min", ext: "js") ?? "", .script),
            ("{{KATEX_JS}}", loadResource(bundle: bundle, name: "katex.min", ext: "js") ?? "", .script),
            ("{{TEXMATH_JS}}", loadResource(bundle: bundle, name: "markdown-it-texmath.min", ext: "js") ?? "", .script),
            ("{{DOMPURIFY_JS}}", loadResource(bundle: bundle, name: "purify.min", ext: "js") ?? "", .script),
            ("{{MERMAID_JS}}", loadResource(bundle: bundle, name: "mermaid.min", ext: "js") ?? "", .script),
            ("{{MARKDOWN_BASE64}}", base64, .none),
        ]

        var html = template
        for (placeholder, content, escape) in substitutions {
            html = html.replacingOccurrences(of: placeholder, with: escaped(content, type: escape))
        }
        return html
    }

    // MARK: - 번들 리소스

    private func loadResource(bundle: Bundle, name: String, ext: String) -> String? {
        guard let url = bundle.url(forResource: name, withExtension: ext) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private func buildHighlightCSS(bundle: Bundle) -> String {
        let light = loadResource(bundle: bundle, name: "highlight-github", ext: "css") ?? ""
        let dark = loadResource(bundle: bundle, name: "highlight-github-dark", ext: "css") ?? ""
        return light + "\n@media (prefers-color-scheme: dark) {\n" + dark + "\n}\n"
    }

    // MARK: - 인젝션 방지

    private enum EscapeType { case style, script, none }

    private func escaped(_ content: String, type: EscapeType) -> String {
        switch type {
        case .style:  return content.replacingOccurrences(of: "</style>", with: "<\\/style>")
        case .script: return content.replacingOccurrences(of: "</script>", with: "<\\/script>")
        case .none:   return content
        }
    }

    // MARK: - Frontmatter 파싱

    private func parseFrontmatter(_ text: String) -> (css: String?, body: String) {
        let lines = text.components(separatedBy: .newlines)

        guard !lines.isEmpty, lines[0].trimmingCharacters(in: .whitespaces) == "---" else {
            return (nil, text)
        }

        var endIndex: Int?
        for i in 1..<lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                endIndex = i
                break
            }
        }

        guard let end = endIndex else {
            return (nil, text)
        }

        var cssValue: String?
        for i in 1..<end {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.lowercased().hasPrefix("css:") {
                let value = line.dropFirst(4).trimmingCharacters(in: .whitespaces)
                if !value.isEmpty { cssValue = value }
                break
            }
        }

        let body = lines[(end + 1)...].joined(separator: "\n")
        return (cssValue, body)
    }

    // MARK: - CSS 우선순위 탐색

    private func loadUserCSS(frontmatter: String?, mdDirectory: URL) -> String {
        if let cssFilename = frontmatter {
            let cssURL = mdDirectory.appendingPathComponent(cssFilename)
            if let css = try? String(contentsOf: cssURL, encoding: .utf8) { return css }
        }

        let localCSS = mdDirectory.appendingPathComponent("style.css")
        if let css = try? String(contentsOf: localCSS, encoding: .utf8) { return css }

        if let containerCSS = AppGroupConstants.containerCSSURL,
           let css = try? String(contentsOf: containerCSS, encoding: .utf8) { return css }

        return ""
    }

    // MARK: - Markdown 파일 읽기 (인코딩 fallback)

    private func readMarkdownFile(at url: URL) throws -> String {
        let rawData = try Data(contentsOf: url)

        // BOM 감지
        if rawData.starts(with: [0xEF, 0xBB, 0xBF]),
           let text = String(data: Data(rawData.dropFirst(3)), encoding: .utf8) { return text }
        if rawData.starts(with: [0xFF, 0xFE]),
           let text = String(data: rawData, encoding: .utf16LittleEndian) { return text }
        if rawData.starts(with: [0xFE, 0xFF]),
           let text = String(data: rawData, encoding: .utf16BigEndian) { return text }

        if let text = String(data: rawData, encoding: .utf8) { return text }

        // EUC-KR fallback
        let cfEncoding = CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.EUC_KR.rawValue)
        )
        if let text = String(data: rawData, encoding: String.Encoding(rawValue: cfEncoding)) { return text }

        throw PreviewError.unsupportedEncoding
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        switch url.scheme {
        case "file", "data":
            decisionHandler(.allow)
        case "http", "https":
            if navigationAction.navigationType == .linkActivated {
                NSWorkspace.shared.open(url)
            }
            decisionHandler(.cancel)
        default:
            decisionHandler(.cancel)
        }
    }
}

// MARK: - Errors

enum PreviewError: Error, LocalizedError {
    case encodingFailed
    case templateNotFound
    case cssNotFound
    case jsNotFound
    case unsupportedEncoding

    var errorDescription: String? {
        switch self {
        case .encodingFailed:    return "Failed to encode markdown as UTF-8"
        case .templateNotFound:  return "template.html not found in bundle"
        case .cssNotFound:       return "default.css not found in bundle"
        case .jsNotFound:        return "markdown-it.min.js not found in bundle"
        case .unsupportedEncoding: return "Unsupported file encoding"
        }
    }
}
