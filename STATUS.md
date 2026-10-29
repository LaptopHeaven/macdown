# Security remediation loop

## Done
- [x] Prevent authored HTML and hostile filenames from injecting executable markup into preview/export; HTML-renderer regression test and full suite pass (21/21). This also resolves the duplicate low-severity title-injection finding.
- [x] Close the MathJax CDN finding as a false positive: the WebView resource delegate rewrites `MathJax.js` requests to the bundled app resource before sending; confirmed the delegate is assigned and the resource is in the built app. No code change needed.
- [x] Correct the Homebrew prefix probe. The PATH-hijack claim was false (`NSTask` rejected bare `brew` despite a fake executable in `PATH`); the actual bug was that the bare launch path never found the installed executable. The controller now uses `executableURL` from standard Homebrew prefixes; the regression test runs `brew --prefix` when installed. Full suite passes (22/22).
- [x] Exclude the MathJax listener's `_callbacks` storage from page JavaScript while retaining `invokeCallbackForKey:`; policy and callback regression checks pass (23/23 tests).

## In progress
- None.

## Next
- [ ] Secure and clean up the CLI's piped-stdin temporary file.
- [ ] Review plug-in code loading as an intentional trust boundary; record whether any change is warranted.
- [ ] Review dependency provenance and known vulnerability status for the checked-in Pods and custom CocoaPods specs.
- [ ] Decide whether the personal build needs sandboxing or Hardened Runtime; avoid distribution hardening unless required.

## Never
- Do not modify `.serena/` (existing untracked user data).
- Do not modify `/Applications/MacDown.app` or `~/Library/Application Support/MacDown` during this code-only remediation pass.
- Do not commit to `master` or modify upstream history.

## Heartbeat
- 2026-10-29T13:49:39Z run 1 phase PREP complete; MathJax bridge storage excluded; callback and full suite 23/23 verified; ready to commit.
