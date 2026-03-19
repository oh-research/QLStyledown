//
//  ContentView.swift
//  qlstyledown
//
//  Created by SeminOH on 3/18/26.
//

import SwiftUI

struct ContentView: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        VStack(spacing: 0) {
            // 상단 앱 정보
            VStack(spacing: 12) {
                if let appIcon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 96, height: 96)
                }

                Text("qlstyledown")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Version \(version)")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text("Developed by oh-research")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Link("github.com/oh-research/QLStyledown",
                     destination: URL(string: "https://github.com/oh-research/QLStyledown")!)
                    .font(.caption)
            }
            .padding(.top, 28)
            .padding(.bottom, 20)

            Divider()

            // 상태 메시지
            VStack(spacing: 8) {
                Label("Quick Look Extension이 등록되었습니다.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                Text("Finder에서 .md 파일을 선택하고 Space를 눌러 미리보기하세요.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 16)

            Divider()

            // 라이브러리 크레딧
            ScrollView {
                VStack(spacing: 12) {
                    Text("Open Source Libraries")
                        .font(.headline)
                        .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 8) {
                        creditRow("markdown-it", desc: "Markdown parser", license: "MIT")
                        creditRow("highlight.js", desc: "Syntax highlighting", license: "BSD-3-Clause")
                        creditRow("KaTeX", desc: "Math typesetting", license: "MIT")
                        creditRow("markdown-it-texmath", desc: "LaTeX math plugin", license: "MIT")
                        creditRow("DOMPurify", desc: "HTML sanitizer", license: "Apache-2.0 / MPL-2.0")
                        creditRow("Mermaid", desc: "Diagram renderer", license: "MIT")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                    VStack(spacing: 4) {
                        Text("Themes inspired by")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Lapis (MIT) — YiNNx")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(width: 450, height: 720)
    }

    private func creditRow(_ name: String, desc: String, license: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(license)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    ContentView()
}
