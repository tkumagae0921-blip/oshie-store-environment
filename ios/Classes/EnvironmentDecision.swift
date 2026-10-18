import Foundation

// No billing authority, receipt content or URL leaves this plugin.
enum EnvironmentDecision {
    static func resolve(receiptName: String?, receiptExists: Bool,
                        verifiedAppEnvironment: String?, simulator: Bool) -> String {
        if simulator { return "unknown" }
        // Verified StoreKit evidence is authoritative; receipt is fallback only.
        if let verified = verifiedAppEnvironment {
            return ["sandbox", "production"].contains(verified) ? verified : "unknown"
        }
        let receipt: String? = receiptExists
            ? (receiptName == "sandboxReceipt" ? "sandbox" : receiptName == "receipt" ? "production" : nil)
            : nil
        return receipt ?? "unknown"
    }
}

// Evidence stays native: only a bundle match bit and fixed environment are retained.
enum AppTransactionEvidence {
    case verified(environment: String, bundleMatches: Bool)
    case unverified
    case unavailable
}

// Actor reentrancy is fenced across StoreKit awaits. Duplicate interactive calls
// return unknown; they never start a second authentication request.
actor EnvironmentReader {
    private var interactiveInFlight = false

    func read(interactive: Bool, simulator: Bool, supportsAppTransaction: Bool,
              shared: () async throws -> AppTransactionEvidence,
              refresh: () async throws -> AppTransactionEvidence,
              receipt: () -> (name: String?, exists: Bool)) async -> String {
        if simulator { return "unknown" }
        if interactive {
            guard !interactiveInFlight else { return "unknown" }
            interactiveInFlight = true
        }
        defer { if interactive { interactiveInFlight = false } }

        if supportsAppTransaction {
            let initial = await readEvidence(shared)
            switch initial {
            case .verified(let environment, let matches):
                return verified(environment, matches: matches)
            case .unverified, .unavailable:
                if interactive {
                    let refreshed = await readEvidence(refresh)
                    switch refreshed {
                    case .verified(let environment, let matches):
                        return verified(environment, matches: matches)
                    case .unverified, .unavailable:
                        break
                    }
                }
            }
        }
        let evidence = receipt()
        return EnvironmentDecision.resolve(receiptName: evidence.name,
            receiptExists: evidence.exists, verifiedAppEnvironment: nil, simulator: false)
    }

    private func readEvidence(_ operation: () async throws -> AppTransactionEvidence) async -> AppTransactionEvidence {
        do { return try await operation() }
        catch { return .unavailable }
    }

    private func verified(_ environment: String, matches: Bool) -> String {
        // A verified mismatch or unsupported environment is terminal, including
        // when a recognizable receipt exists. Never refresh or fall back here.
        guard matches, ["sandbox", "production"].contains(environment) else { return "unknown" }
        // Do not even read a receipt when a verified transaction was returned.
        return environment
    }
}
