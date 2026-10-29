//
//  EditorSettingsView.swift
//  MacDown
//
//  The Editor preference pane. Replaces the
//  MPEditorPreferencesViewController xib; its labels are migrated to
//  Localizable.strings under the pref.editor.* keys.
//

import SwiftUI

struct EditorSettingsView: View {
    @ObservedObject var store: PreferencesStore
    @StateObject private var fontPanel: FontPanelController

    init(store: PreferencesStore) {
        self.store = store
        _fontPanel = StateObject(wrappedValue: FontPanelController(store: store))
    }

    private var prefs: MPPreferences { store.prefs }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            labelled("pref.editor.baseFont", "Base font:",
                     "Editor option: the editor's typeface.") {
                Text(fontPanel.previewText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 240, alignment: .leading)
                Button(store.label("pref.editor.change", "Change…",
                                   comment: "Open the font panel to pick the editor font.")) {
                    fontPanel.show()
                }
            }

            labelled("pref.editor.theme", "Theme:",
                     "Editor option: syntax colour theme for the editor.") {
                Picker("", selection: themeSelection) {
                    Text("").tag("")
                    ForEach(themeNames, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
                .frame(maxWidth: 180)

                Button(store.label("pref.editor.reveal", "Reveal",
                                   comment: "Show the theme folder in the Finder.")) {
                    NSWorkspace.shared.activateFileViewerSelecting(
                        [URL(fileURLWithPath: MPDataDirectory(kMPThemesDirectoryName))])
                }
                Button(store.label("pref.editor.reload", "Reload",
                                   comment: "Re-read the themes from disk.")) {
                    reloadThemes()
                }
            }

            labelled("pref.editor.textInsets", "Text insets:",
                     "Editor option: padding around the text.") {
                NumberField(value: doubleBinding(\.editorHorizontalInset), width: 48)
                Text(store.label("pref.editor.times", "×",
                                 comment: "Separator between the two inset values."))
                    .foregroundStyle(.secondary)
                NumberField(value: doubleBinding(\.editorVerticalInset), width: 48)
            }

            labelled("pref.editor.lineSpacing", "Line spacing:",
                     "Editor option: extra space between lines.") {
                NumberField(value: doubleBinding(\.editorLineSpacing), width: 56)
            }

            HStack(spacing: 8) {
                Toggle(store.label("pref.editor.limitWidth", "Limit editor width to",
                                   comment: "Editor option: cap the editor's text width."),
                       isOn: store.binding(\.editorWidthLimited))
                NumberField(value: doubleBinding(\.editorMaximumWidth),
                            width: 56, range: 0...10000)
                    .disabled(!prefs.editorWidthLimited)
            }
            .padding(.leading, 0)

            labelled("pref.editor.listMarker", "List marker:",
                     "Editor option: bullet character for unordered lists.") {
                Picker("", selection: markerSelection) {
                    Text(store.label("pref.editor.marker.asterisk", "* (Asterisk)",
                                     comment: "Unordered list marker: asterisk."))
                        .tag(0)
                    Text(store.label("pref.editor.marker.plus", "+ (Plus sign)",
                                     comment: "Unordered list marker: plus."))
                        .tag(1)
                    Text(store.label("pref.editor.marker.minus", "- (Minus sign)",
                                     comment: "Unordered list marker: minus."))
                        .tag(2)
                }
                .labelsHidden()
                .frame(maxWidth: 180)
            }

            GroupBox(label: Text(store.label("pref.editor.behavior", "Behavior",
                                             comment: "Editor preferences section title."))) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(store.label("pref.editor.convertTabs", "Insert spaces instead of tabs",
                                       comment: "Editor option: expand tabs to spaces."),
                           isOn: store.binding(\.editorConvertTabs))

                    Toggle(store.label("pref.editor.completeMatchingCharacters",
                                       "Auto-complete matching characters",
                                       comment: "Editor option: close brackets and quotes."),
                           isOn: store.binding(\.editorCompleteMatchingCharacters))

                    Toggle(store.label("pref.editor.smartHome",
                                       "⌘← jumps to first non-whitespace character in line",
                                       comment: "Editor option: smart home key."),
                           isOn: store.binding(\.editorSmartHome))

                    Toggle(store.label("pref.editor.scrollsPastEnd", "Scroll past end",
                                       comment: "Editor option: allow scrolling past the last line."),
                           isOn: store.binding(\.editorScrollsPastEnd))

                    Toggle(store.label("pref.editor.ensuresNewlineAtEOF",
                                       "Ensure newline at end of file on save",
                                       comment: "Editor option: append a trailing newline."),
                           isOn: store.binding(\.editorEnsuresNewlineAtEndOfFile))

                    Toggle(store.label("pref.editor.autoIncrementLists",
                                       "Auto-increment numbering in ordered lists",
                                       comment: "Editor option: continue numbered lists."),
                           isOn: store.binding(\.editorAutoIncrementNumberedLists))
                        .disabled(!prefs.editorInsertPrefixInBlock)

                    Toggle(store.label("pref.editor.insertPrefixInBlock",
                                       "Automatically insert line prefix for the current block",
                                       comment: "Editor option: continue lists and quotes on Return."),
                           isOn: store.binding(\.editorInsertPrefixInBlock))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Layout helper

    private func labelled<Content: View>(
        _ key: String, _ english: String, _ comment: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 8) {
            Text(store.label(key, english, comment: comment))
                .frame(width: 96, alignment: .trailing)
            content()
        }
    }

    // MARK: - Bindings

    /// The numeric preferences are `CGFloat`; SwiftUI's fields and steppers want
    /// `Double`.
    private func doubleBinding(
        _ path: ReferenceWritableKeyPath<MPPreferences, CGFloat>
    ) -> Binding<Double> {
        Binding(
            get: { Double(prefs[keyPath: path]) },
            set: { store.set(path, to: CGFloat($0)) }
        )
    }

    private var themeNames: [String] {
        (MPListEntriesForDirectory(
            kMPThemesDirectoryName,
            MPFileNameHasExtensionProcessor(kMPThemeFileExtension)) as? [String]) ?? []
    }

    private var themeSelection: Binding<String> {
        Binding(
            get: { (prefs.editorStyleName as String?) ?? "" },
            set: { newValue in
                store.set(\.editorStyleName,
                          to: newValue.isEmpty ? nil : (newValue as NSString))
            }
        )
    }

    private var markerSelection: Binding<Int> {
        Binding(
            get: { Int(prefs.editorUnorderedListMarkerType) },
            set: { store.set(\.editorUnorderedListMarkerType, to: $0) }
        )
    }

    /// Re-read the list and ask open documents to re-apply the editor style,
    /// which is what the nib's Reload segment did.
    private func reloadThemes() {
        store.objectWillChange.send()
        NotificationCenter.default.post(
            name: .MPDidRequestEditorSetup,
            object: self,
            userInfo: [MPDidRequestEditorSetupNotificationKeyName: "editorStyleName"])
    }
}

// MARK: - Number field

private struct NumberField: View {
    @Binding var value: Double
    var width: CGFloat = 56
    var range: ClosedRange<Double> = 0...1000

    var body: some View {
        HStack(spacing: 2) {
            TextField("", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: width)
            Stepper("", value: $value, in: range).labelsHidden()
        }
    }
}

// MARK: - Font panel

/// Drives the shared `NSFontPanel`, which has no SwiftUI equivalent and is the
/// only way to offer the system font picker.
final class FontPanelController: NSObject, ObservableObject {
    private let store: PreferencesStore

    init(store: PreferencesStore) {
        self.store = store
        super.init()
    }

    /// "Family - size", the same string the nib put in its preview field.
    var previewText: String {
        let font: NSFont? = store.prefs.editorBaseFont
        guard let font = font else { return "" }
        return String(format: "%@ - %.1f", font.displayName ?? font.fontName, font.pointSize)
    }

    func show() {
        let manager = NSFontManager.shared
        manager.target = self
        manager.action = #selector(changeFont(_:))
        let font: NSFont? = store.prefs.editorBaseFont
        if let font = font {
            manager.setSelectedFont(font, isMultiple: false)
        }
        manager.fontPanel(true)?.orderFront(nil)
    }

    @objc private func changeFont(_ sender: NSFontManager) {
        guard let selected = sender.selectedFont else { return }
        store.objectWillChange.send()
        store.prefs.editorBaseFont = sender.convert(selected)
    }
}
