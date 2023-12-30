import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final qa = [
      (
        AppLocalizations.of(context)!.helpQuestionFileLocation,
        AppLocalizations.of(context)!.helpAnswerFileLocation,
      ),
      (
        AppLocalizations.of(context)!.helpQuestionDataSecurity,
        AppLocalizations.of(context)!.helpAnswerDataSecurity,
      ),
      (
        AppLocalizations.of(context)!.helpQuestionLimits,
        AppLocalizations.of(context)!.helpAnswerLimits,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.helpTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView.separated(
            itemBuilder: (context, index) => ListTile(
              title: Text(
                qa[index].$1,
                // style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(qa[index].$2),
            ),
            separatorBuilder: (context, index) => const Divider(
              height: 10,
              color: Colors.transparent,
            ),
            itemCount: qa.length,
          ),
        ),
      ),
    );
  }
}
