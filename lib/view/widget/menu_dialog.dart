import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:anysend/util/global_config.dart';
import 'package:anysend/view/screen/help.dart';

class MenuDialog extends StatefulWidget {
  const MenuDialog({super.key});

  @override
  State<MenuDialog> createState() => _MenuDialogState();
}

class _MenuDialogState extends State<MenuDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.symmetric(vertical: 20),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Image(image: GlobalConfig.appIcon),
            title: Text(
              AppLocalizations.of(context)!.appName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(GlobalConfig().version),
                Text(
                  GlobalConfig().copyright,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            child: Divider(
              height: 1,
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(80),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(
              AppLocalizations.of(context)!.helpTitle,
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
