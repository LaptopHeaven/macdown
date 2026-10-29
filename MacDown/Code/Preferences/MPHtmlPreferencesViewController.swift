//
//  MPHtmlPreferencesViewController.swift
//  MacDown
//
//  Rewritten from MPHtmlPreferencesViewController.m + .xib. The pane is titled
//  "Rendering" but the class keeps its historic name.
//

import SwiftUI

@objcMembers
final class MPHtmlPreferencesViewController: PreferencesPaneController {

    override var viewIdentifier: String { "HtmlPreferences" }

    override var toolbarItemImage: NSImage? {
        NSImage(named: "PreferencesRendering")
    }

    override var toolbarItemLabel: String? {
        NSLocalizedString("Rendering", comment: "Preference pane title.")
    }

    override func content(store: PreferencesStore) -> AnyView {
        AnyView(RenderingSettingsView(store: store))
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        // The nib re-read the stylesheet and Prism theme lists every time the
        // pane appeared, so a file added while it was closed shows up.
        store.objectWillChange.send()
    }
}
