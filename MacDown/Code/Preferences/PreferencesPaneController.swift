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

    /// The pane's width. Fixed per pane, at the value its nib declared, so that a
    /// longer translation makes the pane taller rather than wider — otherwise the
    /// window resizes when the UI language changes. Height stays content-driven,
    /// so nothing is clipped.
    var paneWidth: CGFloat { 400 }

    lazy var store: PreferencesStore = PreferencesStore(preferences)

    /// The pane's content. Subclasses must override.
    func content(store: PreferencesStore) -> AnyView {
        fatalError("\(type(of: self)) must override content(store:)")
    }

    override func loadView() {
        // The width is applied in SwiftUI, not to the hosting view's frame, so
        // that `fittingSize` reports the height the content needs *at that width*
        // — including any label wrapping. Setting a narrow AppKit frame instead
        // would wrap the content without the measured height growing to match,
        // and the bottom would clip.
        let host = NSHostingView(rootView: content(store: store).frame(width: paneWidth))
        host.layoutSubtreeIfNeeded()
        host.frame = NSRect(origin: .zero, size: host.fittingSize)
        view = host
    }
}
