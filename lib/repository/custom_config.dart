import 'package:anysend/util/shared_prefs.dart';

class CustomConfigRepository {
  static const String kOutputDirectory = "output_directory";

  String? get outputDirectory {
    return SharedPrefs().getString(kOutputDirectory);
  }

  Future<void> setOutputDirectory(String outputDirectory) async {
    SharedPrefs().setString(kOutputDirectory, outputDirectory);
  }
}
