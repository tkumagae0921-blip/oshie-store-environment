## 0.2.2 (local candidate; unpublished)

- Make verified, bundle-matching sandbox/production AppTransaction authoritative.
- Do not read receipt evidence after any verified result; mismatch/unsupported remains unknown.
- Use receipt fallback only for unavailable/unverified transaction evidence.
- Preserve passive current(), explicit-only refresh, concurrency fences and public APIs.
- Do not change app startup continuation or introduce billing authority.

## 0.2.1

- Add explicit-user `refreshFromUserAction()` with shared-first, single refresh fallback.
- Preserve passive `current()` and its Dart eight-second timeout.
- Terminal unknown for verified bundle mismatch; retain conflict fail-closed.
- Coalesce Dart interactive calls and fence native concurrent interactive requests.

## 0.2.0
- Reject verified Xcode/unsupported environment even when receipt filename looks production.
- Prepare standalone Git distribution; retain bounded, fail-closed detection.

## 0.1.0
- Initial reviewed StoreKit/AppTransaction and receipt hint candidate.
