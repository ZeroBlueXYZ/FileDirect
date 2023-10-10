import 'package:anysend/model/auth_token.dart';

class GlobalConfig {
  factory GlobalConfig() => _instance;
  static final GlobalConfig _instance = GlobalConfig._internal();
  GlobalConfig._internal();

  late final String serverUri;
  AuthToken? authToken;

  void ensureInit({required String serverUri}) {
    this.serverUri = serverUri;
  }
}
