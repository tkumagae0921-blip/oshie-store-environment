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
}
