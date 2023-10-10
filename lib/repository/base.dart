import 'package:http_interceptor/http_interceptor.dart';

import 'package:anysend/model/auth_token.dart';
import 'package:anysend/util/global_config.dart';
import 'package:anysend/util/http_interceptors.dart';

abstract class BaseRepository {
  String get baseUri => GlobalConfig().serverUri;
  String get baseWsUri => "ws${GlobalConfig().serverUri.substring(4)}";
  AuthToken? get authToken => GlobalConfig().authToken;

  final InterceptedClient client = InterceptedClient.build(
    interceptors: [
      ServiceInterceptor(),
    ],
    retryPolicy: ServiceRetryPolicy(
      authServerUri: "${GlobalConfig().serverUri}/auth/anonymous-login",
    ),
    requestTimeout: const Duration(seconds: 1),
  );
}
