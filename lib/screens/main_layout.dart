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
    this.showLoginSuccess = false,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();

  /// Open notifications drawer from child widgets
  static void openNotifications(BuildContext context) {
    final state = context.findAncestorStateOfType<_MainLayoutState>();
    state?._openNotificationsDrawer();
  }

  /// Open profile drawer from child widgets
  static void openProfile(BuildContext context) {
    final state = context.findAncestorStateOfType<_MainLayoutState>();
    state?._openProfileDrawer();
  }
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _showNotifications =
      false; // Toggle between profile and notifications drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    const DashboardPage(),
    const PatientsPage(),
    const DietPlansPage(),
    const AppointmentsPage(),
    const ReportsPage(),
    const SettingsPage(),
    const HelpPage(),
  ];

  /// Open notifications drawer
  void _openNotificationsDrawer() {
    setState(() => _showNotifications = true);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  /// Open profile drawer
  void _openProfileDrawer() {
    setState(() => _showNotifications = false);
    _scaffoldKey.currentState?.openEndDrawer();
  }

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
      key: _scaffoldKey,
      endDrawer: _showNotifications
          ? _buildNotificationsDrawer(context)
          : _buildProfileDrawer(context),
      onEndDrawerChanged: (isOpened) {
        // Reset to profile drawer when closed
        if (!isOpened) {
          setState(() => _showNotifications = false);
        }
      },
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4DB8A8), Color(0xFF7B68B8)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Fixed Sidebar
              _buildSidebar(context),
              const SizedBox(width: 15),
              // Dynamic Content Area
              Expanded(child: widget.child ?? _pages[_selectedIndex]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(vertical: 20),
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
          const SizedBox(height: 40),
          _buildSidebarItem(Icons.dashboard_rounded, 'Dashboard', 0),
          const SizedBox(height: 15),
          _buildSidebarItem(Icons.people_rounded, 'Patients', 1),
          const SizedBox(height: 15),
          _buildSidebarItem(Icons.restaurant_menu, 'Diet Plans', 2),
          const SizedBox(height: 15),
          _buildSidebarItem(Icons.calendar_today_outlined, 'Appointments', 3),
          const SizedBox(height: 15),
          _buildSidebarItem(Icons.analytics_outlined, 'Reports', 4),
          const Spacer(),
          _buildSidebarItem(Icons.settings, 'Settings', 5),
          const SizedBox(height: 15),
          _buildSidebarItem(Icons.help_outline, 'Help', 6),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildSidebarItem(IconData icon, String tooltip, int index) {
    final isActive = _selectedIndex == index;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _navigateToPage(index),
        child: Container(
          width: double.infinity,
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Active Background / Bridge
              if (isActive) ...[
                // Top Scoop (Page side)
                Positioned(
                  top: -30,
                  right: -15,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CustomPaint(
                      painter: ConcaveCornerPainter(isTop: true),
                    ),
                  ),
                ),
                // Main Bridge
                Positioned(
                  left: 0,
                  right: -35,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        bottomLeft: Radius.circular(25),
                      ),
                    ),
                  ),
                ),
                // Bottom Scoop (Page side)
                Positioned(
                  bottom: -30,
                  right: -15,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CustomPaint(
                      painter: ConcaveCornerPainter(isTop: false),
                    ),
                  ),
                ),
              ],
              // Icon
              Icon(
                icon,
                color: isActive ? AppColors.primary : Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
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
                    _buildProfileInfoItem(
                      Icons.email_outlined,
                      "Email",
                      doctor['email'],
                    ),
                    _buildProfileInfoItem(
                      Icons.phone_outlined,
                      "Phone",
                      doctor['phone'],
                    ),
                    _buildProfileInfoItem(
                      Icons.medical_services_outlined,
                      "Specialization",
                      doctor['specialization'],
                    ),
                    _buildProfileInfoItem(
                      Icons.business_outlined,
                      "Clinic",
                      doctor['clinic_name'],
                    ),
                    _buildProfileInfoItem(
                      Icons.qr_code_outlined,
                      "Referral Code",
                      doctor['referral_code'],
                    ),
                    _buildProfileInfoItem(
                      Icons.people_outline,
                      "Total Patients",
                      doctor['patient_count'].toString(),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () async {
                        await AuthService.logout();
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
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
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "My Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: doctor['profile_image'] != null
                ? ClipOval(child: Image.network(doctor['profile_image']))
                : Text(
                    doctor['name']?[0] ?? "D",
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            doctor['name'] ?? "Doctor",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            doctor['specialization'] ?? "Specialist",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
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
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
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
                  style: const TextStyle(
                    color: Color(0xFF2D3142),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsDrawer(BuildContext context) {
    return Drawer(
      width: 400,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '2 Unread',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Notifications list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildNotificationItem(
                  icon: Icons.person_add,
                  iconColor: Colors.green,
                  title: 'New Patient Added',
                  message: 'A new patient has joined your care plan',
                  time: '5 min ago',
                  isUnread: true,
                ),
                _buildNotificationItem(
                  icon: Icons.calendar_today,
                  iconColor: Colors.blue,
                  title: 'Appointment Reminder',
                  message: 'You have 3 appointments scheduled for today',
                  time: '1 hour ago',
                  isUnread: true,
                ),
                _buildNotificationItem(
                  icon: Icons.check_circle,
                  iconColor: Colors.orange,
                  title: 'Patient Progress Update',
                  message: 'John Doe has completed today\'s diet plan',
                  time: '2 hours ago',
                  isUnread: false,
                ),
                _buildNotificationItem(
                  icon: Icons.chat_bubble,
                  iconColor: Colors.purple,
                  title: 'New Message',
                  message: 'You have 2 unread messages from patients',
                  time: '3 hours ago',
                  isUnread: false,
                ),
                _buildNotificationItem(
                  icon: Icons.warning,
                  iconColor: Colors.red,
                  title: 'Alert',
                  message: 'Patient goal not met - follow up required',
                  time: 'Yesterday',
                  isUnread: false,
                ),
                _buildNotificationItem(
                  icon: Icons.medical_services,
                  iconColor: Colors.teal,
                  title: 'Prescription Update',
                  message: 'Medication dosage adjusted for Patient #1234',
                  time: '2 days ago',
                  isUnread: false,
                ),
              ],
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to full notifications page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View All Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFF3F4F6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? const Color(0xFF6366F1).withValues(alpha: 0.3)
              : const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
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
      debugPrint('Error fetching profile: $e');
    }
    return null;
  }
}

class ConcaveCornerPainter extends CustomPainter {
  final bool isTop;

  ConcaveCornerPainter({required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();

    if (isTop) {
      // Top Scoop: Fill square but cut out bottom-right circle
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
      path.arcToPoint(
        Offset(0, size.height),
        radius: Radius.circular(size.width),
        clockwise: true,
      );
    } else {
      // Bottom Scoop: Fill square but cut out top-right circle
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.arcToPoint(
        const Offset(0, 0),
        radius: Radius.circular(size.width),
        clockwise: false,
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
