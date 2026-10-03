import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FakeAssetBundle(final Map<String, String> _assets)
    extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final value = _assets[key];
    if (value == null) {
      throw FlutterError('Asset not found: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = _assets[key];
    if (value == null) {
      throw FlutterError('Asset not found: $key');
    }
    return value;
  }
}
