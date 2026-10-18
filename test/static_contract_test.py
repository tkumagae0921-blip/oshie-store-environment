"""Local-only source contract checks. No Flutter, Apple or backend API calls."""
import pathlib, re, json, sys
root = pathlib.Path(__file__).resolve().parents[1]
native = (root / 'ios/Classes/OshieStoreEnvironmentPlugin.swift').read_text()
resolver = (root / 'ios/Classes/EnvironmentDecision.swift').read_text()
dart = (root / 'lib/oshie_store_environment.dart').read_text()
code = '\n'.join([native, resolver, dart])
checks = {}
for name in ['AppStore.sync', 'SKReceiptRefreshRequest', '.purchase(', 'restorePurchases(', 'restoreCompletedTransactions(']:
    checks['forbidden_' + name] = name not in code
checks['single_native_refresh_callsite'] = native.count('AppTransaction.refresh()') == 1
checks['single_native_shared_callsite'] = native.count('await AppTransaction.shared') == 1
checks['only_two_null_argument_methods'] = '["current", "refreshFromUserAction"].contains(call.method), call.arguments == nil' in native
checks['eight_second_timeout_only_once'] = dart.count('.timeout(') == 1 and '.timeout(const Duration(seconds: 8))' in dart
checks['interactive_coalesced'] = 'return _interactiveRequest ??=' in dart
checks['native_interactive_fence'] = 'guard !interactiveInFlight else { return "unknown" }' in resolver
checks['no_runtime_logging'] = not re.search(r'\b(print|debugPrint|NSLog|os_log|Logger)\s*\(', code)
checks['no_network_client'] = not re.search(r'URLSession|URLRequest|HttpClient|Supabase|RevenueCat', code)
checks['single_receipt_fallback_read'] = resolver.count('let evidence = receipt()') == 1
checks['verified_helper_cannot_consult_receipt'] = 'private func verified(_ environment: String, matches: Bool) -> String' in resolver and 'return verified(environment, matches: matches, receipt:' not in resolver
checks['no_verified_receipt_conflict_downgrade'] = 'receipt != app' not in resolver
checks['verified_early_authority'] = 'return ["sandbox", "production"].contains(verified) ? verified : "unknown"' in resolver
checks['version'] = 'version: 0.2.2' in (root/'pubspec.yaml').read_text() and "s.version = '0.2.2'" in (root/'ios/oshie_store_environment.podspec').read_text()
checks['no_timer_loop'] = not re.search(r'\b(while|Timer)\s*\(', code)
checks['simulator_early_return'] = '#if targetEnvironment(simulator)\n        result("unknown")' in native
if len(sys.argv) > 1:
    baseline = pathlib.Path(sys.argv[1])
    def current(s):
        start = s.index('  static Future<OshieStoreEnvironment> current()')
        opened = s.index('{', start); depth = 0
        for i in range(opened, len(s)):
            if s[i] == '{': depth += 1
            elif s[i] == '}':
                depth -= 1
                if depth == 0: return s[start:i+1]
    checks['current_dart_byte_exact'] = current(dart) == current((baseline/'lib/oshie_store_environment.dart').read_text())
print(json.dumps({'checks': checks, 'count': len(checks), 'pass': all(checks.values())}, indent=2))
assert all(checks.values())
