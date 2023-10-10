import 'dart:io';

import 'package:http_interceptor/http_interceptor.dart';

import 'package:anysend/repository/base.dart';

class HealthRepository extends BaseRepository {
  Future<bool> get() async {
    final resp = await client.get("$baseUri/health".toUri());
    return resp.statusCode == HttpStatus.ok;
  }
}
