import 'package:meta/meta.dart';
import 'message.dart';

abstract class TwilioEvent {
  static TwilioEvent fromData(dynamic data) {
    switch (data['event']) {
      case 'NewMessage':
        return NewMessageEvent(
          message: TwilioMessage.fromData(data['message']),
        );
      default:
        return UnknownEvent();
    }
  }
}

class NewMessageEvent extends TwilioEvent {
  final TwilioMessage message;
  NewMessageEvent({@required this.message});
}

class UnknownEvent extends TwilioEvent {}
