import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/activity_sync_service.dart';
import '../../state/session_controller.dart';
import '../activity/register_activity_screen.dart';
import '../feed/feed_screen.dart';
import '../home/home_screen.dart';

/// Casca com a navegação inferior entre as 3 telas principais.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ao abrir: tenta subir o que ficou parado da última vez sem internet.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sincronizar());
    // Enquanto o app está aberto: cobre o caso da internet voltar sozinha,
    // sem ninguém tocar em nada.
    _syncTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _sincronizar(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Voltou do bolso já no wi-fi de casa: momento mais provável de dar certo.
    if (state == AppLifecycleState.resumed) _sincronizar();
  }

  void _sincronizar() {
    if (!mounted) return;
    final sync = context.read<ActivitySyncService>();
    if (!sync.hasPending && sync.pendingCount == 0) {
      // Primeira chamada ainda não leu o disco; refresh resolve.
      sync.refresh();
    }
    final user = context.read<SessionController>().user;
    if (user != null) sync.drain(user);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onRegisterActivity: () => _goTo(1)),
          RegisterActivityScreen(onDone: () => _goTo(2)),
          const FeedScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'A Casa',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
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
