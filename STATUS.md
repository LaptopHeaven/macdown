# Security remediation loop

## Done
- [x] Prevent authored HTML and hostile filenames from injecting executable markup into preview/export; HTML-renderer regression test and full suite pass (21/21). This also resolves the duplicate low-severity title-injection finding.
- [x] Close the MathJax CDN finding as a false positive: the WebView resource delegate rewrites `MathJax.js` requests to the bundled app resource before sending; confirmed the delegate is assigned and the resource is in the built app. No code change needed.
- [x] Correct the Homebrew prefix probe. The PATH-hijack claim was false (`NSTask` rejected bare `brew` despite a fake executable in `PATH`); the actual bug was that the bare launch path never found the installed executable. The controller now uses `executableURL` from standard Homebrew prefixes; the regression test runs `brew --prefix` when installed. Full suite passes (22/22).
- [x] Exclude the MathJax listener's `_callbacks` storage from page JavaScript while retaining `invokeCallbackForKey:`; policy and callback regression checks pass (23/23 tests).
- [x] Secure the CLI's piped-stdin handoff: `mkstemp` creates an owner-only file, the path is published only after a complete write, and the app unlinks only a generated temp path after importing the text. Tests verify permissions, path restrictions, and deletion (24/24).
- [x] Accept plug-in loading as an intentional personal-use trust boundary: only `.plugin` bundles in the user Application Support `PlugIns` directory are loaded for the dedicated Plug-ins menu; no bundled plugins or automatic download/install path was found. The current user PlugIns directory is absent. Bundles placed there execute as the user.

## In progress
- None.

## Next
- [ ] Review dependency provenance and known vulnerability status for the checked-in Pods and custom CocoaPods specs.
- [ ] Decide whether the personal build needs sandboxing or Hardened Runtime; avoid distribution hardening unless required.

## Never
- Do not modify `.serena/` (existing untracked user data).
- Do not modify `/Applications/MacDown.app` or `~/Library/Application Support/MacDown` during this code-only remediation pass.
- Do not commit to `master` or modify upstream history.

## Heartbeat
- 2026-10-29T14:02:12Z run 1 phase PREP complete; plugin loading accepted as intentional personal-use risk; no code change; ready to commit.
