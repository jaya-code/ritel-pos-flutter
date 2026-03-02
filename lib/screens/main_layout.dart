import 'package:flutter/material.dart';
import 'pos_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PosScreen(),
    const Center(child: Text('Dashboard', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Transactions', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Customers', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Settings', style: TextStyle(fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            extended:
                MediaQuery.of(context).size.width >=
                1200, // Expand on very wide screens
            labelType: MediaQuery.of(context).size.width < 1200
                ? NavigationRailLabelType.selected
                : NavigationRailLabelType.none,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: Text('POS'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Transactions'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Customers'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
