import 'dart:convert';
import 'package:meta/meta.dart';

class TwilioMessage {
  final String sid;
  final String body;
  final Map attributes;
  final String author;
  final DateTime dateCreated;
  final String channelSid;
  final bool hasMedia;
  final int index;
  TwilioMessage({
    @required this.sid,
    this.body = '',
    this.attributes,
    this.author,
    this.dateCreated,
    @required this.channelSid,
    this.hasMedia = false,
    @required this.index,
  });

  static TwilioMessage fromData(dynamic data) {
    try {
      return TwilioMessage(
        sid: data['sid'],
        body: data['body'],
        attributes: jsonDecode(data['attributes']),
        author: data['author'],
        dateCreated: DateTime.parse(data['dateCreated']),
        channelSid: data['channelSid'],
        hasMedia: data['hasMedia'] ?? false,
        index: data['index'],
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
    hasMedia,
    index,
  }) =>
      TwilioMessage(
        sid: this.sid,
        body: body ?? this.body,
        attributes: attributes ?? this.attributes,
        author: author ?? this.author,
        dateCreated: dateCreated ?? this.dateCreated,
        channelSid: channelSid ?? this.channelSid,
        hasMedia: hasMedia ?? this.hasMedia,
        index: index ?? this.index,
      );
}
