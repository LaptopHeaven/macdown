# MacDown: arm64 patch vs. Swift/SwiftUI rewrite

Assessment for `macdown-ngx`. Written 2026-10-22, updated 2026-10-28.

**Verdict: patch it now, decide on a rewrite later with evidence. The two are sequential, not competing.**

> **Status: Option A is DONE and verified, plus three follow-ups (2026-10-28).** Branch `arm64-native`:
> `a073a4c` arm64 patch · `b214461` this doc · `054186c` deprecated APIs · `b071a1e` ad-hoc signing · `17873f5` Dracula style · `988ab8a` Alucard style.
> The app builds, runs natively on arm64, and has no non-WebKit deprecation warnings left. Options A+ and B remain open — see §5.3–§5.6 for what landed and §9 for what is still unknown.

---

## 1. TL;DR

| | Scope | Effort | Outcome |
|---|---|---|---|
| **A — Patch** | deployment target, toolbar bounds guard, Sparkle bump | **hours** | native arm64 MacDown, 100% feature parity |
| **A+ — Patch + modernize in place** | A, plus WKWebView, Sparkle 2, SwiftUI settings, notarization | **1–3 weeks** | maintainable stack, still 100% parity |
| **B — SwiftUI rewrite** | new app inheriting MacDown's assets | **2–4 months** (6+ for parity) | modern app, rebuilt editor/document/preview |

The arm64 fix is a weekend. A rewrite is a multi-month commitment plus permanent ownership of a codebase whose upstream has been dormant since April 2021. Build the reference implementation first — it de-risks the rewrite rather than delaying it.

---

## 2. Upstream status

| Fact | Value |
|---|---|
| Repo | `MacDownApp/macdown` |
| master HEAD | `3e2a2bf101c215c143bf00d9f857965f0ee82487` (2021-04-29) |
| Last release | `v0.8.0d71` (2020-02-21), 11,066 downloads |
| Stars / forks | 9,843 / 1,196 |
| Open issues / PRs | 528 / 51 |
| Releases since 2020 | none |
| Merges to master since 2021-04 | none |

**Conclusion:** effectively unmaintained. Any path we choose, we own the app.

Relevant open PRs, none merged:

| PR | Date | Scope | Note |
|---|---|---|---|
| #1234 | 2021-01-29 | 4 files | Sparkle 1.18→1.24, toolbar fix, universal build |
| #1352 | 2025-10-01 | 5 files | deployment target → 10.13, closed unmerged |
| #1377 | 2026-06-28 | 11 files | most complete; deployment target → 11.0, toolbar bounds guards, 14 deprecated API sites, entitlements |
| #1387 | 2026-09-21 | — | toolbar bounds-check fix (same crash as #1377) |

**Roughly 80% of the arm64 work already exists in these PRs.**

---

## 3. Environment used for verification

| | |
|---|---|
| macOS | 27.0.1 (build 26A434) |
| Xcode | 27.1 (27A9275) |
| CocoaPods | 1.16.2 |
| Ruby | 3.2.2 (arm64) |
| Arch | arm64 |

---

## 4. Verified findings

Everything below was reproduced on the machine above, from a scratch clone. Commands are in §8.

### 4.1 Build

| Step | Result |
|---|---|
| `make -C Dependency/peg-markdown-highlight` (generates `pmh_parser.c` via `greg`) | ✅ works on arm64 |
| `pod install` | ✅ all 9 pods resolve |
| Build at repo's `MACOSX_DEPLOYMENT_TARGET = 10.8` | ❌ **Xcode 27 rejects it** — "range of supported deployment target versions is 12.0 to 27.0.x" |
| Build after bumping to 12.0 (project + Podfile `post_install`) | ✅ `** BUILD SUCCEEDED **` |
| Output arch | ✅ universal — `x86_64 arm64` |

> Note: Xcode 27 requires ≥ 12.0. PR #1377 targets 11.0, which will *not* work on Xcode 27. Use 12.0.

### 4.2 Runtime — the arm64-only launch crash

| Test | Result |
|---|---|
| Launch arm64 build | ❌ **crashes at launch** |
| Crash report | `Code Type: ARM-64`, `EXC_BREAKPOINT`, `asi: {"CoreFoundation": ["size unreasonably big"]}` |
| Faulting frame | `-[__NSArrayM insertObject:atIndex:]` ← `-[MPToolbarController toolbarDefaultItemIdentifiers:]` |
| Same binary as `arch -x86_64` (Rosetta) | ✅ runs fine |

Root cause, `MacDown/Code/Application/MPToolbarController.m:136-163`:

```objc
int spaceAfterIndices[] = {};              // empty array...
if (i == spaceAfterIndices[j])             // ...indexed anyway
int flexibleSpaceAfterIndices[] = {2,3,5,7,11};
if (i == flexibleSpaceAfterIndices[k])     // k runs to 5 → one past the end
```

Out-of-bounds stack reads. Undefined behavior that happened to be benign on x86_64; fatal under the arm64 Release optimizer. **This is the single blocker between "builds" and "runs".**

### 4.3 Sparkle is x86_64-only

`Sparkle 1.18.1` is a prebuilt vendored framework. Verified with `lipo`:

| Version | Architectures |
|---|---|
| 1.18.1 (pinned by master) | `x86_64` |
| 1.24.0 | `x86_64 arm64` |
| 1.26.0 | `x86_64 arm64` |

Because there is no arm64 slice, the arm64 link **silently drops Sparkle** — confirmed: no `LC_LOAD_DYLIB` for Sparkle in the arm64 slice, while x86_64 has one.

The app still launches because Sparkle is referenced only from `MainMenu.xib` as a nib `customObject` and from a delegate method signature — a runtime dependency, not a link-time one.

**Consequence: auto-update is silently dead on arm64 until Sparkle is bumped.** Fix is the one-line change PR #1234 already made.

---

## 5. The arm64 patch (Option A)

Three changes:

1. **Deployment target → 12.0** in `MacDown.xcodeproj/project.pbxproj` (6 occurrences) and `Podfile` (`platform :osx, "12.0"`), plus a `post_install` hook so the generated Pods project matches.
2. **Bounds guards** in `MPToolbarController.m`:

```objc
 int spaceAfterIndices[] = {}; // No space in the default set
+NSUInteger spaceAfterIndicesCount = 0;
 int flexibleSpaceAfterIndices[] = {2, 3, 5, 7, 11};
+NSUInteger flexibleSpaceAfterIndicesCount =
+    sizeof(flexibleSpaceAfterIndices) / sizeof(flexibleSpaceAfterIndices[0]);
...
-        if (i == spaceAfterIndices[j])
+        if (j < spaceAfterIndicesCount && i == spaceAfterIndices[j])
...
-        if (i == flexibleSpaceAfterIndices[k])
+        if (k < flexibleSpaceAfterIndicesCount && i == flexibleSpaceAfterIndices[k])
```

3. **Sparkle `~> 1.18` → `~> 1.24`** in the `Podfile`.

Not addressed by this patch (still open):
- `WebView` → `WKWebView` (3 files). Every remaining deprecation warning is in this family — see §5.3.
- Distribution signing. Ad-hoc signing now happens (§5.4), but Gatekeeper still rejects the app; shipping it needs a Developer ID certificate and notarization.
- The editor pane still looks like 2014. The Dracula style added in §5.5 is a preview/export stylesheet only; the editor is styled by `Resources/Themes/*.style`, and no matching theme exists yet.

### 5.1 Result — applied and verified

Branch `arm64-native`, commit `a073a4c`. Deployment target set to **12.0** (not 11.0 — Xcode 27 requires ≥ 12.0). Sparkle resolved to **1.27.3**.

| Check | Result |
|---|---|
| Release build | ✅ succeeds, no errors |
| App binary | ✅ `x86_64 arm64` |
| `macdown` CLI | ✅ `x86_64 arm64` |
| Embedded `Sparkle.framework` | ✅ `x86_64 arm64` |
| Sparkle linked into arm64 slice | ✅ `@rpath/Sparkle.framework` present (was absent entirely) |
| `LC_BUILD_VERSION` minos | ✅ 12.0 |
| Runs natively | ✅ `lsappinfo` → `Arch=ARM64`; `vmmap -summary` → `Code Type: ARM64` |
| Launch crash | ✅ gone — repeated runs, no crash reports, no stderr |
| Windows open | ✅ `System Events` reports 2 windows |
| `xcodebuild test` | ✅ 20/20 pass |
| x86_64 / Rosetta path | ✅ still works |

The launch-crash fix is confirmed: the crash previously occurred in `-[MPToolbarController toolbarDefaultItemIdentifiers:]` via `openUntitledDocumentAndDisplay` → `showWindow:`, so the app demonstrably reaches that path at launch in this environment — and now completes it.

Two side effects of running `pod install` with CocoaPods 1.16.2 (reproducible; re-running leaves the file byte-identical):
- The `[CP] Embed Pods Frameworks` phase loses its two `Sparkle.framework.dSYM` paths. Cosmetic — affects only Sparkle's own crash symbolication.
- `.gitignore` gained entries for two build artifacts that were landing in the source tree: the generated `MacDown/Resources/Styles/GitHub-2020.css` and the xcodebuild plugin caches next to the `Dependency` sub-projects.

### 5.2 Newly found issue — empty `GitHub-2020.css`

`Tools/GitHub-style-generator/Makefile` runs as a build phase and writes `MacDown/Resources/Styles/GitHub-2020.css` via `node_modules/.bin/node-sass | sed > $@`. With no `node_modules`, the command fails but the shell redirect still creates a **0-byte file**, and the pipeline's exit status is `sed`'s, so the build stays green.

`MPHtmlPreferencesViewController -loadStylesheets` enumerates the Styles directory, so the app presents a blank "GitHub 2020" style entry.

**Pre-existing, not arm64-related** — a fresh clone on x86_64 behaves identically, and PR #1352 accidentally committed a 0-byte copy of this file. `Tools/build_for_release.py` never installs the node deps either. Fix options: vendor the real CSS from a released `.app`, or make the recipe fail loudly (e.g. `set -o pipefail`) so the empty file never lands.

### 5.3 Deprecated APIs — done

Every non-WebKit deprecated API was replaced: **89 deprecation warnings → 0** in the Release build. The 62 that remain are all `WebView`/`DOM`/`Web*`. Commit `054186c`.

Most were straight renames (`NSAutoPagination`, `NSFileHandlingPanelOKButton`, `NSOnState`, `NSDragPboard`, `colorUsingColorSpaceName:`, `base64Encoding`, `insertText:`, `stringByAddingPercentEscapesUsingEncoding:`). Four were real behaviour changes: save/export panels now use `allowedContentTypes` with `UTType`; file drops read `NSURL` objects via `readObjectsForClasses:`; `MPGetDataMap` uses `+unarchivedObjectOfClasses:fromData:error:`; and the CLI launches via `NSWorkspaceOpenConfiguration`.

Two things were deliberately **not** migrated:

- **`-disableFlushWindow` / `-enableFlushWindow` / `isFlushWindowDisabled`.** Apple's suggested replacement, `+[NSAnimationContext runAnimationGroup:]`, cannot express this pair — the calls straddle runloop turns (`didCommitLoad` … MathJax completion callback), so batching them would mean restructuring the preview reload path, which can't be verified without a GUI test. Behaviour is unchanged; the two call sites became one helper with the warning silenced and the reasoning recorded in the code.
- **The WebView family.** Deprecated since 10.14 but still functional. Migrating to `WKWebView` touches `MPDocument.m`'s ~200 lines of delegate code, the MathJax CDN interception, plugin JS injection, and scroll sync. Still a separate, larger change.

`MPGetDataMap` carried real risk: `data.map`/`treats.map` were archived with PyObjC's `OC_PythonString`. Tested standalone before committing — `$classhints` substitute `NSString`, and both maps decode identically under the secure API (verified with a throwaway harness, not assumed).

### 5.4 Signing — done

Ad-hoc, for the same reason the whole port was cheap. Commit `b071a1e`.

**It was not required to run locally.** The arm64 linker already ad-hoc signs the executable, which is what Apple Silicon enforces, and the app launched through LaunchServices before the change. What was missing was a *sealed bundle*: with `CODE_SIGN_IDENTITY = ""`, `codesign --verify --deep --strict` said "code object is not signed at all" and `spctl` rejected it. That only bites once the `.app` is copied or zipped.

Setting both configurations to `"-"` (Xcode's "Sign to Run Locally") fixes it — the signature now verifies. **It still does not satisfy Gatekeeper**: `spctl` will keep rejecting an ad-hoc signature, and distribution needs a Developer ID certificate plus notarization. That is a separate, opt-in step.

### 5.5 A Dracula style — added, plus its Alucard counterpart

`MacDown/Resources/Styles/Dracula (IBM Plex).css` and `Alucard (IBM Plex).css`. Commits `17873f5`, `988ab8a`.

Dracula is dark, Alucard is Dracula's official light counterpart. Both use IBM Plex Sans for prose and IBM Plex Mono for code, and both appear in the Styles menu with no project changes, because `Resources/Styles` is a folder reference. IBM Plex is fetched from Google Fonts so the preview is right without a local install, while the stack still resolves a locally installed copy offline.

Alucard is built from the official "Alucard Classic" tokens (`Background #fffbeb`, `Foreground #1f1f1f`, `Selection #cfcfde`, `Comment #6c664b`, `Cyan #036a96`, `Green #14710a`, `Orange #a34d14`, `Pink #a3144d`, `Purple #644ac9`, `Red #cb3a2a`, `Yellow #846e15`). Its "Current Line" token equals Comment, so code and table surfaces use adjacent UI tokens instead — `#ece9df` for code, `#ceccc0` for borders and raised surfaces.

They style the structures the renderer actually emits, taken from `hoedown_html_patch.c`: `<div><pre data-information="…"><code class="language-x">` blocks, `li.task-list-item`, `ul.toc`, and the standard hoedown set.

**The pair is kept structurally parallel on purpose.** Verified mechanically: 45 selectors, identical sets, identical property lists on every one. The only delta is Alucard's `--selection` variable, which is a real spec token Dracula has no equivalent for. Any drift between the two files will therefore show up in a plain diff.

They also fix a small upstream bug: `show-information.css` styles the language label with `pre[class*='language-']`, but the language class lands on the inner `<code>`, so that selector never matches and the label goes unstyled. The new sheets target `pre[data-information]` with enough specificity to win even when the extension stylesheet loads, so the info string now appears.

Contrast was checked, not assumed — and that surfaced a defect in the first Dracula cut. The code-block language badge was comment-on-current-line: **1.97:1** in Dracula, 3.58:1 in Alucard. The badge is small text, so it needs the full 4.5:1. Both sheets now use the foreground color there: **8.59:1** and **10.22:1**. Every other Alucard pair passes AA, worst case 4.80:1 (italic yellow).

Verified by rendering a sample of MacDown's emitted markup in a browser with each sheet inlined the way the app does it. The font claim was checked properly rather than taken on faith: a test string measures 533.73px in `IBM Plex Sans` against 496.69px for both a deliberately fake family and `serif`, and the face reports `loaded` — so the webfont really is applied and not silently falling back.

Both are installed: the `.app` at `/Applications` was refreshed, and the user-level copies in `~/Library/Application Support/MacDown/Styles/` were written directly. That second step is needed because seeding never overwrites an existing file (§5.7) — Alucard would have seeded itself as a new file, but the Dracula badge fix would not have reached the user copy.

### 5.6 No matching editor theme — open

The Dracula CSS only covers the preview/export pane. The **editor** (the `NSTextView`) is styled by `Resources/Themes/*.style`, and there is no Dracula theme, so a Dracula preview still sits next to a light editor. `Themes/*.style` is a small JSON file and would be a quick follow-up; the editor *font* is a separate preference and is not part of the theme.
---

### 5.7 Installed to /Applications

Replaced `/Applications/MacDown.app` (0.7.3, x86_64 only, unsigned) with this build (`0.0.1113` / build `1111.2`, universal, ad-hoc signed). Old copy backed up to:

```
~/Library/Application Support/macdown-ngx-backup/MacDown-0.7.3.app
```

Preferences carry over untouched — same bundle identifier (`com.uranusjr.macdown`).

**The trap: styles and themes do not live in the app bundle at runtime.** `MPMainController -copyFiles` seeds them from the bundle into `~/Library/Application Support/MacDown/{Styles,Themes}/` on launch, and it **only copies files that are missing** — it never overwrites. So:

- Replacing the `.app` does *not* refresh an existing style or theme.
- Editing a shipped style in the repo has no effect until the user-level copy is deleted (it re-seeds on the next launch) or overwritten directly.

This bit us already: the first launch seeded `Dracula (IBM Plex).css` before the TOC fix landed, so Application Support held a stale copy. It has been overwritten with the current version. All other user styles and themes were verified byte-identical to the 0.7.3 bundle, i.e. nothing was customised.

Two zero-byte styles sit in the user directory and show up as blank entries in the Styles menu:

| File | Origin |
|---|---|
| `GitHub-2017.css` | shipped empty by upstream 0.7.3 (Jan 2020) |
| `GitHub-2020.css` | generated empty by this build (§5.2) — re-seeds itself if deleted |

Only `GitHub-2017.css` can be removed for good, since it is no longer in the bundle. Fixing the other one means fixing the generator, not deleting the file.

Rebuild-and-reinstall, for reference:

```bash
xcodebuild -workspace MacDown.xcworkspace -scheme MacDown \
  -configuration Release -derivedDataPath ./build build
osascript -e 'quit app "MacDown"'
ditto build/Build/Products/Release/MacDown.app /Applications/MacDown.app
```

---

## 6. Rewrite assessment (Option B)

### 6.1 Codebase size

| Subsystem | Lines | Does SwiftUI help? |
|---|---|---|
| `MPDocument.m` — doc model, encoding, autosave, print, export, webview glue | 2,017 | ❌ NSDocument semantics |
| `MPRenderer.m` + `hoedown_html_patch` — markdown→HTML | 704 | ❌ C + WebView |
| `NSTextView+Autocomplete.m` — list continuation, tab, wrap/toggle, headers | 730 | ❌ NSTextView |
| App shell / toolbar / plugin controller | 826 | ✅ mostly |
| Preferences (7 panes) | 1,108 | ✅ best fit |
| Extensions + utilities | 1,577 | ⚠️ mechanical |
| `peg-markdown-highlight` (C, generated parser) | ~8,600 | ❌ |
| Assets: 26 styles/themes, Prism, MathJax, Mermaid/Viz, templates | ~2,900 lines + 9 MB | ✅ port unchanged |
| Localization | 26 languages, 211 `.strings` files, 12,013 lines | ⚠️ mechanical, then review |

Totals: **6,804 lines `.m`, 806 lines `.h`, 30 `.m` files, 0 Swift, 8 `.xib`.**

The ObjC is small. The language migration is the easy part; SwiftUI shrinks the shell, which is the smallest piece. A "SwiftUI app" still ends up ~70% AppKit wrapped in `NSViewRepresentable`.

### 6.2 What SwiftUI does not solve

1. **The editor.** SwiftUI still has no markdown source editor. Apple's WWDC26 TextKit session states it directly: *"If you have a SwiftUI app, use a ViewRepresentable to include these text views."* `TextEditor` gained `AttributedString` editing in macOS 26, but that is rich text, not a markdown source editor with custom highlighting.
   - Off-the-shelf options now exist: `STTextView` (TextKit 2, SwiftUI wrappers), `swift-markdown-engine`, `swift-markdown-view`. All young and largely single-vendor — a head start, not a foundation.
2. **The preview.** hoedown (C) → HTML → WebView, plus Prism, MathJax, Mermaid, Graphviz and a JS hook. In SwiftUI this is `WKWebView` + `NSViewRepresentable`. Cheapest path: keep hoedown behind a bridging header (~50 lines of glue, byte-identical output).
3. **Document semantics.** Autosave-in-place, encoding detection, versions, print with pagination, export accessory panel, Open Recent, file-conflict handling. `DocumentGroup` is thin; most of this is hand-written either way.

### 6.3 Effort

| Work | Estimate |
|---|---|
| SwiftUI shell: settings scene, Commands/menus, toolbar, document scene | 1–2 weeks |
| Editor | **0** if adopting a TextKit 2 package · 4–6 weeks if written from scratch |
| Preview + renderer bridge (keeping hoedown) | 1–2 weeks |
| Preview via cmark-gfm instead (output parity rework) | +4–6 weeks |
| Document model: autosave, encoding, print, export | 3–4 weeks |
| Plugin system (ObjC bundles + JS hooks) | 1–2 weeks — or drop |
| Localization import into String Catalogs | ~1 week + translator review |
| AppleScript (`MacDown.sdef`, 205 lines) | ~1 week — usually dropped |
| Signing, notarization, Sparkle 2, updates | ~3 days |

**~2–4 months for a credible clone; 6+ months for parity.**

### 6.4 What a rewrite quietly costs

- **Localization.** 12,013 lines across 26 languages. A rewrite ships English-only unless real work is done. "It lost my language" is a regression no TextKit 2 upgrade fixes.
- **The plugin system and AppleScript.** Small, but they are why some users are still on MacDown instead of a newer editor.
- **Permanent ownership.** Upstream is dead, so a fork means owning the whole app forever. That is a larger decision than Swift vs. ObjC and should be made deliberately.

---

## 7. Recommendation

1. ~~**This weekend:** apply the §5 patch, build, sign ad-hoc, confirm a clean window launch on arm64.~~ **Done — see §5.1.** Next: decide on signing for distribution.
2. **Use it for a month** as a daily driver. Record what actually annoys you.
3. **Then decide B with evidence:** which features are actually used? Is the *editor feel* the problem, or the shell? Does iOS matter? A month of real use answers these; a design doc does not.
4. **If going SwiftUI:** fork as a new app that imports MacDown's assets (styles, themes, Prism, MathJax, hoedown extensions), keeps hoedown behind a bridging header, adopts a TextKit 2 editor package, and ships English + our languages first. Chase "better than MacDown for me", not parity.

**A+ (patch + modernize in place) is likely the best long-term answer.** ObjC and Swift coexist in the same target with zero interop cost, so WKWebView, Sparkle 2, and a SwiftUI settings scene can be adopted without rebuilding the document model, the dialect, or the localizations.

**The one decision that drives the rewrite schedule is hoedown vs. cmark-gfm — not SwiftUI.** Decide that before writing any Swift.

---

## 8. Reproduction

The patch is applied on branch `arm64-native` (commit `a073a4c`) in this repo. Clean-build reproduction:

```bash
git clone https://github.com/MacDownApp/macdown.git && cd macdown
git submodule update --init

# generate the PEG parser (works fine on arm64)
make -C Dependency/peg-markdown-highlight

# system CocoaPods 1.16.2 is fine; bundler/Gemfile.lock is stale for Ruby 3.2
pod install

# apply the three changes from §5, then:
pod install
xcodebuild -workspace MacDown.xcworkspace -scheme MacDown -configuration Release \
  -derivedDataPath ./build build CODE_SIGNING_ALLOWED=NO

# arch checks
lipo -archs build/Build/Products/Release/MacDown.app/Contents/MacOS/MacDown
#   -> x86_64 arm64
lipo -archs build/Build/Products/Release/MacDown.app/Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle
#   -> x86_64 arm64        (x86_64 only on Sparkle 1.18.1)
otool -arch arm64 -L build/Build/Products/Release/MacDown.app/Contents/MacOS/MacDown | grep -i sparkle
#   -> @rpath/Sparkle.framework/...   (absent before the Sparkle bump)

# confirm it runs natively rather than under Rosetta
./build/Build/Products/Release/MacDown.app/Contents/MacOS/MacDown &
vmmap -summary <pid> | grep "Code Type"     # -> ARM64
lsappinfo info -app MacDown | grep Arch     # -> Arch=ARM64
osascript -e 'tell application "System Events" to tell process "MacDown" to return count of windows'

# tests
xcodebuild -workspace MacDown.xcworkspace -scheme MacDown -configuration Debug \
  -derivedDataPath ./build test CODE_SIGNING_ALLOWED=NO
```

To reproduce the original crash, build at the untouched `master` revision and launch — the `.ips` files land in `~/Library/Logs/DiagnosticReports/MacDown-*.ips` with `Code Type: ARM-64`, `EXC_BREAKPOINT`, and `asi: {"CoreFoundation": ["size unreasonably big"]}`.

> Note: `vmmap` lists `/usr/lib/libRosetta.dylib` in **every** process on macOS 27, so it is not a translation indicator. Use `Code Type` or `lsappinfo`'s `Arch=` instead.

---

## 9. Open questions

- [x] ~~Does a clean window launch after the toolbar guard?~~ **Yes — verified, §5.1.**
- [x] ~~Deprecated APIs~~ **Done — §5.3.**
- [x] ~~Do we need ad-hoc signing locally?~~ **No — but the bundle is now sealed anyway, §5.4.**
- [ ] Does auto-update actually work with Sparkle 1.27.3 on arm64? (unverified: the framework now links and loads, but the update flow was never exercised)
- [ ] `SUUpdater` in `MainMenu.xib` — now resolves on arm64 since Sparkle links. Confirm the delegate wiring fires.
- [ ] Ship the real `GitHub-2020.css`, or drop the style (§5.2)
- [ ] Sign/notarize for distribution, or keep this a local build? (§5.4: ad-hoc now, but Gatekeeper still rejects)
- [ ] Add matching **editor themes** for the Dracula/Alucard preview styles, or leave the editor light (§5.6)
- [ ] `WebView` → `WKWebView` (§5.3) — the last deprecation, and a real project
- [ ] Verify the modernised behaviours by hand: file drops into the editor, the save/export panels' file-type restrictions, and the CLI's launch path (§5.3)
- [ ] Which features do we actually use? (drives the rewrite decision)
- [ ] hoedown vs. cmark-gfm — the real rewrite schedule driver
- [ ] Is iOS/iPadOS a goal? (a strong argument for B)
- [ ] Do we accept losing plugins/AppleScript/localization coverage in a rewrite?

---

## 10. Evidence gaps

- Sparkle's update flow was not exercised end-to-end — that needs a signed build and a live appcast.
- The editor and preview were not manually exercised. Verification covered launch, window creation, arch, and the unit tests (20/20), not editing or rendering behaviour.
- The Dracula stylesheet was verified by rendering a **reconstruction** of MacDown's markup in Chromium, built from the exact strings in `hoedown_html_patch.c` — not from the app's own renderer output. The structure should match, but it is not app-verified.
- The four behaviour-changing deprecation fixes (file drops, save/export `UTType` filters, `NSWorkspaceOpenConfiguration` launch) compile and the app runs, but each specific interaction was not driven by hand.
- `MPGetDataMap`'s secure unarchive **was** verified empirically against both bundled maps, with a throwaway harness rather than assumed.
- `macdown-cmd` builds universal, but its runtime behaviour was not exercised: it writes file paths and piped content into MacDown's real user defaults, so running it would have side effects on the host.
- TextKit 2 editor packages were assessed from their documentation, not hands-on.
- Localization effort is estimated as "mechanical" only; it assumes the existing translations are accepted as-is.
