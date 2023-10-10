import 'package:json_annotation/json_annotation.dart';

part 'package.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Package {
  @JsonKey(required: true)
  final String code;

  @JsonKey(required: true)
  final String ownerId;

  @JsonKey(required: true)
  final DateTime createTime;

  @JsonKey(required: true)
  final DateTime expireTime;

  Package({
    required this.code,
    required this.ownerId,
    required this.createTime,
    required this.expireTime,
  });

  factory Package.fromJson(Map<String, dynamic> json) =>
      _$PackageFromJson(json);

  Map<String, dynamic> toJson() => _$PackageToJson(this);
}
