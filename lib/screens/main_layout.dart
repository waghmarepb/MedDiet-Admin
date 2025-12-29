import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:meddiet/constants/api_config.dart';
import 'package:meddiet/constants/api_endpoints.dart';
import 'package:meddiet/constants/app_colors.dart';
import 'package:meddiet/screens/pages/dashboard_page.dart';
import 'package:meddiet/screens/pages/patients_page.dart';
import 'package:meddiet/screens/pages/diet_plans_page.dart';
import 'package:meddiet/screens/pages/appointments_page.dart';
import 'package:meddiet/screens/pages/reports_page.dart';
import 'package:meddiet/screens/pages/settings_page.dart';
import 'package:meddiet/screens/pages/help_page.dart';
import 'package:meddiet/screens/login_screen.dart';
import 'package:meddiet/services/auth_service.dart';

class MainLayout extends StatefulWidget {
  final Widget? child;
  final int? currentIndex;
  final bool showLoginSuccess;
  
  const MainLayout({
    super.key,
    this.child,
    this.currentIndex,
    this.showLoginSuccess = false
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

  if (widget.showLoginSuccess) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Logged in successfully!"),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: _buildProfileDrawer(context),
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

  Widget _buildProfileDrawer(BuildContext context) {
    return Drawer(
      width: 400,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
      ),
      child: FutureBuilder(
        future: _fetchDoctorProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text("Error loading profile"));
          }

          final data = snapshot.data as Map<String, dynamic>;
          final doctor = data['data'];

          return Column(
            children: [
              _buildDrawerHeader(doctor),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildProfileInfoItem(Icons.email_outlined, "Email", doctor['email']),
                    _buildProfileInfoItem(Icons.phone_outlined, "Phone", doctor['phone']),
                    _buildProfileInfoItem(Icons.medical_services_outlined, "Specialization", doctor['specialization']),
                    _buildProfileInfoItem(Icons.business_outlined, "Clinic", doctor['clinic_name']),
                    _buildProfileInfoItem(Icons.qr_code_outlined, "Referral Code", doctor['referral_code']),
                    _buildProfileInfoItem(Icons.people_outline, "Total Patients", doctor['patient_count'].toString()),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () async {
                        await AuthService.logout();
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const SignInScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerHeader(Map<String, dynamic> doctor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "My Profile",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: doctor['profile_image'] != null
                ? ClipOval(child: Image.network(doctor['profile_image']))
                : Text(
                    doctor['name']?[0] ?? "D",
                    style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            doctor['name'] ?? "Doctor",
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            doctor['specialization'] ?? "Specialist",
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(color: Color(0xFF2D3142), fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchDoctorProfile() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.baseUrl + ApiEndpoints.profile),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'accept': '*/*',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
    return null;
  }
}

