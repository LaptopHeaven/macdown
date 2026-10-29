//
//  PreferencesStore.swift
//  MacDown
//
//  Bridges MPPreferences into SwiftUI for the preference panes.
//

import SwiftUI

/// Read/write access to `MPPreferences` from SwiftUI.
///
/// Values go through `MPPreferences` rather than `@AppStorage`, even though
/// PAPreferences stores them in `NSUserDefaults` under the property name as the
/// key. Routing through the object keeps the app's existing KVO and
/// notification-driven refresh paths byte-for-byte what they were when these
/// panes were nib-driven; `@AppStorage` would write the same defaults without
/// anyone listening.
final class PreferencesStore: ObservableObject {

    let prefs: MPPreferences

    private var changeObserver: NSObjectProtocol?

    init(_ prefs: MPPreferences) {
        self.prefs = prefs

        // PAPreferences posts this from every generated setter, and only for real
        // preference writes. NSUserDefaultsDidChangeNotification would also fire
        // for window frames and split-view state, which is a lot of pointless
        // SwiftUI invalidation. Without this, a preference written from outside
        // the pane — MPDocument clears editorStyleName when a theme goes missing —
        // would leave an open pane showing a stale value.
        changeObserver = NotificationCenter.default.addObserver(
            forName: .PAPreferencesDidChange,
            object: prefs,
            queue: .main
        ) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    deinit {
        if let changeObserver = changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }
    }

    /// Two-way binding to an `MPPreferences` property.
    ///
    /// `objectWillChange` is sent by hand: `MPPreferences` is a plain ObjC
    /// object, so SwiftUI has no other signal that a displayed value moved.
    func binding<T>(_ keyPath: ReferenceWritableKeyPath<MPPreferences, T>) -> Binding<T> {
        Binding(
            get: { self.prefs[keyPath: keyPath] },
            set: { newValue in
                self.objectWillChange.send()
                self.prefs[keyPath: keyPath] = newValue
            }
        )
    }

    /// Binding to the negation of a `BOOL` property, for the two preferences
    /// the original nibs bound through `NSNegateBoolean`.
    func negated(_ keyPath: ReferenceWritableKeyPath<MPPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { !self.prefs[keyPath: keyPath] },
            set: { newValue in
                self.objectWillChange.send()
                self.prefs[keyPath: keyPath] = !newValue
            }
        )
    }

    /// Writes a value and notifies SwiftUI. For the handful of preferences whose
    /// change has a side effect, or which are not driven by a `Toggle`.
    func set<T>(_ keyPath: ReferenceWritableKeyPath<MPPreferences, T>, to value: T) {
        objectWillChange.send()
        prefs[keyPath: keyPath] = value
    }

    /// Convenience for the pane labels.
    ///
    /// Keys are namespaced (`pref.<pane>.<name>`) with the English text as the
    /// fallback, rather than using the English text as the key. Bare English keys
    /// collide across contexts: the German for the Markdown pane's "Highlight"
    /// checkbox is "Markierung", but the toolbar button of the same name is
    /// "Markiert", and one shared key would have silently picked the wrong one.
    func label(_ key: String, _ english: String, comment: String = "") -> String {
        NSLocalizedString(key, tableName: nil, bundle: .main,
                          value: english, comment: comment)
    }
}
