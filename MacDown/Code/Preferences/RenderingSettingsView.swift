//
//  RenderingSettingsView.swift
//  MacDown
//
//  The Rendering preference pane. Replaces the
//  MPHtmlPreferencesViewController xib; its labels are migrated to
//  Localizable.strings under the pref.rendering.* keys.
//

import SwiftUI

struct RenderingSettingsView: View {
    @ObservedObject var store: PreferencesStore

    private var prefs: MPPreferences { store.prefs }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            labelled("pref.rendering.css", "CSS:",
                     "Rendering option: which stylesheet the preview uses.") {
                Picker("", selection: styleSelection) {
                    Text("").tag("")
                    ForEach(styleNames, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
                .frame(maxWidth: 180)

                Button(store.label("pref.rendering.reveal", "Reveal",
                                   comment: "Show the stylesheet folder in the Finder.")) {
                    reveal(MPDataDirectory(kMPStylesDirectoryName))
                }
                Button(store.label("pref.rendering.reload", "Reload",
                                   comment: "Re-read the stylesheets from disk.")) {
                    reloadStyles()
                }
            }

            labelled("pref.rendering.defaultPath", "Default path:",
                     "Rendering option: base directory for relative links.") {
                PathControl(url: defaultDirectory).frame(height: 22)
            }

            Toggle(store.label("pref.rendering.syntaxHighlighting",
                               "Syntax highlighted code block",
                               comment: "Rendering option: highlight code blocks with Prism."),
                   isOn: store.binding(\.htmlSyntaxHighlighting))

            labelled("pref.rendering.theme", "Theme:",
                     "Rendering option: Prism colour theme.") {
                Picker("", selection: highlightingThemeSelection) {
                    Text(prismDefaultThemeName).tag(prismDefaultThemeName)
                    ForEach(highlightingThemeNames, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
                .frame(maxWidth: 180)
                .disabled(!prefs.htmlSyntaxHighlighting)
            }

            Toggle(store.label("pref.rendering.lineNumbers", "Show line numbers",
                               comment: "Rendering option: number the lines of code blocks."),
                   isOn: store.binding(\.htmlLineNumbers))
                .disabled(!prefs.htmlSyntaxHighlighting)

            Toggle(store.label("pref.rendering.graphviz", "Graphviz",
                               comment: "Rendering option: render Graphviz diagrams."),
                   isOn: store.binding(\.htmlGraphviz))
                .disabled(!prefs.htmlSyntaxHighlighting)

            Toggle(store.label("pref.rendering.mermaid", "Mermaid",
                               comment: "Rendering option: render Mermaid diagrams."),
                   isOn: store.binding(\.htmlMermaid))
                .disabled(!prefs.htmlSyntaxHighlighting)

            Toggle(store.label("pref.rendering.mathJax", "TeX-like math syntax",
                               comment: "Rendering option: render TeX maths with MathJax."),
                   isOn: store.binding(\.htmlMathJax))

            Text(store.label("pref.rendering.mathJaxNote",
                             "Math support requires Internet connection.",
                             comment: "Note under the maths option."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 20)

            Toggle(store.label("pref.rendering.mathJaxInlineDollar",
                               "Use dollar sign ($) as inline delimiter",
                               comment: "Rendering option: allow $…$ for inline maths."),
                   isOn: store.binding(\.htmlMathJaxInlineDollar))
                .disabled(!prefs.htmlMathJax)

            Toggle(store.label("pref.rendering.taskList", "Task list syntax",
                               comment: "Rendering option: render - [ ] task lists."),
                   isOn: store.binding(\.htmlTaskList))

            Toggle(store.label("pref.rendering.frontMatter", "Detect Jekyll front-matter",
                               comment: "Rendering option: hide Jekyll front-matter."),
                   isOn: store.binding(\.htmlDetectFrontMatter))

            Toggle(store.label("pref.rendering.toc", "Detect table of contents token",
                               comment: "Rendering option: expand a [TOC] token."),
                   isOn: store.binding(\.htmlRendersTOC))

            Toggle(store.label("pref.rendering.hardWrap", "Render newline literally",
                               comment: "Rendering option: treat newlines as hard breaks."),
                   isOn: store.binding(\.htmlHardWrap))

            Toggle(store.label("pref.rendering.zoom", "Scale preview based on editor font size",
                               comment: "Rendering option: scale the preview with the editor font."),
                   isOn: store.binding(\.previewZoomRelativeToBaseFontSize))

            labelled("pref.rendering.accessory", "Accessory:",
                     "Rendering option: what to show in the corner of code blocks.") {
                Picker("", selection: accessorySelection) {
                    Text(store.label("pref.rendering.accessory.none", "None",
                                     comment: "Code block accessory: nothing."))
                        .tag(Int(MPCodeBlockAccessoryType.none.rawValue))
                    Text(store.label("pref.rendering.accessory.languageName", "Language name",
                                     comment: "Code block accessory: the language."))
                        .tag(Int(MPCodeBlockAccessoryType.languageName.rawValue))
                    Text(store.label("pref.rendering.accessory.custom", "Custom",
                                     comment: "Code block accessory: the info string."))
                        .tag(Int(MPCodeBlockAccessoryType.custom.rawValue))
                }
                .labelsHidden()
                .frame(maxWidth: 180)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Layout helper

    /// A right-aligned label and its control, matching the nib's 83pt label column.
    private func labelled<Content: View>(
        _ key: String, _ english: String, _ comment: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 8) {
            Text(store.label(key, english, comment: comment))
                .frame(width: 84, alignment: .trailing)
            content()
        }
    }

    // MARK: - Stylesheets

    /// Names of the stylesheets on disk, as the nib populated its popup: the
    /// first (empty) item means "no stylesheet".
    private var styleNames: [String] {
        (MPListEntriesForDirectory(
            kMPStylesDirectoryName,
            MPFileNameHasExtensionProcessor(kMPStyleFileExtension)) as? [String]) ?? []
    }

    private var styleSelection: Binding<String> {
        Binding(
            get: { self.styleName },
            set: { newValue in
                store.set(\.htmlStyleName, to: newValue.isEmpty ? nil : (newValue as NSString))
            }
        )
    }

    /// MPPreferences declares its object properties `assign`, so Swift imports
    /// them as `NSString` rather than `String`. Convert at the boundary.
    private var styleName: String { (prefs.htmlStyleName as String?) ?? "" }

    private var defaultDirectory: Binding<URL?> {
        Binding(
            get: { prefs.htmlDefaultDirectoryUrl as URL? },
            set: { store.set(\.htmlDefaultDirectoryUrl, to: $0 as NSURL?) }
        )
    }

    private func reveal(_ directory: String) {
        NSWorkspace.shared.activateFileViewerSelecting(
            [URL(fileURLWithPath: directory)])
    }

    /// Re-read the list from disk and ask open documents to re-render, which is
    /// what the nib's Reload segment did.
    private func reloadStyles() {
        store.objectWillChange.send()
        NotificationCenter.default.post(name: .MPDidRequestPreviewRender, object: self)
    }

    // MARK: - Prism themes

    private var prismDefaultThemeName: String {
        // Kept as the literal key rather than a pref.rendering.* one: this string
        // was already an NSLocalizedString in the ObjC pane, so its translations
        // ("(Standard)", "(デフォルト)") are in place.
        NSLocalizedString("(Default)", comment: "Prism theme title")
    }

    /// Prism theme files are named `prism-<name>.css`; the nib stripped the
    /// `prism-` prefix and the `.css` suffix and capitalised the rest.
    private var highlightingThemeNames: [String] {
        let urls = Bundle.main.urls(forResourcesWithExtension: "css",
                                    subdirectory: "Prism/themes") ?? []
        return urls.compactMap { url in
            let name = url.lastPathComponent
            guard name.count > 10 else { return nil }
            let start = name.index(name.startIndex, offsetBy: 6)
            let end = name.index(name.endIndex, offsetBy: -4)
            return String(name[start..<end]).capitalized
        }
    }

    private var highlightingThemeSelection: Binding<String> {
        Binding(
            get: {
                let name = (self.prefs.htmlHighlightingThemeName as String?) ?? ""
                return name.isEmpty ? self.prismDefaultThemeName : name
            },
            set: { newValue in
                let stored: NSString? = (newValue == self.prismDefaultThemeName)
                    ? "" : (newValue as NSString)
                self.store.set(\.htmlHighlightingThemeName, to: stored)
            }
        )
    }

    // MARK: - Code block accessory

    private var accessorySelection: Binding<Int> {
        Binding(
            get: { Int(prefs.htmlCodeBlockAccessory) },
            set: { store.set(\.htmlCodeBlockAccessory, to: $0) }
        )
    }
}

// MARK: - Default path control

/// `NSPathControl` has no SwiftUI equivalent, and it is a genuinely useful
/// control here — you can drag a folder onto it and pick from the recent-places
/// menu — so it is wrapped rather than degraded to a plain folder button.
private struct PathControl: NSViewRepresentable {
    @Binding var url: URL?

    func makeNSView(context: Context) -> NSPathControl {
        let control = NSPathControl()
        control.pathStyle = .standard
        control.target = context.coordinator
        control.action = #selector(Coordinator.pathChanged(_:))
        control.url = url
        return control
    }

    func updateNSView(_ control: NSPathControl, context: Context) {
        context.coordinator.parent = self
        if control.url != url {
            control.url = url
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject {
        var parent: PathControl

        init(_ parent: PathControl) { self.parent = parent }

        @objc func pathChanged(_ sender: NSPathControl) {
            parent.url = sender.url
        }
    }
}
