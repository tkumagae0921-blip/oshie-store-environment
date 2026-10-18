import Foundation

struct Scenario {
    let name: String
    let interactive: Bool
    let shared: AppTransactionEvidence
    let refresh: AppTransactionEvidence
    let receipt: String?
    let expected: String
    let sharedCount: Int
    let refreshCount: Int
    let receiptCount: Int
    var simulator = false
    var supported = true
}
actor Probe {
    var sharedCount = 0
    var refreshCount = 0
    func shared(_ value: AppTransactionEvidence) -> AppTransactionEvidence { sharedCount += 1; return value }
    func refresh(_ value: AppTransactionEvidence) -> AppTransactionEvidence { refreshCount += 1; return value }
    func counts() -> (Int, Int) { (sharedCount, refreshCount) }
}
final class ReceiptProbe {
    var count = 0
    let name: String?
    init(_ name: String?) { self.name = name }
    func read() -> (name: String?, exists: Bool) { count += 1; return (name, name != nil) }
}
actor SuspendedRefresh {
    private var entered = false
    private var enteredWaiter: CheckedContinuation<Void, Never>?
    private var completion: CheckedContinuation<AppTransactionEvidence, Never>?
    func call() async -> AppTransactionEvidence {
        entered = true
        enteredWaiter?.resume(); enteredWaiter = nil
        return await withCheckedContinuation { completion = $0 }
    }
    func waitUntilEntered() async {
        if entered { return }
        await withCheckedContinuation { enteredWaiter = $0 }
    }
    func finish() { completion?.resume(returning: .unavailable); completion = nil }
}
@main struct ExplicitRefreshTests {
    static func main() async throws {
        func v(_ environment: String, _ matches: Bool = true) -> AppTransactionEvidence {
            .verified(environment: environment, bundleMatches: matches)
        }
        var cases: [Scenario] = [
            Scenario(name: "current_shared_sandbox", interactive: false, shared: v("sandbox"), refresh: v("production"), receipt: nil, expected: "sandbox", sharedCount: 1, refreshCount: 0, receiptCount: 0),
            Scenario(name: "current_shared_production", interactive: false, shared: v("production"), refresh: v("sandbox"), receipt: nil, expected: "production", sharedCount: 1, refreshCount: 0, receiptCount: 0),
            Scenario(name: "current_bundle_mismatch_receipt_blocked", interactive: false, shared: v("sandbox", false), refresh: v("sandbox"), receipt: "receipt", expected: "unknown", sharedCount: 1, refreshCount: 0, receiptCount: 0),
            Scenario(name: "current_unavailable_sandbox_receipt", interactive: false, shared: .unavailable, refresh: v("production"), receipt: "sandboxReceipt", expected: "sandbox", sharedCount: 1, refreshCount: 0, receiptCount: 1),
            Scenario(name: "current_unavailable_production_receipt", interactive: false, shared: .unavailable, refresh: v("sandbox"), receipt: "receipt", expected: "production", sharedCount: 1, refreshCount: 0, receiptCount: 1),
            Scenario(name: "current_unavailable_no_receipt", interactive: false, shared: .unavailable, refresh: v("production"), receipt: nil, expected: "unknown", sharedCount: 1, refreshCount: 0, receiptCount: 1),
            Scenario(name: "current_unverified_receipt", interactive: false, shared: .unverified, refresh: v("production"), receipt: "sandboxReceipt", expected: "sandbox", sharedCount: 1, refreshCount: 0, receiptCount: 1),
            Scenario(name: "current_simulator", interactive: false, shared: v("production"), refresh: v("production"), receipt: "receipt", expected: "unknown", sharedCount: 0, refreshCount: 0, receiptCount: 0, simulator: true),
            Scenario(name: "interactive_shared_sandbox", interactive: true, shared: v("sandbox"), refresh: v("production"), receipt: nil, expected: "sandbox", sharedCount: 1, refreshCount: 0, receiptCount: 0),
            Scenario(name: "interactive_shared_production", interactive: true, shared: v("production"), refresh: v("sandbox"), receipt: nil, expected: "production", sharedCount: 1, refreshCount: 0, receiptCount: 0),
            Scenario(name: "interactive_shared_bundle_mismatch", interactive: true, shared: v("production", false), refresh: v("sandbox"), receipt: "receipt", expected: "unknown", sharedCount: 1, refreshCount: 0, receiptCount: 0),
            Scenario(name: "shared_unavailable_refresh_sandbox", interactive: true, shared: .unavailable, refresh: v("sandbox"), receipt: nil, expected: "sandbox", sharedCount: 1, refreshCount: 1, receiptCount: 0),
            Scenario(name: "shared_unverified_refresh_sandbox", interactive: true, shared: .unverified, refresh: v("sandbox"), receipt: nil, expected: "sandbox", sharedCount: 1, refreshCount: 1, receiptCount: 0),
            Scenario(name: "shared_unavailable_refresh_production", interactive: true, shared: .unavailable, refresh: v("production"), receipt: nil, expected: "production", sharedCount: 1, refreshCount: 1, receiptCount: 0),
            Scenario(name: "refresh_bundle_mismatch_receipt_blocked", interactive: true, shared: .unavailable, refresh: v("sandbox", false), receipt: "sandboxReceipt", expected: "unknown", sharedCount: 1, refreshCount: 1, receiptCount: 0),
            Scenario(name: "refresh_unverified_no_receipt", interactive: true, shared: .unavailable, refresh: .unverified, receipt: nil, expected: "unknown", sharedCount: 1, refreshCount: 1, receiptCount: 1),
            Scenario(name: "refresh_unavailable_no_receipt", interactive: true, shared: .unavailable, refresh: .unavailable, receipt: nil, expected: "unknown", sharedCount: 1, refreshCount: 1, receiptCount: 1),
            Scenario(name: "refresh_unavailable_sandbox_receipt", interactive: true, shared: .unavailable, refresh: .unavailable, receipt: "sandboxReceipt", expected: "sandbox", sharedCount: 1, refreshCount: 1, receiptCount: 1),
            Scenario(name: "refresh_unavailable_production_receipt", interactive: true, shared: .unavailable, refresh: .unavailable, receipt: "receipt", expected: "production", sharedCount: 1, refreshCount: 1, receiptCount: 1),
            Scenario(name: "shared_sandbox_conflict", interactive: true, shared: v("sandbox"), refresh: v("sandbox"), receipt: "receipt", expected: "sandbox", sharedCount: 1, refreshCount: 0, receiptCount: 0),
            Scenario(name: "shared_production_conflict", interactive: true, shared: v("production"), refresh: v("production"), receipt: "sandboxReceipt", expected: "production", sharedCount: 1, refreshCount: 0, receiptCount: 0),
            Scenario(name: "refresh_sandbox_conflict", interactive: true, shared: .unavailable, refresh: v("sandbox"), receipt: "receipt", expected: "sandbox", sharedCount: 1, refreshCount: 1, receiptCount: 0),
            Scenario(name: "refresh_production_conflict", interactive: true, shared: .unavailable, refresh: v("production"), receipt: "sandboxReceipt", expected: "production", sharedCount: 1, refreshCount: 1, receiptCount: 0),
            Scenario(name: "verified_agrees_receipt", interactive: true, shared: .unavailable, refresh: v("sandbox"), receipt: "sandboxReceipt", expected: "sandbox", sharedCount: 1, refreshCount: 1, receiptCount: 0),
            Scenario(name: "shared_unsupported_terminal", interactive: true, shared: v("unknown"), refresh: v("sandbox"), receipt: "receipt", expected: "unknown", sharedCount: 1, refreshCount: 0, receiptCount: 0),
            Scenario(name: "refresh_unsupported_terminal", interactive: true, shared: .unavailable, refresh: v("unknown"), receipt: "receipt", expected: "unknown", sharedCount: 1, refreshCount: 1, receiptCount: 0),
            Scenario(name: "interactive_simulator", interactive: true, shared: v("sandbox"), refresh: v("sandbox"), receipt: "sandboxReceipt", expected: "unknown", sharedCount: 0, refreshCount: 0, receiptCount: 0, simulator: true),
            Scenario(name: "older_ios_receipt_only", interactive: true, shared: v("production"), refresh: v("production"), receipt: "sandboxReceipt", expected: "sandbox", sharedCount: 0, refreshCount: 0, receiptCount: 1, supported: false)
        ]
        // Cross-product verifies that verified paths do not invoke receipt(),
        // even when its evidence disagrees or is absent/unrecognized.
        for path in ["current", "interactive_shared", "interactive_refresh"] {
            for receiptName in [nil, "sandboxReceipt", "receipt", "other"] as [String?] {
                for environment in ["sandbox", "production", "xcode", "unknown", "unsupported"] {
                    for matches in [true, false] {
                        let refreshed = path == "interactive_refresh"
                        let expected = matches && ["sandbox", "production"].contains(environment) ? environment : "unknown"
                        cases.append(Scenario(name: "authority_" + path + "_" + environment + "_" + String(matches) + "_" + (receiptName ?? "absent"),
                            interactive: path != "current", shared: refreshed ? .unavailable : v(environment, matches),
                            refresh: v(environment, matches), receipt: receiptName, expected: expected,
                            sharedCount: 1, refreshCount: refreshed ? 1 : 0, receiptCount: 0))
                    }
                }
            }
        }
        // Fallback is still allowed only when verified evidence is unavailable.
        for interactive in [false, true] {
            for receiptName in [nil, "sandboxReceipt", "receipt", "other"] as [String?] {
                for unverified in [false, true] {
                    let missing: AppTransactionEvidence = unverified ? .unverified : .unavailable
                    let expected = receiptName == "sandboxReceipt" ? "sandbox" : receiptName == "receipt" ? "production" : "unknown"
                    cases.append(Scenario(name: "fallback_" + String(interactive) + "_" + String(unverified) + "_" + (receiptName ?? "absent"),
                        interactive: interactive, shared: missing, refresh: missing, receipt: receiptName, expected: expected,
                        sharedCount: 1, refreshCount: interactive ? 1 : 0, receiptCount: 1))
                }
            }
        }
        var rows: [[String: Any]] = []
        for c in cases {
            let probe = Probe(); let receipt = ReceiptProbe(c.receipt)
            let actual = await EnvironmentReader().read(interactive: c.interactive,
                simulator: c.simulator, supportsAppTransaction: c.supported,
                shared: { await probe.shared(c.shared) }, refresh: { await probe.refresh(c.refresh) }, receipt: receipt.read)
            let counts = await probe.counts()
            precondition(actual == c.expected && counts.0 == c.sharedCount && counts.1 == c.refreshCount && receipt.count == c.receiptCount, c.name)
            rows.append(["case": c.name, "result": actual, "shared_count": counts.0,
                         "refresh_count": counts.1, "receipt_reads": receipt.count, "pass": true])
        }
        for receiptName in [nil, "sandboxReceipt", "receipt"] as [String?] {
            let probe = Probe()
            let actual = await EnvironmentReader().read(interactive: true, simulator: false, supportsAppTransaction: true,
                shared: { _ = await probe.shared(.unavailable); throw CancellationError() },
                refresh: { _ = await probe.refresh(.unavailable); throw CancellationError() },
                receipt: { (receiptName, receiptName != nil) })
            let counts = await probe.counts()
            let expected = receiptName == "sandboxReceipt" ? "sandbox" : receiptName == "receipt" ? "production" : "unknown"
            precondition(actual == expected && counts.0 == 1 && counts.1 == 1)
            rows.append(["case": "shared_throw_refresh_cancel_" + expected, "result": actual,
                         "shared_count": counts.0, "refresh_count": counts.1, "pass": true])
        }
        let reader = EnvironmentReader(); let probe = Probe(); let pending = SuspendedRefresh()
        let first = Task { await reader.read(interactive: true, simulator: false, supportsAppTransaction: true,
            shared: { await probe.shared(.unavailable) },
            refresh: { _ = await probe.refresh(.unavailable); return await pending.call() }, receipt: { (nil, false) }) }
        await pending.waitUntilEntered()
        let duplicate = await reader.read(interactive: true, simulator: false, supportsAppTransaction: true,
            shared: { await probe.shared(.unavailable) }, refresh: { await probe.refresh(.unavailable) }, receipt: { (nil, false) })
        precondition(duplicate == "unknown")
        var counts = await probe.counts(); precondition(counts.0 == 1 && counts.1 == 1)
        await pending.finish()
        let completed = await first.value; precondition(completed == "unknown")
        rows.append(["case": "native_double_tap_while_refresh_pending", "shared_count": counts.0, "refresh_count": counts.1, "pass": true])
        let laterTap = await reader.read(interactive: true, simulator: false, supportsAppTransaction: true,
            shared: { await probe.shared(.verified(environment: "sandbox", bundleMatches: true)) },
            refresh: { await probe.refresh(.unavailable) }, receipt: { (nil, false) })
        counts = await probe.counts()
        precondition(laterTap == "sandbox" && counts.0 == 2 && counts.1 == 1)
        rows.append(["case": "native_fence_released_after_completion", "pass": true])
        let slowReader = EnvironmentReader(); let slowProbe = Probe(); let slowShared = SuspendedRefresh()
        let slowFirst = Task { await slowReader.read(interactive: true, simulator: false, supportsAppTransaction: true,
            shared: { _ = await slowProbe.shared(.unavailable); return await slowShared.call() },
            refresh: { await slowProbe.refresh(.verified(environment: "sandbox", bundleMatches: true)) }, receipt: { (nil, false) }) }
        await slowShared.waitUntilEntered()
        let slowDuplicate = await slowReader.read(interactive: true, simulator: false, supportsAppTransaction: true,
            shared: { await slowProbe.shared(.unavailable) }, refresh: { await slowProbe.refresh(.unavailable) }, receipt: { (nil, false) })
        precondition(slowDuplicate == "unknown")
        let beforeRelease = await slowProbe.counts(); precondition(beforeRelease.0 == 1 && beforeRelease.1 == 0)
        await slowShared.finish()
        let slowResult = await slowFirst.value; let afterRelease = await slowProbe.counts()
        precondition(slowResult == "sandbox" && afterRelease.0 == 1 && afterRelease.1 == 1)
        rows.append(["case": "native_double_tap_while_shared_pending", "shared_count": afterRelease.0, "refresh_count": afterRelease.1, "pass": true])
        let data = try JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
        print(String(decoding: data, as: UTF8.self))
    }
}
