//
//  TerminalSettingsView.swift
//  MacDown
//
//  The Terminal preference pane. Replaces the
//  MPTerminalPreferencesViewController xib; its labels are migrated to
//  Localizable.strings under the pref.terminal.* keys.
//

import SwiftUI

struct TerminalSettingsView: View {
    @ObservedObject var store: PreferencesStore
    @StateObject private var shell = ShellUtilityController()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(store.label("pref.terminal.indicator", "●",
                                 comment: "Status dot: green when installed, red when not."))
                    .foregroundStyle(shell.isInstalled ? Self.installedColor
                                                       : Self.notInstalledColor)
                Text(shell.isInstalled
                     ? NSLocalizedString("Shell utility installed",
                                         comment: "Label stating that shell utility has been installed")
                     : store.label("pref.terminal.notInstalled",
                                   "Shell support not installed",
                                   comment: "Label stating that the shell utility is missing."))
            }

            // Pinned width: the paragraph's ideal width is otherwise unbounded,
            // and content-driven pane sizing turns that into a huge window.
            infoText
                .frame(width: 320, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Text(store.label("pref.terminal.location", "Location:",
                                 comment: "Label for the installed utility's path."))
                Text(shell.isInstalled
                     ? (shell.installedURL?.path ?? "")
                     : NSLocalizedString("<Not installed>",
                                         comment: "Displayed when shell utility is not installed"))
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Button(shell.isInstalled
                   ? NSLocalizedString("Uninstall", comment: "Uninstall shell utility button")
                   : store.label("pref.terminal.install", "Install",
                                 comment: "Install shell utility button")) {
                shell.isInstalled ? shell.uninstall() : shell.install()
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { shell.refresh() }
    }

    /// The info paragraph, with every "macdown" set in a monospaced face — what
    /// the nib's -highlightMacdownInInfo did with an attributed string.
    private var infoText: Text {
        let full = store.label(
            "pref.terminal.info",
            "By activating shell support you can use the macdown utility to open MacDown and documents from a shell.",
            comment: "Explains what the shell utility is for.")
        let command = "macdown"
        var result = Text("")
        var rest = Substring(full)
        while let found = rest.range(of: command) {
            result = result + Text(String(rest[rest.startIndex..<found.lowerBound]))
            result = result + Text(String(rest[found])).font(.system(.body, design: .monospaced))
            rest = rest[found.upperBound...]
        }
        return result + Text(String(rest))
    }

    /// Same two colours the nib used for its status dot.
    private static let installedColor = Color(red: 0.357, green: 0.659, blue: 0.192)
    private static let notInstalledColor = Color(red: 0.897, green: 0.231, blue: 0.21)
}

// MARK: - Shell utility

/// Installs the bundled `macdown` command by symlinking it into place, and
/// reports where it currently lives. Mirrors -lookForShellUtility,
/// -installShellUtility and -uninstallShellUtility.
final class ShellUtilityController: ObservableObject {
    @Published private(set) var installedURL: URL?

    var isInstalled: Bool { installedURL != nil }

    /// Look for the utility where Homebrew would put it, falling back to the
    /// fixed install path — the same search the nib's controller ran, including
    /// its async Homebrew prefix lookup.
    func refresh() {
        MPDetectHomebrewPrefixWithCompletionhandler { [weak self] output in
            let path: String
            if let output = output, !output.isEmpty {
                let prefix = output.trimmingCharacters(in: .whitespacesAndNewlines)
                path = (prefix as NSString).appendingPathComponent("bin/macdown")
            } else {
                path = MPCommandInstallationPath
            }
            self?.installedURL = FileManager.default.fileExists(atPath: path)
                ? URL(fileURLWithPath: path)
                : nil
        }
    }

    func install() {
        guard let utility = Bundle.main.sharedSupportURL?
            .appendingPathComponent("bin/macdown").path else { return }
        guard FileManager.default.fileExists(atPath: utility) else { return }
        try? FileManager.default.createSymbolicLink(atPath: MPCommandInstallationPath,
                                                    withDestinationPath: utility)
        refresh()
    }

    func uninstall() {
        guard let url = installedURL else { return }
        try? FileManager.default.removeItem(at: url)
        installedURL = nil
    }
}
