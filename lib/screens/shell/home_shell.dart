import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _irPara,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'A Casa',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Registrar',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Mural',
          ),
        ],
      ),
    );
  }
}
