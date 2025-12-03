import 'package:flutter/material.dart';
import 'package:meddiet/screens/pages/dashboard_page.dart';
import 'package:meddiet/screens/pages/patients_page.dart';
import 'package:meddiet/screens/pages/diet_plans_page.dart';
import 'package:meddiet/screens/pages/appointments_page.dart';
import 'package:meddiet/screens/pages/reports_page.dart';
import 'package:meddiet/screens/pages/settings_page.dart';
import 'package:meddiet/screens/pages/help_page.dart';

class MainLayout extends StatefulWidget {
  final Widget? child;
  final int? currentIndex;
  
  const MainLayout({
    super.key,
    this.child,
    this.currentIndex,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const PatientsPage(),
    const DietPlansPage(),
    const AppointmentsPage(),
    const ReportsPage(),
    const SettingsPage(),
    const HelpPage(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.currentIndex != null) {
      _selectedIndex = widget.currentIndex!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4DB8A8),
              Color(0xFF7B68B8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Fixed Sidebar - completely separate
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: _buildSidebar(context),
              ),
              const SizedBox(width: 20),
              // Dynamic Content Area
              Expanded(
                child: widget.child ?? _pages[_selectedIndex],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 70,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          _buildSidebarIcon(
            Icons.dashboard_rounded, 
            _selectedIndex == 0,
            onTap: () => _navigateToPage(0),
            tooltip: 'Dashboard',
          ),
          const SizedBox(height: 20),
          _buildSidebarIcon(
            Icons.people_rounded, 
            _selectedIndex == 1,
            onTap: () => _navigateToPage(1),
            tooltip: 'Patients',
          ),
          const SizedBox(height: 20),
          _buildSidebarIcon(
            Icons.restaurant_menu, 
            _selectedIndex == 2,
            onTap: () => _navigateToPage(2),
            tooltip: 'Diet Plans',
          ),
          const SizedBox(height: 20),
          _buildSidebarIcon(
            Icons.calendar_today_outlined, 
            _selectedIndex == 3,
            onTap: () => _navigateToPage(3),
            tooltip: 'Appointments',
          ),
          const SizedBox(height: 20),
          _buildSidebarIcon(
            Icons.analytics_outlined, 
            _selectedIndex == 4,
            onTap: () => _navigateToPage(4),
            tooltip: 'Reports',
          ),
          const Spacer(),
          _buildSidebarIcon(
            Icons.settings, 
            _selectedIndex == 5,
            onTap: () => _navigateToPage(5),
            tooltip: 'Settings',
          ),
          const SizedBox(height: 20),
          _buildSidebarIcon(
            Icons.help_outline, 
            _selectedIndex == 6,
            onTap: () => _navigateToPage(6),
            tooltip: 'Help',
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildSidebarIcon(IconData icon, bool isActive, {VoidCallback? onTap, String? tooltip}) {
    final iconWidget = InkWell(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: iconWidget,
      );
    }
    return iconWidget;
  }
}

