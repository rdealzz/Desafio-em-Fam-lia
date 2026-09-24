import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../services/activity_sync_service.dart';
import '../../state/session_controller.dart';
import '../activity/register_activity_screen.dart';
import '../feed/feed_screen.dart';
import '../home/home_screen.dart';

/// Casca das três telas.
///
/// `PageView` em vez de `IndexedStack`: dá para **arrastar** entre as telas,
/// que é como todo mundo já espera navegar no celular. `keepPage` mantém a
/// rolagem de cada uma, e as três ficam vivas — trocar de aba não reconstrói
/// nem refaz consulta.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  final PageController _pager = PageController();
  int _index = 0;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sincronizar());
    _syncTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _sincronizar(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sincronizar();
  }

  void _sincronizar() {
    if (!mounted) return;
    final sync = context.read<ActivitySyncService>();
    final user = context.read<SessionController>().user;
    if (user != null) sync.drain(user);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _pager.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _irPara(int i) {
    HapticFeedback.selectionClick();
    _pager.animateToPage(i, duration: Motion.base, curve: Motion.enter);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: PageView(
        controller: _pager,
        onPageChanged: (i) => setState(() => _index = i),
        physics: const ClampingScrollPhysics(),
        children: [
          HomeScreen(onRegisterActivity: () => _irPara(1)),
          RegisterActivityScreen(onDone: () => _irPara(2)),
          const FeedScreen(),
        ],
      ),
      // Barra de abas do iOS (CupertinoTabBar): ícones no traço dos SF
      // Symbols, sem a pílula de seleção do Material, fio fino no topo.
      bottomNavigationBar: CupertinoTheme(
        data: CupertinoThemeData(
          primaryColor: p.accent,
          textTheme: const CupertinoTextThemeData(
            tabLabelTextStyle: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
        child: CupertinoTabBar(
          currentIndex: _index,
          onTap: _irPara,
          height: 54,
          iconSize: 25,
          activeColor: p.accent,
          inactiveColor: p.textMuted,
          backgroundColor: p.surface,
          border: Border(
            top: BorderSide(color: p.borderStrong, width: 0.5),
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house),
              activeIcon: Icon(CupertinoIcons.house_fill),
              label: 'A Casa',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.plus_circle),
              activeIcon: Icon(CupertinoIcons.plus_circle_fill),
              label: 'Registrar',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chat_bubble_2),
              activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill),
              label: 'Mural',
            ),
          ],
        ),
      ),
    );
  }
}
