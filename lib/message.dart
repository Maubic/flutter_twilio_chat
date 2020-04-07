import 'package:meta/meta.dart';

class TwilioMessage {
  final String sid;
  final String body;
  final Map attributes;
  final String author;
  final DateTime dateCreated;
  final String channelSid;
  TwilioMessage({
    @required this.sid,
    this.body = '',
    this.attributes,
    this.author,
    this.dateCreated,
    @required this.channelSid,
  });

  static TwilioMessage fromData(dynamic data) {
    try {
      return TwilioMessage(
        sid: data['sid'],
        body: data['body'],
        attributes: data['attributes'],
        author: data['author'],
        dateCreated: DateTime.parse(data['dateCreated']),
        channelSid: data['channelSid'],
      );
    } catch (err) {
      print('Error parsing TwilioMessage: $err');
    }
  }

  TwilioMessage copyWith({
    body,
    attributes,
    author,
    dateCreated,
    channelSid,
  }) =>
      TwilioMessage(
        sid: this.sid,
        body: body ?? this.body,
        attributes: attributes ?? this.attributes,
        author: author ?? this.author,
        dateCreated: dateCreated ?? this.dateCreated,
        channelSid: channelSid ?? this.channelSid,
      );
}
