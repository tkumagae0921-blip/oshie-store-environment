import Foundation

// No billing authority, receipt content or URL leaves this plugin.
enum EnvironmentDecision {
    static func resolve(receiptName: String?, receiptExists: Bool,
                        verifiedAppEnvironment: String?, simulator: Bool) -> String {
        if simulator { return "unknown" }
        if let verified = verifiedAppEnvironment, !["sandbox", "production"].contains(verified) { return "unknown" }
        let receipt: String? = receiptExists
            ? (receiptName == "sandboxReceipt" ? "sandbox" : receiptName == "receipt" ? "production" : nil)
            : nil
        let app = ["sandbox", "production"].contains(verifiedAppEnvironment ?? "") ? verifiedAppEnvironment : nil
        if let receipt = receipt, let app = app, receipt != app { return "unknown" }
        return receipt ?? app ?? "unknown"
    }
}
