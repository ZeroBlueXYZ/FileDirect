import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:anysend/model/job_state.dart';
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
            const VerticalDivider(),
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
          label: Text(AppLocalizations.of(context)!.homeNavigationItemSend),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.download_outlined),
          selectedIcon: const Icon(Icons.download),
          label: Text(AppLocalizations.of(context)!.homeNavigationItemReceive),
        ),
      ],
      labelType: NavigationRailLabelType.all,
      selectedIndex: _navigationItemIndex,
      onDestinationSelected: (value) {
        setState(() {
          _navigationItemIndex = value;
        });
      },
    );
  }

  BottomNavigationBar _bottomNavigationBar() {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.upload_outlined),
          activeIcon: const Icon(Icons.upload),
          label: AppLocalizations.of(context)!.homeNavigationItemSend,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.download_outlined),
          activeIcon: const Icon(Icons.download),
          label: AppLocalizations.of(context)!.homeNavigationItemReceive,
        ),
      ],
      currentIndex: _navigationItemIndex,
      onTap: (value) {
        setState(() {
          _navigationItemIndex = value;
        });
      },
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
}
