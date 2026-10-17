import Flutter
import Foundation
import StoreKit

public final class OshieStoreEnvironmentPlugin: NSObject, FlutterPlugin {
    private static let reader = EnvironmentReader()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "jp.tipies.oshie/store-environment", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(OshieStoreEnvironmentPlugin(), channel: channel)
    }
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard ["current", "refreshFromUserAction"].contains(call.method), call.arguments == nil else {
            result(FlutterMethodNotImplemented); return
        }
        #if targetEnvironment(simulator)
        result("unknown")
        #else
        let interactive = call.method == "refreshFromUserAction"
        Task {
            let supported: Bool
            if #available(iOS 16.0, *) { supported = true } else { supported = false }
            let hint = await Self.reader.read(interactive: interactive, simulator: false,
                supportsAppTransaction: supported,
                shared: {
                    if #available(iOS 16.0, *) {
                        return Self.evidence(try await AppTransaction.shared)
                    }
                    return .unavailable
                },
                refresh: {
                    // Reached only by the explicit-user method after an unusable
                    // shared result. No timer, retry, or lifecycle entry point.
                    if #available(iOS 16.0, *) {
                        return Self.evidence(try await AppTransaction.refresh())
                    }
                    return .unavailable
                }, receipt: Self.receiptEvidence)
            await MainActor.run { result(hint) }
        }
        #endif
    }

    @available(iOS 16.0, *)
    private static func evidence(_ verification: VerificationResult<AppTransaction>) -> AppTransactionEvidence {
        guard case .verified(let app) = verification else { return .unverified }
        let environment: String
        switch app.environment {
        case .sandbox: environment = "sandbox"
        case .production: environment = "production"
        default: environment = "unknown"
        }
        return .verified(environment: environment, bundleMatches: app.bundleID == "jp.tipies.oshie")
    }

    private static func receiptEvidence() -> (name: String?, exists: Bool) {
        let receipt = Bundle.main.appStoreReceiptURL
        return (receipt?.lastPathComponent,
                receipt.map { FileManager.default.fileExists(atPath: $0.path) } ?? false)
    }
}
