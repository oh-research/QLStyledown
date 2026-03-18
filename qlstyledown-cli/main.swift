//
//  main.swift
//  qlstyledown-cli
//
//  Created by SeminOH on 3/18/26.
//

import Foundation

// MARK: - CLI Commands

func printUsage() {
    let usage = """
    Usage: qlstyledown <command>

    Commands:
      themes     List available themes
      use <name> Switch to specified theme
      current    Show current active theme
      help       Show this help message
    """
    print(usage)
}

func listThemes() {
    let themesDir = AppGroupConstants.userThemesDirectory
    let fm = FileManager.default

    guard fm.fileExists(atPath: themesDir.path) else {
        print("No themes directory found at \(themesDir.path)")
        print("Run qlstyledown.app once to create it with default themes.")
        return
    }

    guard let files = try? fm.contentsOfDirectory(at: themesDir,
                                                   includingPropertiesForKeys: nil,
                                                   options: .skipsHiddenFiles) else {
        print("Failed to read themes directory.")
        return
    }

    let cssFiles = files.filter { $0.pathExtension == "css" }

    if cssFiles.isEmpty {
        print("No CSS themes found in \(themesDir.path)")
        return
    }

    let activeTheme = AppGroupConstants.activeThemeName

    for file in cssFiles.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
        let name = file.deletingPathExtension().lastPathComponent
        if name == activeTheme {
            print("  \(name) (active)")
        } else {
            print("  \(name)")
        }
    }
}

func useTheme(_ name: String) {
    let themesDir = AppGroupConstants.userThemesDirectory
    let cssFile = themesDir.appendingPathComponent("\(name).css")

    guard FileManager.default.fileExists(atPath: cssFile.path) else {
        print("Theme '\(name)' not found at \(cssFile.path)")
        return
    }

    guard let css = try? String(contentsOf: cssFile, encoding: .utf8) else {
        print("Failed to read theme '\(name)'.")
        return
    }

    // App Group Container에 복사
    guard let containerURL = AppGroupConstants.containerURL else {
        print("App Group Container not available.")
        print("Make sure App Groups capability is configured.")
        return
    }

    let fm = FileManager.default
    if !fm.fileExists(atPath: containerURL.path) {
        try? fm.createDirectory(at: containerURL, withIntermediateDirectories: true)
    }

    guard let targetURL = AppGroupConstants.containerCSSURL else {
        print("Failed to determine container CSS path.")
        return
    }

    do {
        try css.write(to: targetURL, atomically: true, encoding: .utf8)
    } catch {
        print("Failed to write CSS to container: \(error.localizedDescription)")
        return
    }

    // UserDefaults에 활성 테마 저장
    AppGroupConstants.sharedDefaults?.set(name, forKey: AppGroupConstants.activeThemeKey)

    print("Switched to theme '\(name)'.")
}

func showCurrentTheme() {
    let theme = AppGroupConstants.activeThemeName
    print("  \(theme)")
}

// MARK: - Main

let args = CommandLine.arguments

guard args.count >= 2 else {
    printUsage()
    exit(0)
}

let command = args[1].lowercased()

switch command {
case "themes":
    listThemes()
case "use":
    guard args.count >= 3 else {
        print("Usage: qlstyledown use <theme-name>")
        exit(1)
    }
    useTheme(args[2])
case "current":
    showCurrentTheme()
case "help", "--help", "-h":
    printUsage()
default:
    print("Unknown command: \(command)")
    printUsage()
    exit(1)
}
