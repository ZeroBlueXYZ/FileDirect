import 'dart:convert';
import 'dart:io';

import 'package:http_interceptor/http_interceptor.dart';

import 'package:anysend/model/package.dart';
import 'package:anysend/repository/base.dart';

class PackageRepository extends BaseRepository {
  Future<Package?> get({required String code}) async {
    final resp = await client.get(
      "$baseUri/package".toUri(),
      params: {"code": code},
    );
    if (resp.statusCode == HttpStatus.ok) {
      return Package.fromJson(jsonDecode(resp.body));
    }
    return null;
  }

  Future<Package?> create() async {
    final resp = await client.post("$baseUri/package".toUri());
    if (resp.statusCode == HttpStatus.ok) {
      return Package.fromJson(jsonDecode(resp.body));
    }
    return null;
  }
}
