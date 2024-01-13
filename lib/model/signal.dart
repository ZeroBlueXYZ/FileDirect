import 'package:json_annotation/json_annotation.dart';

part 'signal.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Signal {
  @JsonKey(required: true)
  final String receiver;

  @JsonKey(required: true)
  final String sender;

  @JsonKey(required: true)
  final String type;

  @JsonKey(required: true)
  final String message;

  Signal({
    required this.receiver,
    required this.sender,
    required this.type,
    required this.message,
  });

  factory Signal.fromJson(Map<String, dynamic> json) => _$SignalFromJson(json);

  Map<String, dynamic> toJson() => _$SignalToJson(this);
}

class SignalTypes {
  static const String askToReceive = "ASK_TO_RECEIVE";
  static const String cancelAskToReceive = "CANCEL_ASK_TO_RECEIVE";
  static const String accept = "ACCEPT";
  static const String deny = "DENY";
  static const String cancel = "CANCEL";
  static const String done = "DONE";
  static const String iceCandidate = "ICE_CANDIDATE";
  static const String sdp = "SDP";
}
