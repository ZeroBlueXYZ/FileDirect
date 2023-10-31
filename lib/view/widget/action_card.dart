import 'package:flutter/material.dart';

class ActionCard extends StatelessWidget {
  final Widget? title;
  final Widget? subtitle;
  final void Function()? onTap;
  final IconData? trailingIcon;
  final void Function()? onTrailingIconPressed;
  final LinearProgressIndicator? linearProgressIndicator;

  const ActionCard({
    super.key,
    this.title,
    this.subtitle,
    this.onTap,
    this.trailingIcon,
    this.onTrailingIconPressed,
    this.linearProgressIndicator,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: const RoundedRectangleBorder(),
      child: Column(children: [
        ListTile(
          title: title,
          subtitle: subtitle,
          trailing: IconButton(
            icon: Icon(trailingIcon),
            onPressed: onTrailingIconPressed,
          ),
          onTap: onTap,
        ),
        if (linearProgressIndicator != null) linearProgressIndicator!,
      ]),
    );
  }
}
