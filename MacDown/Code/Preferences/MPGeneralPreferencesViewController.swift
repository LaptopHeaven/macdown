//
//  MPGeneralPreferencesViewController.swift
//  MacDown
//
//  Rewritten from MPGeneralPreferencesViewController.m + .xib.
//

import SwiftUI

@objcMembers
final class MPGeneralPreferencesViewController: PreferencesPaneController {

    override var viewIdentifier: String { "GeneralPreferences" }

    override var toolbarItemImage: NSImage? {
        NSImage(named: "PreferencesGeneral")
    }

    override var toolbarItemLabel: String? {
        // Same key as the nib-based pane used, so the existing translations
        // ("Allgemein" and friends) still apply.
        NSLocalizedString("General", comment: "Preference pane title.")
    }

    override func content(store: PreferencesStore) -> AnyView {
        AnyView(GeneralSettingsView(store: store))
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        // The nib-built pane bound straight to the preferences, so it picked up
        // changes made elsewhere while it was closed. A SwiftUI tree does not, so
        // nudge it once when the pane is shown.
        store.objectWillChange.send()
    }
}
