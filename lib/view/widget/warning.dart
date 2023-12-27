import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

SnackBar unknownErrorSnackBar(BuildContext context) {
  return SnackBar(
    content: Text(AppLocalizations.of(context)!.warningUnknownError),
  );
}

SnackBar restrictedNetworkErrorSnackBar(
  BuildContext context, {
  required void Function() onPressed,
}) {
  return SnackBar(
    content: Text(AppLocalizations.of(context)!.warningRestrictedNetworkError),
    action: SnackBarAction(
      label: AppLocalizations.of(context)!.textOk,
      onPressed: onPressed,
    ),
    duration: const Duration(days: 1),
  );
}

SnackBar interruptedNetworkErrorSnackBar(
  BuildContext context, {
  required void Function() onPressed,
}) {
  return SnackBar(
    content: Text(AppLocalizations.of(context)!.warningInterruptedNetworkError),
    action: SnackBarAction(
      label: AppLocalizations.of(context)!.textOk,
      onPressed: onPressed,
    ),
    duration: const Duration(days: 1),
  );
}

SnackBar ongoingTaskSnackBar(BuildContext context) {
  return SnackBar(
    content: Text(AppLocalizations.of(context)!.warningOngoingTask),
  );
}

SnackBar invalidCodeSnackBar(BuildContext context) {
  return SnackBar(
    content: Text(AppLocalizations.of(context)!.warningInvalidCode),
  );
}

SnackBar codeCopiedToClipboardSnackBar(BuildContext context) {
  return SnackBar(
    content: Text(AppLocalizations.of(context)!.warningCodeCopiedToClipboard),
    duration: const Duration(seconds: 3),
  );
}

SnackBar deniedBySenderSnackBar(
  BuildContext context, {
  required void Function() onPressed,
}) {
  return SnackBar(
    content: Text(AppLocalizations.of(context)!.warningDeniedBySender),
    action: SnackBarAction(
      label: AppLocalizations.of(context)!.textOk,
      onPressed: onPressed,
    ),
    duration: const Duration(seconds: 8),
  );
}

SnackBar canceledByPeerSnackBar(
  BuildContext context, {
  required void Function() onPressed,
}) {
  return SnackBar(
    content: Text(AppLocalizations.of(context)!.warningCanceledByPeer),
    action: SnackBarAction(
      label: AppLocalizations.of(context)!.textOk,
      onPressed: onPressed,
    ),
    duration: const Duration(days: 1),
  );
}

SnackBar savedToFileSnackBar(BuildContext context) {
  return SnackBar(
    content: Text(AppLocalizations.of(context)!.warningSavedToFile),
    duration: const Duration(seconds: 3),
  );
}

Widget confirmCancellationDialog(
  BuildContext context, {
  required void Function(bool) onPressed,
}) {
  return AlertDialog(
    title: Text(
      AppLocalizations.of(context)!.textConfirmCancel,
      textAlign: TextAlign.center,
    ),
    actions: [
      TextButton(
        onPressed: () => onPressed(false),
        child: Text(
          AppLocalizations.of(context)!.textNo,
          textAlign: TextAlign.center,
        ),
      ),
      TextButton(
        onPressed: () => onPressed(true),
        child: Text(
          AppLocalizations.of(context)!.textYes,
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}
