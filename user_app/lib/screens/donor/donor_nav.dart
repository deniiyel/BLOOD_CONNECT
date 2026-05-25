import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import 'donor_dashboard.dart';
import 'donor_profile_screen.dart';
import '../shared/requests_screen.dart';

class DonorNav extends StatefulWidget {
  const DonorNav({super.key});

  @override
  State<DonorNav> createState() => _DonorNavState();
}

class _DonorNavState extends State<DonorNav> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startListeners();
    });
  }

  void _startListeners() {
    final uid = context.read<AppAuthProvider>().user?.uid;
    if (uid == null) return;
    context.read<DonorProvider>().watchDonorProfile(uid);
    context.read<RequestProvider>().watchDonorRequests(uid);
  }

  static const _screens = [
    DonorDashboard(),
    RequestsScreen(isForDonor: true),
    DonorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox_rounded),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
