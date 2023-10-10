// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Signal _$SignalFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['receiver', 'sender', 'type', 'message'],
  );
  return Signal(
    receiver: json['receiver'] as String,
    sender: json['sender'] as String,
    type: json['type'] as String,
    message: json['message'] as String,
  );
}

Map<String, dynamic> _$SignalToJson(Signal instance) => <String, dynamic>{
      'receiver': instance.receiver,
      'sender': instance.sender,
      'type': instance.type,
      'message': instance.message,
    };
