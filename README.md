# oshie_store_environment 0.2.0

A Flutter iOS plugin returning `production`, `sandbox`, or `unknown` for Oshie.
This is a routing hint, never purchase, membership, or credit authority.
No backend URLs, API keys, credentials, account data, purchase/restore operations,
or receipt contents are included or returned.

## Requirements
Flutter / Dart >=3.4.0 <4.0.0; iOS >=13.0; Swift 5. AppTransaction is guarded
at iOS 16.0. Bundle identity check is `jp.tipies.oshie`.
Verified AppTransaction environment and an existing receipt-location signal are
cross-checked. Conflicts, simulator, verified Xcode/unsupported environments,
unavailable signals, missing plugin, platform failure or an 8-second timeout
return unknown. Missing receipt/auth/network never implies production.
No receipt refresh, AppTransaction refresh, purchase, restore, or sign-in is invoked.

```dart
final hint = await OshieStoreEnvironmentReader.current();
```

The caller must keep unknown in a local-only shell. Never initialize a default
production backend. Choose only a baked manifest after resolution; no hot switch.

## Git consumption (fill only after approved publication)
```yaml
oshie_store_environment:
  git:
    url: <future-public-repo>
    ref: <full-40-character-commit-sha>
```
Do not use branches or tag-only references. This candidate has no published Git SHA.
The review package records its tree SHA256 separately. Use repository root as the
package root; no enclosing workspace, client package, evidence or test data.

## Validation
`flutter test test/environment_channel_test.dart` tests channel behavior without
StoreKit. `ios/Tests/environment_tests.swift` plus `EnvironmentDecision.swift`
can be compiled as a standalone macOS Swift test executable. Plugin sources are
also iOS SDK typechecked by the enclosing review package. These are not a signed
IPA or TestFlight proof. License is proprietary; publishing is a separate approval.
