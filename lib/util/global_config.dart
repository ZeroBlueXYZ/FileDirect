import 'package:anysend/model/auth_token.dart';
import 'package:anysend/util/string_helper.dart';

class GlobalConfig {
  factory GlobalConfig() => _instance;
  static final GlobalConfig _instance = GlobalConfig._internal();
  GlobalConfig._internal();

  final String multicastId = randomString(36);
  late final String serverUri;
  AuthToken? authToken;

  void ensureInit({required String serverUri}) {
    this.serverUri = serverUri;
  }
}
