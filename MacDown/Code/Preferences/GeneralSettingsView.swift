//
//  GeneralSettingsView.swift
//  MacDown
//
//  The General preference pane. Replaces the MPGeneralPreferencesViewController
//  xib; the pane labels it used to carry are migrated to Localizable.strings
//  under the pref.general.* keys.
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var store: PreferencesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GroupBox(label: Text(store.label(
                "pref.general.behavior", "Behavior",
                comment: "Preferences section title."))) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(store.label(
                        "pref.general.ensureOpenDocumentOnLaunch",
                        "Ensure open document on launch",
                        comment: "Preferences option: open a document window at launch."),
                        isOn: store.negated(\.supressesUntitledDocumentOnLaunch))

                    Toggle(store.label(
                        "pref.general.automaticPreview",
                        "Update preview automatically as you type",
                        comment: "Preferences option: live preview while typing."),
                        isOn: automaticPreview)

                    Toggle(store.label(
                        "pref.general.syncScroll",
                        "Sync preview scrollbar when editor scrolls",
                        comment: "Preferences option: keep the preview scrolled with the editor."),
                        isOn: store.binding(\.editorSyncScrolling))

                    Toggle(store.label(
                        "pref.general.editorOnRight", "Put editor on the right",
                        comment: "Preferences option: place the editor to the right of the preview."),
                        isOn: store.binding(\.editorOnRight))

                    Toggle(store.label(
                        "pref.general.showWordCount", "Show word count",
                        comment: "Preferences option: show a word count in the editor."),
                        isOn: store.binding(\.editorShowWordCount))
                        .disabled(store.prefs.markdownManualRender)

                    Toggle(store.label(
                        "pref.general.createFileForLinkTarget",
                        "Automatically create files for link targets",
                        comment: "Preferences option: create files when a link target is opened."),
                        isOn: store.binding(\.createFileForLinkTarget))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// "Update preview automatically" is the negation of `markdownManualRender`,
    /// which the original nib expressed with an `NSNegateBoolean` value
    /// transformer.
    private var automaticPreview: Binding<Bool> {
        Binding(
            get: { !store.prefs.markdownManualRender },
            set: { isOn in
                store.set(\.markdownManualRender, to: !isOn)
                if !isOn {
                    // Preserves -updateWordCounterVisibility:, which cleared the
                    // word count whenever automatic preview was switched off.
                    store.set(\.editorShowWordCount, to: false)
                }
            }
        )
    }
}
