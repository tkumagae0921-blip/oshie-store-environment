import Flutter
import Foundation
import StoreKit

public final class OshieStoreEnvironmentPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "jp.tipies.oshie/store-environment", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(OshieStoreEnvironmentPlugin(), channel: channel)
    }
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "current", call.arguments == nil else {
            result(FlutterMethodNotImplemented); return
        }
        #if targetEnvironment(simulator)
        result("unknown")
        #else
        let receipt = Bundle.main.appStoreReceiptURL
        let exists = receipt.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
        if #available(iOS 16.0, *) {
            Task {
                var appEnvironment: String? = nil
                // No AppTransaction.refresh, receipt refresh, purchase or restore here.
                if let verification = try? await AppTransaction.shared,
                   case .verified(let app) = verification,
                   app.bundleID == "jp.tipies.oshie" {
                    switch app.environment {
                    case .sandbox: appEnvironment = "sandbox"
                    case .production: appEnvironment = "production"
                    default: appEnvironment = "unsupported"
                    }
                }
                let hint = EnvironmentDecision.resolve(receiptName: receipt?.lastPathComponent,
                    receiptExists: exists, verifiedAppEnvironment: appEnvironment, simulator: false)
                await MainActor.run { result(hint) }
            }
        } else {
            result(EnvironmentDecision.resolve(receiptName: receipt?.lastPathComponent,
                receiptExists: exists, verifiedAppEnvironment: nil, simulator: false))
        }
        #endif
    }
}
