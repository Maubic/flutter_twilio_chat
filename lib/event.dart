import 'package:meta/meta.dart';
import 'message.dart';
import 'channel.dart';

abstract class TwilioEvent {
  static TwilioEvent fromData(dynamic data) {
    switch (data['event']) {
      case 'NewMessage':
        return NewMessageEvent(
          message: TwilioMessage.fromData(data['message']),
          channel: TwilioChannel.fromData(data['channel']),
        );
      case 'ChannelJoined':
        return ChannelJoinedEvent(
          channel: TwilioChannel.fromData(data['channel']),
        );
      case 'ChannelUpdated':
        return ChannelUpdatedEvent(
          channel: TwilioChannel.fromData(data['channel']),
        );
      case 'TokenAboutToExpire':
        return TokenAboutToExpireEvent();
      case 'TokenExpired':
        return TokenExpiredEvent();
      default:
        return UnknownEvent();
    }
  }
}

class NewMessageEvent extends TwilioEvent {
  final TwilioMessage message;
  final TwilioChannel channel;
  NewMessageEvent({
    @required this.message,
    @required this.channel,
  });
}

class ChannelJoinedEvent extends TwilioEvent {
  final TwilioChannel channel;
  ChannelJoinedEvent({@required this.channel});
}

class ChannelUpdatedEvent extends TwilioEvent {
  final TwilioChannel channel;
  ChannelUpdatedEvent({@required this.channel});
}

class TokenAboutToExpireEvent extends TwilioEvent {}

class TokenExpiredEvent extends TwilioEvent {}

class UnknownEvent extends TwilioEvent {}
