import 'package:meta/meta.dart';
import 'message.dart';
import 'channel.dart';

abstract class TwilioEvent {
  static TwilioEvent fromData(dynamic data) {
    switch (data['event']) {
      case 'NewMessage':
        return NewMessageEvent(
          message: TwilioMessage.fromData(data['message']),
        );
      case 'ChannelJoined':
        return ChannelJoinedEvent(
          channel: TwilioChannel.fromData(data['channel']),
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

class ChannelJoinedEvent extends TwilioEvent {
  final TwilioChannel channel;
  ChannelJoinedEvent({@required this.channel});
}

class UnknownEvent extends TwilioEvent {}