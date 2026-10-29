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
- [x] Re-audit item 3: after rewriting MathJax to its bundled file, allow only `file:` and `data:` WebView resources. Scheme-policy test and full suite pass (27/27), Release build succeeds, and a runtime WebView check confirmed returning `nil` prevents the HTTP request. Remote CSS imports (including Google Fonts in bundled themes) are now blocked; local IBM Plex fonts are installed, but the visual fallback was not rechecked.

## In progress
- [ ] Re-audit item 4: allow only http/https/mailto for non-file link clicks; preserve local file links.

## Next
- None.

## Never
- Do not modify `.serena/` (existing untracked user data).
- Do not modify `/Applications/MacDown.app` or `~/Library/Application Support/MacDown` during this code-only remediation pass.
- Do not commit to `master` or modify upstream history.

## Heartbeat
- 2026-10-29T15:11:39Z run 2: item 3 verified (27/27 tests, Release build, runtime cancellation confirmed) and ready to commit; item 4 now in progress; `.serena/` remains write-protected.
