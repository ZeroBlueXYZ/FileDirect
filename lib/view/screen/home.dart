import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:anysend/model/job_state.dart';
import 'package:anysend/util/global_config.dart';
import 'package:anysend/view/screen/help.dart';
import 'package:anysend/view/screen/receive.dart';
import 'package:anysend/view/screen/send.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navigationItemIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return constraints.maxWidth > 600 ? _horizontalHome() : _verticalHome();
    });
  }

  Scaffold _horizontalHome() {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _navigationRail(),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _indexedStack(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Scaffold _verticalHome() {
    return Scaffold(
      appBar: _appBar(),
      body: SafeArea(
        child: _indexedStack(),
      ),
      bottomNavigationBar: _bottomNavigationBar(),
    );
  }

  NavigationRail _navigationRail() {
    return NavigationRail(
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.upload_outlined),
          selectedIcon: const Icon(Icons.upload),
          label: Text(AppLocalizations.of(context)!.textSend),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.download_outlined),
          selectedIcon: const Icon(Icons.download),
          label: Text(AppLocalizations.of(context)!.textReceive),
        ),
      ],
      leading: Container(
        padding: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 1,
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withAlpha(255),
            ),
          ),
        ),
        child: IconButton(
          onPressed: () => showDialog(
            context: context,
            builder: (context) => _aboutDialog(),
          ),
          icon: const Image(image: GlobalConfig.appIcon40x40),
        ),
      ),
      trailing: Expanded(
          child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _helpIconButton(),
            ],
          ),
        ),
      )),
      labelType: NavigationRailLabelType.all,
      selectedIndex: _navigationItemIndex,
      onDestinationSelected: (value) {
        setState(() {
          _navigationItemIndex = value;
        });
      },
      backgroundColor:
          Theme.of(context).colorScheme.surfaceVariant.withAlpha(80),
      indicatorColor: Theme.of(context).colorScheme.surfaceVariant,
    );
  }

  AppBar _appBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Image(image: GlobalConfig.appIcon, width: 30),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => _aboutDialog(),
            ),
          ),
          Text(
            AppLocalizations.of(context)!.appName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        _helpIconButton(),
      ],
    );
  }

  BottomNavigationBar _bottomNavigationBar() {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.upload_outlined),
          activeIcon: const Icon(Icons.upload),
          label: AppLocalizations.of(context)!.textSend,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.download_outlined),
          activeIcon: const Icon(Icons.download),
          label: AppLocalizations.of(context)!.textReceive,
        ),
      ],
      currentIndex: _navigationItemIndex,
      onTap: (value) {
        setState(() {
          _navigationItemIndex = value;
        });
      },
      iconSize: 30,
    );
  }

  Widget _indexedStack() {
    return ChangeNotifierProvider(
      create: (context) => JobStateModel(),
      child: IndexedStack(
        index: _navigationItemIndex,
        children: const [
          SendScreen(),
          ReceiveScreen(),
        ],
      ),
    );
  }

  AboutDialog _aboutDialog() {
    return AboutDialog(
      applicationName: AppLocalizations.of(context)!.appName,
      applicationVersion: GlobalConfig().version,
      applicationIcon: const Image(image: GlobalConfig.appIcon, width: 80),
      applicationLegalese: GlobalConfig().copyright,
      children: [
        const Divider(height: 20, color: Colors.transparent),
        Text(AppLocalizations.of(context)!.appDescription),
      ],
    );
  }

  IconButton _helpIconButton() {
    return IconButton(
      icon: const Icon(Icons.help_outline),
      // iconSize: 28,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HelpScreen(),
        ),
      ),
    );
  }
}
