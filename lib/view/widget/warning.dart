import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

SnackBar unknownErrorSnackBar(BuildContext context) {
  return SnackBar(
    content: Text(AppLocalizations.of(context)!.warningUnknownError),
  );
}

SnackBar restrictedNetworkErrorSnackBar(BuildContext context) {
  return SnackBar(
    content: Text(AppLocalizations.of(context)!.warningRestrictedNetworkError),
    duration: const Duration(seconds: 8),
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
