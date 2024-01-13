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

@JsonSerializable(fieldRename: FieldRename.snake)
class NearbyPackage {
  @JsonKey(required: true)
  final String code;

  @JsonKey(required: true)
  final String ownerId;

  @JsonKey(required: true)
  final DateTime expireTime;

  @JsonKey(required: true)
  final String platform;

  final String? ownerName;

  NearbyPackage({
    required this.code,
    required this.ownerId,
    required this.expireTime,
    required this.platform,
    required this.ownerName,
  });

  factory NearbyPackage.fromJson(Map<String, dynamic> json) =>
      _$NearbyPackageFromJson(json);

  Map<String, dynamic> toJson() => _$NearbyPackageToJson(this);

  @override
  int get hashCode => (code + ownerId).hashCode;

  @override
  bool operator ==(Object other) {
    return (other is NearbyPackage) &&
        other.code == code &&
        other.ownerId == ownerId;
  }
}
