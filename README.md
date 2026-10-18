# Oshie Store Environment 0.2.2 — local candidate

`OshieStoreEnvironmentReader.current()` is the non-interactive API for startup
and automatic foreground checks. It never invokes AppTransaction.refresh.
Its existing Dart eight-second timeout is unchanged (it does not cancel StoreKit).

`OshieStoreEnvironmentReader.refreshFromUserAction()` is only for a direct,
explicit user action. AppTransaction.refresh can display App Store authentication
UI and contact Apple. Do not call it from startup, timers, lifecycle or automatic
retry. Disable the initiating button while awaiting completion/cancellation.
There is no interactive timeout; concurrent Dart calls share one Future and
native overlapping interactive requests are rejected as unknown.

Both return only production, sandbox, unknown. On physical iOS 16+, shared is
checked once; only the explicit-user path may refresh once after shared throws
or is unverified. Verified bundle mismatch/unsupported environment is terminal
unknown, without receipt fallback. Verified matching sandbox/production is
authoritative and returned without reading the receipt. Receipt filename/existence
is fallback evidence only after unavailable/unverified AppTransaction results.
Simulator/non-iOS stays unknown. Older iOS retains receipt-only fallback.
No purchase, restore, AppStore.sync, receipt-refresh request, backend operations,
transaction payloads or identifiers are exposed. No logging is added.

The existing approved app startup continuation is unchanged by this plugin.
Only the safe-shell retry button may call the interactive API. A successful hint
may finish unresolved startup only when no backend has been assigned and no
Supabase initialization has started. Assignment and initialization remain at
most once; an initialized backend must never hot-switch. This library cannot
authenticate the provenance of a tap. Do not persist or force an environment.

Not published, tagged or pushed. Tests mock StoreKit; native app not built.

Requirements: Dart >=3.4.0 <4.0.0, iOS >=13.0, Swift5; StoreKit AppTransaction
is guarded at iOS16. This is routing evidence, never purchase/membership/credit
authority. Callers must keep unknown in a local-only shell and never select a
default production backend.

After separately approved publication, consume the repository root with a full
40-character Git revision, not a branch or tag-only reference. This local
candidate has no published Git SHA. License remains proprietary. Unit tests and
iOS SDK typechecking do not establish signed-app or TestFlight runtime behavior.
