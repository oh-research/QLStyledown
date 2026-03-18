//
//  AppGroupConstants.swift
//  Shared
//
//  Created by SeminOH on 3/18/26.
//

import Foundation

enum AppGroupConstants {
    static let groupIdentifier = "group.com.ohresearch.qlstyledown"
    static let activeThemeKey = "activeTheme"
    static let defaultThemeName = "github"
    static let containerCSSFilename = "style.css"

    /// ~/.qlstyledown/themes/
    static var userThemesDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".qlstyledown")
            .appendingPathComponent("themes")
    }

    /// App Group Container URL
    static var containerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupIdentifier
        )
    }

    /// App Group Container 내 style.css URL
    static var containerCSSURL: URL? {
        containerURL?.appendingPathComponent(containerCSSFilename)
    }

    /// App Group UserDefaults
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: groupIdentifier)
    }

    /// 현재 활성 테마 이름
    static var activeThemeName: String {
        sharedDefaults?.string(forKey: activeThemeKey) ?? defaultThemeName
    }
}
