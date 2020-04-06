import 'dart:async';
import 'package:meta/meta.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import 'channel.dart';
export 'channel.dart';

class FlutterTwilioChat {
  static const MethodChannel _methodChannel =
      const MethodChannel('flutter_twilio_chat');
  static const EventChannel _eventChannel =
      const EventChannel('flutter_twilio_chat_events');

  static FlutterTwilioChat _instance;
  static get instance {
    if (_instance == null) _instance = FlutterTwilioChat();
    return _instance;
  }

  final StreamController<Map> controller = BehaviorSubject<Map>();
  FlutterTwilioChat() {
    _eventChannel.receiveBroadcastStream().cast<Map>().pipe(this.controller);
  }

  Future<List<TwilioChannel>> initialize(
      {@required String token, String region}) async {
    final Map result = await _methodChannel.invokeMethod('initialize', {
      'token': token,
      'region': region,
    });
    return result['channels']
        .map<TwilioChannel>(TwilioChannel.fromData)
        .toList();
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

  Future<void> markAsRead({
    @required String channelId,
  }) async {
    try {
      await _methodChannel.invokeMethod('markAsRead', {
        'channelId': channelId,
      });
    } catch (err) {
      print('Error: $err');
    }
  }
}

class TwilioEvent {}
