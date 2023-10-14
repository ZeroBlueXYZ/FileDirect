import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';

import 'package:anysend/model/package.dart';
import 'package:anysend/model/platform_type.dart';

class NearbyCard extends StatelessWidget {
  final NearbyPackage package;
  final void Function()? onTap;

  const NearbyCard({
    super.key,
    required this.package,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListTile(
        leading: Icon(_platformIconData(package.platform)),
        title: Text(
          package.code,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${AppLocalizations.of(context)!.textExpiresIn} ",
            ),
            TimerCountdown(
              endTime: package.expireTime,
              format: CountDownTimerFormat.minutesSeconds,
              enableDescriptions: false,
              spacerWidth: 2,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _platformIconData(String platform) {
    switch (platform) {
      case PlatformType.android:
        return Icons.phone_android;
      case PlatformType.ios:
        return Icons.phone_iphone;
      case PlatformType.linux:
        return Icons.computer;
      case PlatformType.windows:
        return Icons.desktop_windows;
      case PlatformType.macos:
        return Icons.laptop_mac;
      default:
        return Icons.laptop_chromebook;
    }
  }
}
