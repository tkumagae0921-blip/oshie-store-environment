import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum OshieStoreEnvironment { production, sandbox, unknown }

/// Routing hint only. Each backend independently fixes and verifies grant scope.
class OshieStoreEnvironmentReader {
  static const _channel = MethodChannel('jp.tipies.oshie/store-environment');

  static Future<OshieStoreEnvironment> current() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return OshieStoreEnvironment.unknown;
    }
    try {
      final value = await _channel.invokeMethod<String>('current').timeout(const Duration(seconds: 8));
      return switch (value) {
        'production' => OshieStoreEnvironment.production,
        'sandbox' => OshieStoreEnvironment.sandbox,
        _ => OshieStoreEnvironment.unknown,
      };
    } on TimeoutException {
      return OshieStoreEnvironment.unknown;
    } on PlatformException {
      return OshieStoreEnvironment.unknown;
    } on MissingPluginException {
      return OshieStoreEnvironment.unknown;
    }
  }

  static Future<OshieStoreEnvironment>? _interactiveRequest;

  /// Only call directly in response to an explicit user tap, never from startup
  /// or lifecycle callbacks. StoreKit may show App Store authentication UI.
  /// No timeout: await StoreKit completion/cancellation. Concurrent taps share
  /// one request. The caller must disable its button until this future completes.
  /// This returns evidence only; it must not hot-switch an initialized backend.
  static Future<OshieStoreEnvironment> refreshFromUserAction() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return Future.value(OshieStoreEnvironment.unknown);
    }
    return _interactiveRequest ??= _refreshFromUserAction().whenComplete(() {
      _interactiveRequest = null;
    });
  }

  static Future<OshieStoreEnvironment> _refreshFromUserAction() async {
    try {
      final value = await _channel.invokeMethod<String>('refreshFromUserAction');
      return switch (value) {
        'production' => OshieStoreEnvironment.production,
        'sandbox' => OshieStoreEnvironment.sandbox,
        _ => OshieStoreEnvironment.unknown,
      };
    } on PlatformException {
      return OshieStoreEnvironment.unknown;
    } on MissingPluginException {
      return OshieStoreEnvironment.unknown;
    }
  }
}
