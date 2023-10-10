import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http_interceptor/http_interceptor.dart';

import 'package:anysend/model/auth_token.dart';
import 'package:anysend/util/global_config.dart';

class ServiceInterceptor implements InterceptorContract {
  @override
  Future<RequestData> interceptRequest({required RequestData data}) async {
    data.headers[HttpHeaders.contentTypeHeader] = "application/json";
    if (GlobalConfig().authToken != null) {
      data.headers[HttpHeaders.authorizationHeader] =
          "bearer ${GlobalConfig().authToken!.accessToken}";
    }
    return data;
  }

  @override
  Future<ResponseData> interceptResponse({required ResponseData data}) async {
    return data;
  }
}

class ServiceRetryPolicy extends RetryPolicy {
  final String authServerUri;

  ServiceRetryPolicy({required this.authServerUri});

  @override
  int get maxRetryAttempts => 1;

  @override
  bool shouldAttemptRetryOnException(Exception reason) {
    return (reason is TimeoutException);
  }

  @override
  Future<bool> shouldAttemptRetryOnResponse(ResponseData response) async {
    switch (response.statusCode) {
      case HttpStatus.unauthorized:
        return await refreshToken();
      case HttpStatus.serviceUnavailable:
        return true;
      default:
        return false;
    }
  }

  Future<bool> refreshToken() async {
    try {
      final resp = await InterceptedHttp.build(
        interceptors: [],
      ).post(authServerUri.toUri());
      if (resp.statusCode == HttpStatus.ok) {
        GlobalConfig().authToken = AuthToken.fromJson(jsonDecode(resp.body));
        return true;
      }
    } catch (e) {
      // do nothing
    }
    return false;
  }
}
