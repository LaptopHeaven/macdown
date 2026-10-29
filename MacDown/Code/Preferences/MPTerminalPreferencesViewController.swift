//
//  MPTerminalPreferencesViewController.swift
//  MacDown
//
//  Rewritten from MPTerminalPreferencesViewController.m + .xib.
//

import SwiftUI

@objcMembers
final class MPTerminalPreferencesViewController: PreferencesPaneController {

    override var viewIdentifier: String { "TerminalPreferences" }

    override var toolbarItemImage: NSImage? {
        NSImage(named: "PreferencesTerminal")
    }

    override var toolbarItemLabel: String? {
        NSLocalizedString("Terminal", comment: "Preference pane title.")
    }

    override func content(store: PreferencesStore) -> AnyView {
        AnyView(TerminalSettingsView(store: store))
    }
}
