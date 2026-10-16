import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshie_store_environment/oshie_store_environment.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 const channel=MethodChannel('jp.tipies.oshie/store-environment');
 setUp((){debugDefaultTargetPlatformOverride=TargetPlatform.iOS;});
 tearDown((){debugDefaultTargetPlatformOverride=null;TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel,null);});
 for(final value in ['production','sandbox','unknown','xcode']){
  test('channel $value',()async{
   TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel,(c)async{expect(c.method,'current');expect(c.arguments,null);return value;});
   expect(await OshieStoreEnvironmentReader.current(),switch(value){'production'=>OshieStoreEnvironment.production,'sandbox'=>OshieStoreEnvironment.sandbox,_=>OshieStoreEnvironment.unknown});
  });
 }
 test('no App Store auth / channel error remains unknown',()async{
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel,(_)async=>throw PlatformException(code:'no_auth'));
  expect(await OshieStoreEnvironmentReader.current(),OshieStoreEnvironment.unknown);
 });
 testWidgets('offline timeout remains unknown', (t)async{
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel,(_)async{await Future<void>.delayed(const Duration(seconds:20));return 'production';});
  final pending=OshieStoreEnvironmentReader.current();await t.pump(const Duration(seconds:9));
  expect(await pending,OshieStoreEnvironment.unknown);await t.pump(const Duration(seconds:12));debugDefaultTargetPlatformOverride=null;
 });
}
