import 'package:meta/meta.dart';

class TwilioChannel {
  final String sid;
  final String uniqueName;
  final String friendlyName;
  final Map attributes;
  final String createdBy;
  final int unconsumedCount;
  final DateTime dateUpdated;
  TwilioChannel({
    @required this.sid,
    this.uniqueName = '',
    this.friendlyName = '',
    this.attributes,
    this.createdBy,
    this.unconsumedCount,
    this.dateUpdated,
  });

  static TwilioChannel fromData(dynamic data) {
    try {
      return TwilioChannel(
        sid: data['sid'],
        uniqueName: data['uniqueName'],
        friendlyName: data['friendlyName'],
        attributes: data['attributes'],
        createdBy: data['createdBy'],
        unconsumedCount: data['unconsumedCount'],
        dateUpdated: DateTime.fromMillisecondsSinceEpoch(data['dateUpdated']),
      );
    } catch (err) {
      print('Error parsing TwilioChannel: $err');
    }
  }

  TwilioChannel copyWith({
    uniqueName,
    friendlyName,
    attributes,
    createdBy,
    unconsumedCount,
    dateUpdated,
  }) =>
      TwilioChannel(
        sid: this.sid,
        uniqueName: uniqueName ?? this.uniqueName,
        friendlyName: friendlyName ?? this.friendlyName,
        attributes: attributes ?? this.attributes,
        createdBy: createdBy ?? this.createdBy,
        unconsumedCount: unconsumedCount ?? this.unconsumedCount,
        dateUpdated: dateUpdated ?? this.dateUpdated,
      );
}
