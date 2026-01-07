import 'package:flutter/material.dart';
import 'package:meddiet/services/auth_service.dart';
import 'package:meddiet/constants/api_config.dart';
import 'package:meddiet/constants/api_endpoints.dart';
import 'package:meddiet/screens/main_layout.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Real data from API
  List<Map<String, dynamic>> _patients = [];
  int _totalPatients = 0;
  bool _isLoading = true;

  // Calendar data
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentMonth = DateTime.now();
    _generateWeekDays();
    _fetchDashboardData();
  }

  /// Generate the current week days for calendar display
  void _generateWeekDays() {
    final now = _selectedDate;
    final weekday = now.weekday % 7; // Convert to Sunday = 0
    final startOfWeek = now.subtract(Duration(days: weekday));
    _weekDays = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );
  }

  Future<void> _fetchDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patients}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _patients = List<Map<String, dynamic>>.from(data['data']);
            _totalPatients = _patients.length;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  bool _isRecentPatient(Map<String, dynamic> patient) {
    final createdAt = patient['created_at'];
    if (createdAt == null) return false;
    try {
      final date = DateTime.parse(createdAt);
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      return date.isAfter(weekAgo);
    } catch (e) {
      return false;
    }
  }

  List<Map<String, dynamic>> get _recentPatients {
    final sorted = List<Map<String, dynamic>>.from(_patients);
    sorted.sort((a, b) {
      final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });
    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          children: [
            // Header at top
            _buildHeader(),
            // Main content area with 2 columns
            Expanded(
              child: Row(
                children: [
                  // Center column - Transactions & Summary (80%)
                  Expanded(flex: 8, child: _buildCenterColumn()),
                  // Right column - Contacts (20%)
                  Expanded(flex: 2, child: _buildRightSidebar()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildHeader() {
    final doctorName = AuthService.doctorData?['name'] ?? 'Doctor';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_getGreeting()} $doctorName!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          Row(
            children: [
              // Notification bell with red dot
              InkWell(
                onTap: () {
                  // Open notifications drawer from main layout
                  final scaffoldContext = context
                      .findAncestorStateOfType<ScaffoldState>()
                      ?.context;
                  if (scaffoldContext != null) {
                    MainLayout.openNotifications(scaffoldContext);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        size: 18,
                        color: Color(0xFF2D3142),
                      ),
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Profile avatar
              InkWell(
                onTap: () => Scaffold.of(context).openEndDrawer(),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFFDB777),
                  child: Text(
                    (AuthService.doctorData?['name']?[0] ?? 'D').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenterColumn() {
    return Builder(
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickSummary(),
              const SizedBox(height: 30),
              _buildAllUsersList(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MedDiet Insights & Summary',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final url = Uri.parse('http://localhost:3000/api-docs');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.code, size: 16),
              label: const Text(
                'API Docs',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildImageCard(
                'Healthy Salads',
                'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=2070&auto=format&fit=crop',
                'Recommended for Heart Health',
              ),
              const SizedBox(width: 20),
              _buildImageCard(
                'Olive Oil Benefits',
                'https://images.unsplash.com/photo-1473093226795-af9932fe5856?q=80&w=2012&auto=format&fit=crop',
                'Key Ingredient in MedDiet',
              ),
              const SizedBox(width: 20),
              _buildImageCard(
                'Fresh Seafood',
                'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=1974&auto=format&fit=crop',
                'Weekly Protein Source',
              ),
              const SizedBox(width: 20),
              _buildImageCard(
                'Nuts & Grains',
                'https://images.unsplash.com/photo-1511690656952-34342bb7c2f2?q=80&w=2064&auto=format&fit=crop',
                'Essential Healthy Fats',
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Patients',
                _isLoading ? '...' : '$_totalPatients',
                'Registered',
                const Color(0xFF5B4FA3),
                true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Active Plans',
                _isLoading ? '...' : '$_totalPatients',
                'Active',
                const Color(0xFF00BCD4),
                false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'This Week',
                _isLoading
                    ? '...'
                    : '${_patients.where((p) => _isRecentPatient(p)).length}',
                'New Patients',
                const Color(0xFF5B4FA3),
                false,
                showBars: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildPieChartCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildImageCard(String title, String imageUrl, String subtitle) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllUsersList(BuildContext context) {
    final colors = [
      const Color(0xFF5B4FA3),
      const Color(0xFF00BCD4),
      const Color(0xFFFF9800),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Patients (${_recentPatients.length})',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            IconButton(
              onPressed: _fetchDashboardData,
              icon: Icon(
                Icons.refresh,
                color: _isLoading ? Colors.grey : const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _recentPatients.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      'No patients registered yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _recentPatients.asMap().entries.map((entry) {
                    final index = entry.key;
                    final patient = entry.value;
                    final name = patient['name'] ?? 'Unknown';
                    final email = patient['email'] ?? '';
                    final createdAt = patient['created_at'] ?? '';

                    String timeAgo = 'New';
                    try {
                      final date = DateTime.parse(createdAt);
                      final diff = DateTime.now().difference(date);
                      if (diff.inDays > 0) {
                        timeAgo =
                            '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
                      } else if (diff.inHours > 0) {
                        timeAgo =
                            '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
                      } else {
                        timeAgo = 'Just now';
                      }
                    } catch (e) {
                      debugPrint('Error parsing date: $e');
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < _recentPatients.length - 1 ? 12 : 0,
                      ),
                      child: _buildRealUserItem(
                        context,
                        name,
                        email,
                        timeAgo,
                        colors[index % colors.length],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildRealUserItem(
    BuildContext context,
    String name,
    String email,
    String timeAgo,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [iconColor.withValues(alpha: 0.8), iconColor],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registered $timeAgo',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    String currency,
    Color color,
    bool showAreaChart, {
    bool showBars = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
              ),
              Icon(Icons.trending_up, color: Colors.green, size: 14),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          Text(
            currency,
            style: const TextStyle(fontSize: 11, color: Color(0xFFBDBDBD)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 70,
            child: showAreaChart
                ? CustomPaint(
                    size: const Size(double.infinity, 70),
                    painter: AreaChartPainter(color),
                  )
                : showBars
                ? CustomPaint(
                    size: const Size(double.infinity, 70),
                    painter: BarChartPainter(color),
                  )
                : CustomPaint(
                    size: const Size(double.infinity, 70),
                    painter: LineChartPainter(color),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Graph',
                style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
              ),
              const Icon(Icons.trending_up, color: Colors.green, size: 14),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(painter: DonutChartPainter()),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '35%\nEducation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF9E9E9E),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MY CALENDAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getMonthYear(_currentMonth),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Week Days Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeekDay('Sun'),
                      _buildWeekDay('Mon'),
                      _buildWeekDay('Tue'),
                      _buildWeekDay('Wed'),
                      _buildWeekDay('Thu'),
                      _buildWeekDay('Fri'),
                      _buildWeekDay('Sat'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Calendar Days Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _weekDays.map((date) {
                      final isSelected =
                          date.day == _selectedDate.day &&
                          date.month == _selectedDate.month &&
                          date.year == _selectedDate.year;
                      return _buildCalendarDay(date.day.toString(), isSelected);
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
                // Date Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getFormattedDate(_selectedDate),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[400],
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Appointments List
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildAppointmentItem(
                        '2:00 pm',
                        'Meeting with chief physician Dr. Williams',
                        const Color(0xFFEC4899),
                      ),
                      const SizedBox(height: 16),
                      _buildAppointmentItem(
                        '2:30 pm',
                        'Consultation with Mr. White',
                        const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(height: 16),
                      _buildAppointmentItem(
                        '3:00 pm',
                        'Consultation with Mrs. Maisey',
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 16),
                      _buildAppointmentItem(
                        '3:50 pm',
                        'Examination of Mrs. Lee\'s freckle',
                        const Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDay(String day) {
    return SizedBox(
      width: 30,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  /// Get month and year (e.g., "January 2026")
  String _getMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Get formatted date (e.g., "JANUARY, 07")
  String _getFormattedDate(DateTime date) {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '${months[date.month - 1]}, $day';
  }

  Widget _buildCalendarDay(String day, bool isSelected) {
    return Container(
      width: 30,
      height: 40,
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              )
            : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(String time, String title, Color dotColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time
        SizedBox(
          width: 55,
          child: Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Dot
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        // Title
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Painters
class AreaChartPainter extends CustomPainter {
  final Color color;
  AreaChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.3);
    path.lineTo(size.width * 0.6, size.height * 0.4);
    path.lineTo(size.width * 0.8, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LineChartPainter extends CustomPainter {
  final Color color;
  LineChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.lineTo(size.width * 0.25, size.height * 0.7);
    path.lineTo(size.width * 0.5, size.height * 0.4);
    path.lineTo(size.width * 0.75, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.3);

    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.5),
      4,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BarChartPainter extends CustomPainter {
  final Color color;
  BarChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = size.width / 10;
    final bars = [0.7, 0.5, 0.9, 0.4, 0.6, 0.8, 0.3, 0.7];

    for (int i = 0; i < bars.length; i++) {
      final x = i * (size.width / bars.length) + barWidth / 2;
      final barHeight = size.height * bars[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barHeight, barWidth * 0.6, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        rect,
        paint..color = color.withValues(alpha: i % 2 == 0 ? 1.0 : 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint1 = Paint()
      ..color = const Color(0xFF5B4FA3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    final paint2 = Paint()
      ..color = const Color(0xFF00BCD4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    final paint3 = Paint()
      ..color = const Color(0xFF2D3142)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      -math.pi / 2,
      math.pi * 0.7,
      false,
      paint1,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      -math.pi / 2 + math.pi * 0.7,
      math.pi * 0.8,
      false,
      paint2,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      -math.pi / 2 + math.pi * 1.5,
      math.pi * 0.5,
      false,
      paint3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
