//
//  MPEditorPreferencesViewController.swift
//  MacDown
//
//  Rewritten from MPEditorPreferencesViewController.m + .xib.
//

import SwiftUI

@objcMembers
final class MPEditorPreferencesViewController: PreferencesPaneController {

    override var viewIdentifier: String { "EditorPreferences" }

    override var toolbarItemImage: NSImage? {
        NSImage(named: "PreferencesEditor")
    }

    override var toolbarItemLabel: String? {
        NSLocalizedString("Editor", comment: "Preference pane title.")
    }

    override func content(store: PreferencesStore) -> AnyView {
        AnyView(EditorSettingsView(store: store))
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        // The nib refreshed the font preview and re-read the theme list every
        // time the pane appeared.
        store.objectWillChange.send()
    }
}
