# Security remediation loop

## Done
- [x] Prevent authored HTML and hostile filenames from injecting executable markup into preview/export; HTML-renderer regression test and full suite pass (21/21). This also resolves the duplicate low-severity title-injection finding.
- [x] Close the MathJax CDN finding as a false positive: the WebView resource delegate rewrites `MathJax.js` requests to the bundled app resource before sending; confirmed the delegate is assigned and the resource is in the built app. No code change needed.
- [x] Correct the Homebrew prefix probe. The PATH-hijack claim was false (`NSTask` rejected bare `brew` despite a fake executable in `PATH`); the actual bug was that the bare launch path never found the installed executable. The controller now uses `executableURL` from standard Homebrew prefixes; the regression test runs `brew --prefix` when installed. Full suite passes (22/22).
- [x] Exclude the MathJax listener's `_callbacks` storage from page JavaScript while retaining `invokeCallbackForKey:`; policy and callback regression checks pass (23/23 tests).
- [x] Secure the CLI's piped-stdin handoff: `mkstemp` creates an owner-only file, the path is published only after a complete write, and the app unlinks only a generated temp path after importing the text. Tests verify permissions, path restrictions, and deletion (24/24).
- [x] Upgrade vulnerable LibYAML 0.1.4 to upstream 0.2.5 with a repo-local podspec and SHA-256-pinned HTTPS source. This fixes CVE-2014-2525 (and CVE-2013-6393); front matter is parsed only when its preference is enabled, which defaults off. Long escaped-tag front-matter regression test passes; full suite is 25/25 and Release build succeeds.
- [x] Review the remaining custom-spec dependencies. Hoedown 3.0.7 and the native Objective-C `handlebars-objc` 1.4.5 have no published GitHub advisories found; JavaScript Handlebars CVEs do not apply to this implementation. `Pods/` is ignored (not committed); `Podfile.lock` tracks versions and podspec checksums. Accept the remote tag/spec trust for this personal build; revisit before distribution or if a concrete advisory appears.
- [x] Confirm sandbox/Hardened Runtime are disabled and signing is ad hoc (`get-task-allow` is true). Deferred hardening until a distribution decision, as approved; no code/signing change.
- [x] Accept plug-in loading as an intentional personal-use trust boundary: only `.plugin` bundles in the user Application Support `PlugIns` directory are loaded for the dedicated Plug-ins menu; no bundled plugins or automatic download/install path was found. The current user PlugIns directory is absent. Bundles placed there execute as the user.
- [x] Re-audit item 1: default and initialize renderer HTML-escape flags before the first parse; regression test exercises the safe default (25/25) and Release build succeeds.
- [x] Re-audit item 2: pin LibYAML to upstream fix commit `51843fe` and cap nesting at 1,000; a 1,100-level front-matter regression test rejects input safely. Full suite 26/26 and Release build pass. Pod installation now uses upstream `bootstrap`/Autotools, which are present on this personal build machine.
- [x] Re-audit item 3: after rewriting MathJax to its bundled file, allow only `file:` and `data:` WebView resources. Scheme-policy test and full suite pass (27/27), Release build succeeds, and a runtime WebView check confirmed returning `nil` prevents the HTTP request. Remote CSS imports are now blocked; the two IBM Plex styles that relied on one had their fonts embedded instead (see the item 3 follow-up below).
- [x] Re-audit item 4: for clicked links, allow `http:`, `https:`, `mailto:`, and local file URLs; ignore other schemes and remote-host `file:` URLs. Link-policy regression test and full suite pass (28/28); Release build succeeds.
- [x] Item 3 follow-up: the two IBM Plex styles no longer `@import` Google Fonts (blocked by the new resource filter). The needed faces — Sans 400/600, Sans italic 400, Mono 400/600 — are embedded in each sheet as latin-subset WOFF2 `data:` URLs (SIL OFL 1.1), so preview and export are correct offline with no font installed. Non-latin glyphs fall back to the system stack. Each sheet is now ~167 KB; the selector sets remain identical between Dracula and Alucard.
- [x] Font compliance: IBM Plex is OFL 1.1, which requires the copyright notice and license to ship with every copy. Added `LICENSE/ibm-plex.txt` and an IBM Plex acknowledgement to `Credits.rtf` in all 14 locales (that file is what the **About MacDown** panel renders); `textutil` parses it and the installed bundle was verified. Also credited Courtney Bearse (LaptopHeaven) in Contributors. Suite 28/28, Release build passes.

## In progress
- None.

## Next
- None.

## Never
- Do not modify `.serena/` (existing untracked user data).
- Do not modify `/Applications/MacDown.app` or `~/Library/Application Support/MacDown` during this code-only remediation pass.
- Do not commit to `master` or modify upstream history.
- Push only to the fork remote `origin` (`LaptopHeaven/macdown`); `upstream` (`MacDownApp/macdown`) is fetch-only.

## Heartbeat
- 2026-10-29T15:14:22Z run 2: item 4 verified (28/28 tests, Release build); re-audit queue complete; `.serena/` remains write-protected.
- 2026-10-29T15:20:00Z run 2: forked upstream to `LaptopHeaven/macdown`; `origin` now points at the fork and `arm64-native` is pushed and tracking it; `.serena/` remains untracked.
- 2026-10-29T15:31:00Z run 3: refreshed the rewritten commit hashes in `ASSESSMENT.md` and embedded the IBM Plex faces in both styles; installing and re-verifying preview rendering next.
- 2026-10-29T15:40:00Z run 3: every commit hash in `ASSESSMENT.md` now resolves (14/14). Release built and installed to `/Applications/MacDown.app` (signature verified, universal), user-level styles refreshed past the seed-once trap, and the preview was checked by hand with the Dracula sheet — headings, bold, italic, inline code and tables all render in IBM Plex with no network request.
- 2026-10-29T15:52:00Z run 3: OFL compliance and credit added; Release rebuilt, reinstalled and the About panel checked by hand. `.serena/` remains untracked.
