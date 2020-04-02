import 'dart:async';
import 'package:meta/meta.dart';

import 'package:flutter/services.dart';

class FlutterTwilioChat {
  static const MethodChannel _methodChannel =
      const MethodChannel('flutter_twilio_chat');

  static Future<String> get platformVersion async {
    final String version =
        await _methodChannel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> initialize(
      {@required String token, String region}) async {
    await _methodChannel.invokeMethod('initialize', {
      'token': token,
      'region': region,
    });
  }

  Future<void> sendSimpleMessage({
    @required String channelId,
    @required String messageText,
  }) async {
    try {
      await _methodChannel.invokeMethod('sendSimpleMessage', {
        'channelId': channelId,
        'messageText': messageText,
      });
    } catch (err) {
      print('Error: $err');
    }
  }
}
