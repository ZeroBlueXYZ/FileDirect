import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  factory SharedPrefs() => _instance;
  static final SharedPrefs _instance = SharedPrefs._internal();
  SharedPrefs._internal();

  late final SharedPreferences sharedPrefs;

  ensureInit() async {
    sharedPrefs = await SharedPreferences.getInstance();
  }

  String? getString(String key) => sharedPrefs.getString(key);

  Future<bool> setString(String key, String value) async =>
      await sharedPrefs.setString(key, value);
}
