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

    func preparePreviewOfFile(at url: URL) async throws {
        // 1. .md 파일 읽기
        let rawMarkdown = try readMarkdownFile(at: url)

        // 2. frontmatter 파싱
        let (frontmatter, markdown) = parseFrontmatter(rawMarkdown)

        // 3. Base64 인코딩
        guard let data = markdown.data(using: .utf8) else {
            throw PreviewError.encodingFailed
        }
        let base64 = data.base64EncodedString()

        // 4. 번들 리소스 읽기
        let bundle = Bundle(for: type(of: self))

        guard let templateURL = bundle.url(forResource: "template", withExtension: "html"),
              let templateString = try? String(contentsOf: templateURL, encoding: .utf8) else {
            throw PreviewError.templateNotFound
        }

        guard let cssURL = bundle.url(forResource: "default", withExtension: "css"),
              let cssString = try? String(contentsOf: cssURL, encoding: .utf8) else {
            throw PreviewError.cssNotFound
        }

        guard let jsURL = bundle.url(forResource: "markdown-it.min", withExtension: "js"),
              let jsString = try? String(contentsOf: jsURL, encoding: .utf8) else {
            throw PreviewError.jsNotFound
        }

        // highlight.js (optional — 없어도 동작)
        let highlightJS = (try? String(contentsOf: bundle.url(forResource: "highlight.min", withExtension: "js")!, encoding: .utf8)) ?? ""

        // highlight.js CSS (light + dark 합쳐서 삽입)
        let highlightCSSLight = (try? String(contentsOf: bundle.url(forResource: "highlight-github", withExtension: "css")!, encoding: .utf8)) ?? ""
        let highlightCSSDark = (try? String(contentsOf: bundle.url(forResource: "highlight-github-dark", withExtension: "css")!, encoding: .utf8)) ?? ""
        let highlightCSS = highlightCSSLight + "\n@media (prefers-color-scheme: dark) {\n" + highlightCSSDark + "\n}\n"

        // 5. 사용자 CSS 탐색 (우선순위: frontmatter → 로컬 → 글로벌)
        let mdParentDir = url.deletingLastPathComponent()
        let userCSS = loadUserCSS(frontmatter: frontmatter, mdDirectory: mdParentDir)

        // 6. 치환 (인젝션 방지)
        let safeDefaultCSS = cssString.replacingOccurrences(of: "</style>", with: "<\\/style>")
        let safeHighlightCSS = highlightCSS.replacingOccurrences(of: "</style>", with: "<\\/style>")
        let safeUserCSS = userCSS.replacingOccurrences(of: "</style>", with: "<\\/style>")
        let safeJS = jsString.replacingOccurrences(of: "</script>", with: "<\\/script>")
        let safeHighlightJS = highlightJS.replacingOccurrences(of: "</script>", with: "<\\/script>")

        // 7. 템플릿 조립
        var html = templateString
        html = html.replacingOccurrences(of: "{{DEFAULT_CSS}}", with: safeDefaultCSS)
        html = html.replacingOccurrences(of: "{{HIGHLIGHT_CSS}}", with: safeHighlightCSS)
        html = html.replacingOccurrences(of: "{{USER_CSS}}", with: safeUserCSS)
        html = html.replacingOccurrences(of: "{{MARKDOWN_IT_JS}}", with: safeJS)
        html = html.replacingOccurrences(of: "{{HIGHLIGHT_JS}}", with: safeHighlightJS)
        html = html.replacingOccurrences(of: "{{MARKDOWN_BASE64}}", with: base64)

        // 8. temp 파일에 저장 + loadFileURL로 로드
        // temp 파일과 .md 부모 디렉토리 모두 접근 가능하도록
        // temp 디렉토리에 저장하고, allowingReadAccessTo에 두 경로의 공통 상위를 사용
        let tempDir = FileManager.default.temporaryDirectory
        let tempHTML = tempDir.appendingPathComponent("qlstyledown-preview.html")
        try html.write(to: tempHTML, atomically: true, encoding: .utf8)

        // 9. loadFileURL로 로드
        // temp 파일 읽기를 위해 allowingReadAccessTo를 "/" 로 설정
        // (sandbox extension이 이미 .md 부모 디렉토리와 temp에 접근 허용)
        webView.loadFileURL(tempHTML, allowingReadAccessTo: URL(fileURLWithPath: "/"))
    }

    // MARK: - Frontmatter 파싱

    /// 제한된 frontmatter parser: 첫 줄이 "---"인 경우에만 파싱, css: 키만 추출
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

        // frontmatter 블록에서 css: 키 추출
        var cssValue: String?
        for i in 1..<end {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.lowercased().hasPrefix("css:") {
                let value = line.dropFirst(4).trimmingCharacters(in: .whitespaces)
                if !value.isEmpty {
                    cssValue = value
                }
                break
            }
        }

        // frontmatter 제거한 본문
        let bodyLines = Array(lines[(end + 1)...])
        let body = bodyLines.joined(separator: "\n")

        return (cssValue, body)
    }

    // MARK: - CSS 우선순위 탐색

    /// 우선순위: frontmatter CSS → 로컬 style.css → 글로벌 CSS (App Group Container)
    private func loadUserCSS(frontmatter: String?, mdDirectory: URL) -> String {
        // 1. frontmatter 지정 CSS
        if let cssFilename = frontmatter {
            let cssURL = mdDirectory.appendingPathComponent(cssFilename)
            if let css = try? String(contentsOf: cssURL, encoding: .utf8) {
                return css
            }
        }

        // 2. 로컬 style.css
        let localCSS = mdDirectory.appendingPathComponent("style.css")
        if let css = try? String(contentsOf: localCSS, encoding: .utf8) {
            return css
        }

        // 3. 글로벌 CSS (App Group Container)
        if let containerCSS = AppGroupConstants.containerCSSURL,
           let css = try? String(contentsOf: containerCSS, encoding: .utf8) {
            return css
        }

        // 사용자 CSS 없음 → 빈 문자열 (default.css만 적용)
        return ""
    }

    // MARK: - Markdown 파일 읽기 (인코딩 fallback)

    private func readMarkdownFile(at url: URL) throws -> String {
        let rawData = try Data(contentsOf: url)

        // BOM 감지
        if rawData.starts(with: [0xEF, 0xBB, 0xBF]) {
            let textData = rawData.dropFirst(3)
            if let text = String(data: Data(textData), encoding: .utf8) {
                return text
            }
        }

        if rawData.starts(with: [0xFF, 0xFE]) {
            if let text = String(data: rawData, encoding: .utf16LittleEndian) {
                return text
            }
        }

        if rawData.starts(with: [0xFE, 0xFF]) {
            if let text = String(data: rawData, encoding: .utf16BigEndian) {
                return text
            }
        }

        // UTF-8 시도
        if let text = String(data: rawData, encoding: .utf8) {
            return text
        }

        // EUC-KR fallback
        let cfEncoding = CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.EUC_KR.rawValue)
        )
        if let text = String(data: rawData, encoding: String.Encoding(rawValue: cfEncoding)) {
            return text
        }

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
        case .encodingFailed:
            return "Failed to encode markdown as UTF-8"
        case .templateNotFound:
            return "template.html not found in bundle"
        case .cssNotFound:
            return "default.css not found in bundle"
        case .jsNotFound:
            return "markdown-it.min.js not found in bundle"
        case .unsupportedEncoding:
            return "Unsupported file encoding"
        }
    }
}
