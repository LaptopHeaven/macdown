//
//  MPMarkdownPreferencesViewController.swift
//  MacDown
//
//  Rewritten from MPMarkdownPreferencesViewController.m + .xib.
//

import SwiftUI

@objcMembers
final class MPMarkdownPreferencesViewController: PreferencesPaneController {

    override var viewIdentifier: String { "MarkdownPreferences" }

    override var toolbarItemImage: NSImage? {
        NSImage(named: "PreferencesMarkdown")
    }

    override var toolbarItemLabel: String? {
        NSLocalizedString("Markdown", comment: "Preference pane title.")
    }

    override var paneWidth: CGFloat { 400 }

    override func content(store: PreferencesStore) -> AnyView {
        AnyView(MarkdownSettingsView(store: store))
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        store.objectWillChange.send()
    }
}
