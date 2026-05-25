import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import 'recipient_home.dart';
import 'donor_search_screen.dart';
import '../shared/requests_screen.dart';
import 'recipient_profile_screen.dart';

class RecipientNav extends StatefulWidget {
  const RecipientNav({super.key});

  @override
  State<RecipientNav> createState() => _RecipientNavState();
}

class _RecipientNavState extends State<RecipientNav> {
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
    context.read<RequestProvider>().watchRecipientRequests(uid);
    // Pre-load available donors for search + home
    context.read<DonorProvider>().watchDonorSearch();
  }

  static const _screens = [
    RecipientHome(),
    DonorSearchScreen(),
    RequestsScreen(isForDonor: false),
    RecipientProfileScreen(),
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Find Donors',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
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
