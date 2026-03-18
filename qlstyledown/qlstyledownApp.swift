//
//  qlstyledownApp.swift
//  qlstyledown
//
//  Created by SeminOH on 3/18/26.
//

import SwiftUI

@main
struct qlstyledownApp: App {
    init() {
        SetupManager.installDefaultThemes()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - 최초 실행 시 기본 테마 설치

enum SetupManager {
    static func installDefaultThemes() {
        let fm = FileManager.default
        let themesDir = AppGroupConstants.userThemesDirectory

        // ~/.qlstyledown/themes/ 디렉토리 생성
        if !fm.fileExists(atPath: themesDir.path) {
            try? fm.createDirectory(at: themesDir, withIntermediateDirectories: true)
        }

        // 번들에서 기본 테마 복사 (이미 있으면 덮어쓰지 않음)
        let bundle = Bundle.main
        let themeFiles = ["default", "minimal"]

        for theme in themeFiles {
            let destName = theme == "default" ? "github" : theme
            let destURL = themesDir.appendingPathComponent("\(destName).css")

            if !fm.fileExists(atPath: destURL.path) {
                if let srcURL = bundle.url(forResource: theme, withExtension: "css") {
                    try? fm.copyItem(at: srcURL, to: destURL)
                }
            }
        }

        // App Group Container에 기본 CSS 설정 (없는 경우)
        if let containerURL = AppGroupConstants.containerURL {
            if !fm.fileExists(atPath: containerURL.path) {
                try? fm.createDirectory(at: containerURL, withIntermediateDirectories: true)
            }

            if let containerCSS = AppGroupConstants.containerCSSURL,
               !fm.fileExists(atPath: containerCSS.path) {
                // github.css를 기본으로 복사
                let githubCSS = themesDir.appendingPathComponent("github.css")
                if fm.fileExists(atPath: githubCSS.path) {
                    try? fm.copyItem(at: githubCSS, to: containerCSS)
                }
            }
        }
    }
}
