//
//  MarkdownSettingsView.swift
//  MacDown
//
//  The Markdown preference pane. Replaces the
//  MPMarkdownPreferencesViewController xib; its labels are migrated to
//  Localizable.strings under the pref.markdown.* keys.
//

import SwiftUI

struct MarkdownSettingsView: View {
    @ObservedObject var store: PreferencesStore

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                GroupBox(label: Text(store.label(
                    "pref.markdown.documentFormatting", "Document formatting",
                    comment: "Markdown preferences section: whole-document options."))) {
                    option("pref.markdown.smartypants", "Smartypants",
                           "Markdown option: SmartyPants typographic punctuation.",
                           \.extensionSmartyPants)
                }

                GroupBox(label: Text(store.label(
                    "pref.markdown.blockFormatting", "Block formatting",
                    comment: "Markdown preferences section: block-level syntax."))) {
                    VStack(alignment: .leading, spacing: 6) {
                        option("pref.markdown.table", "Table",
                               "Markdown option: table syntax.",
                               \.extensionTables)
                        option("pref.markdown.fencedCode", "Fenced code block",
                               "Markdown option: ``` fenced code blocks.",
                               \.extensionFencedCode)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)
            }

            GroupBox(label: Text(store.label(
                "pref.markdown.inlineFormatting", "Inline formatting",
                comment: "Markdown preferences section: inline syntax."))) {
                VStack(alignment: .leading, spacing: 6) {
                    option("pref.markdown.intraWordEmphasis", "Intra-word emphasis",
                           "Markdown option: emphasis inside a word.",
                           \.extensionIntraEmphasis)
                    option("pref.markdown.strikethrough", "Strikethrough",
                           "Markdown option: strikethrough.",
                           \.extensionStrikethough)
                    option("pref.markdown.underline", "Underline",
                           "Markdown option: underline.",
                           \.extensionUnderline)
                    option("pref.markdown.quote", "Quote",
                           "Markdown option: quote syntax.",
                           \.extensionQuote)
                    option("pref.markdown.highlight", "Highlight",
                           "Markdown option: highlight syntax.",
                           \.extensionHighlight)
                    option("pref.markdown.superscript", "Superscript",
                           "Markdown option: superscript.",
                           \.extensionSuperscript)
                    option("pref.markdown.autolink", "Autolink",
                           "Markdown option: automatic links.",
                           \.extensionAutolink)
                    option("pref.markdown.footnote", "Footnote",
                           "Markdown option: footnotes.",
                           \.extensionFootnotes)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func option(_ key: String, _ english: String, _ comment: String,
                        _ path: ReferenceWritableKeyPath<MPPreferences, Bool>) -> some View {
        Toggle(store.label(key, english, comment: comment), isOn: store.binding(path))
    }
}
