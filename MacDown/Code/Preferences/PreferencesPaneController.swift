//
//  PreferencesPaneController.swift
//  MacDown
//
//  Hosts a SwiftUI view inside a MASPreferences pane.
//

import SwiftUI

/// Base class for the SwiftUI preference panes.
///
/// Subclasses supply the pane's identity, a SwiftUI view, and a size.
///
/// The size matters: like the nibs before them, these views have no top-level
/// constraint to the surrounding window, so `MASPreferencesWindowController`
/// sizes the window from `controller.view.bounds` with height sizing disabled.
/// That makes this frame the pane's real size, not a hint.
///
/// The identity members are the awkward part. `MASPreferencesViewController`
/// declares them as optional, so omitting them does not fail to compile, or to
/// link, or even to launch — the window controller simply finds no pane to show
/// and the Settings window never appears.
@objcMembers
class PreferencesPaneController: MPPreferencesViewController, MASPreferencesViewController {

    /// Identifies the pane, and doubles as the user-defaults key naming the
    /// pane to reselect next time.
    var viewIdentifier: String { "" }

    var toolbarItemImage: NSImage? { nil }

    var toolbarItemLabel: String? { nil }

    /// Size the pane occupies. Subclasses override; the nibs' sizes are the guide.
    var paneSize: NSSize { NSSize(width: 400, height: 300) }

    lazy var store: PreferencesStore = PreferencesStore(preferences)

    /// The pane's content. Subclasses must override.
    func content(store: PreferencesStore) -> AnyView {
        fatalError("\(type(of: self)) must override content(store:)")
    }

    override func loadView() {
        let host = NSHostingView(rootView: content(store: store))
        host.frame = NSRect(origin: .zero, size: paneSize)
        view = host
    }
}
