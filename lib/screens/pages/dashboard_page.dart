import 'package:flutter/material.dart';
import 'package:meddiet/services/auth_service.dart';
import 'package:meddiet/services/analytics_service.dart';
import 'package:meddiet/constants/api_config.dart';
import 'package:meddiet/constants/api_endpoints.dart';
import 'package:meddiet/constants/app_colors.dart';
// import 'package:meddiet/screens/main_layout.dart'; // Unused after hiding notifications
import 'package:meddiet/widgets/common_header.dart';
import 'package:meddiet/widgets/shimmer_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';

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
  List<Map<String, dynamic>> _appointments = [];
  int _totalPatients = 0;
  AnalyticsData? _analyticsData;
  bool _isLoading = true;
  bool _isLoadingAppointments = true;

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
    _fetchAppointments();
  }

  /// Generate the current week days for calendar display
  void _generateWeekDays() {
    final now = _selectedDate;
    // DateTime.weekday: Monday=1, Tuesday=2, ..., Sunday=7
    // We want Sunday=0, Monday=1, ..., Saturday=6
    final weekday = now.weekday == 7 ? 0 : now.weekday;
    final startOfWeek = now.subtract(Duration(days: weekday));
    _weekDays = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2D3142),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _currentMonth = picked;
        _generateWeekDays();
      });
    }
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoadingAppointments = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.doctorAppointments}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _appointments = List<Map<String, dynamic>>.from(data['data']);
            _isLoadingAppointments = false;
          });
        }
      } else {
        setState(() => _isLoadingAppointments = false);
      }
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      setState(() => _isLoadingAppointments = false);
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(
          Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patients}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AuthService.token}',
          },
        ),
        AnalyticsService.fetchAnalytics(),
      ]);

      final response = results[0] as http.Response;
      final analytics = results[1] as AnalyticsData;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _patients = List<Map<String, dynamic>>.from(data['data']);
            _totalPatients = _patients.length;
            _analyticsData = analytics;
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
    final doctorName = AuthService.doctorData?['name'] ?? 'Doctor';
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
            CommonHeader(
              title: '${_getGreeting()} $doctorName!',
              showAvatar: true,
            ),
            // Main content area with responsive layout
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Determine if we should use mobile/tablet/desktop layout
                  final isDesktop = constraints.maxWidth > 1200;
                  final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
                  
                  if (isDesktop) {
                    // Desktop: 2 column layout
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Center column - Transactions & Summary
                        Expanded(flex: 7, child: _buildCenterColumn()),
                        // Divider line
                        Container(
                          width: 1,
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        // Right column - Calendar & Appointments
                        Expanded(flex: 3, child: _buildRightSidebar()),
                      ],
                    );
                  } else if (isTablet) {
                    // Tablet: 2 column layout with adjusted proportions
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: _buildCenterColumn()),
                        Container(
                          width: 1,
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        Expanded(flex: 4, child: _buildRightSidebar()),
                      ],
                    );
                  } else {
                    // Mobile: Single column layout
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCenterColumn(),
                          const Divider(height: 1),
                          _buildRightSidebar(),
                        ],
                      ),
                    );
                  }
                },
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

  Widget _buildCenterColumn() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive padding based on screen width
        final horizontalPadding = constraints.maxWidth > 1200 
            ? 30.0 
            : constraints.maxWidth > 768 
                ? 20.0 
                : 16.0;
        
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding, 
            24, 
            horizontalPadding, 
            30,
          ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleFontSize = constraints.maxWidth > 768 ? 22.0 : 18.0;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'MedDiet Insights & Summary',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3142),
                    ),
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
        LayoutBuilder(
          builder: (context, constraints) {
            // Adjust card size based on available width
            final cardWidth = constraints.maxWidth > 1200 
                ? 280.0 
                : constraints.maxWidth > 768 
                    ? 240.0 
                    : 200.0;
            
            return SizedBox(
              height: 220,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildImageCard(
                    'Healthy Salads',
                    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=2070&auto=format&fit=crop',
                    'Recommended for Heart Health',
                    cardWidth,
                  ),
                  const SizedBox(width: 20),
                  _buildImageCard(
                    'Olive Oil Benefits',
                    'https://images.unsplash.com/photo-1473093226795-af9932fe5856?q=80&w=2012&auto=format&fit=crop',
                    'Key Ingredient in MedDiet',
                    cardWidth,
                  ),
                  const SizedBox(width: 20),
                  _buildImageCard(
                    'Fresh Seafood',
                    'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=1974&auto=format&fit=crop',
                    'Weekly Protein Source',
                    cardWidth,
                  ),
                  const SizedBox(width: 20),
                  _buildImageCard(
                    'Nuts & Grains',
                    'https://images.unsplash.com/photo-1511690656952-34342bb7c2f2?q=80&w=2064&auto=format&fit=crop',
                    'Essential Healthy Fats',
                    cardWidth,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsive grid for summary cards
            final isWideScreen = constraints.maxWidth > 900;
            final isMediumScreen = constraints.maxWidth > 600;
            
            if (isWideScreen) {
              // Desktop: 4 cards in a row
              if (_isLoading) {
                return Row(
                  children: [
                    Expanded(child: ShimmerWidgets.summaryCardShimmer()),
                    const SizedBox(width: 16),
                    Expanded(child: ShimmerWidgets.summaryCardShimmer()),
                    const SizedBox(width: 16),
                    Expanded(child: ShimmerWidgets.summaryCardShimmer()),
                    const SizedBox(width: 16),
                    Expanded(child: ShimmerWidgets.chartShimmer(height: 200)),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Patients',
                      '$_totalPatients',
                      'Registered',
                      const Color(0xFF5B4FA3),
                      true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Active Plans',
                      '$_totalPatients',
                      'Active',
                      const Color(0xFF00BCD4),
                      false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'This Week',
                      '${_patients.where((p) => _isRecentPatient(p)).length}',
                      'New Patients',
                      const Color(0xFF5B4FA3),
                      false,
                      showBars: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPieChartCard()),
                ],
              );
            } else if (isMediumScreen) {
              // Tablet: 2 cards per row
              if (_isLoading) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: ShimmerWidgets.summaryCardShimmer()),
                        const SizedBox(width: 16),
                        Expanded(child: ShimmerWidgets.summaryCardShimmer()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: ShimmerWidgets.summaryCardShimmer()),
                        const SizedBox(width: 16),
                        Expanded(child: ShimmerWidgets.chartShimmer(height: 200)),
                      ],
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Patients',
                          '$_totalPatients',
                          'Registered',
                          const Color(0xFF5B4FA3),
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Active Plans',
                          '$_totalPatients',
                          'Active',
                          const Color(0xFF00BCD4),
                          false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'This Week',
                          '${_patients.where((p) => _isRecentPatient(p)).length}',
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
            } else {
              // Mobile: 1 card per row
              if (_isLoading) {
                return Column(
                  children: [
                    ShimmerWidgets.summaryCardShimmer(),
                    const SizedBox(height: 16),
                    ShimmerWidgets.summaryCardShimmer(),
                    const SizedBox(height: 16),
                    ShimmerWidgets.summaryCardShimmer(),
                    const SizedBox(height: 16),
                    ShimmerWidgets.chartShimmer(height: 200),
                  ],
                );
              }
              return Column(
                children: [
                  _buildSummaryCard(
                    'Total Patients',
                    '$_totalPatients',
                    'Registered',
                    const Color(0xFF5B4FA3),
                    true,
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryCard(
                    'Active Plans',
                    '$_totalPatients',
                    'Active',
                    const Color(0xFF00BCD4),
                    false,
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryCard(
                    'This Week',
                    '${_patients.where((p) => _isRecentPatient(p)).length}',
                    'New Patients',
                    const Color(0xFF5B4FA3),
                    false,
                    showBars: true,
                  ),
                  const SizedBox(height: 16),
                  _buildPieChartCard(),
                ],
              );
            }
          },
        ),
          ],
        );
      },
    );
  }

  Widget _buildImageCard(String title, String imageUrl, String subtitle, double width) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final titleFontSize = constraints.maxWidth > 768 ? 22.0 : 18.0;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Recent Patients (${_recentPatients.length})',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3142),
                    ),
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
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
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
      },
    );
  }

  Widget _buildRealUserItem(
    BuildContext context,
    String name,
    String email,
    String timeAgo,
    Color iconColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 500;
        final avatarSize = isSmallScreen ? 44.0 : 54.0;
        final nameFontSize = isSmallScreen ? 14.0 : 15.0;
        final emailFontSize = isSmallScreen ? 11.0 : 12.0;
        
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: emailFontSize,
                    color: const Color(0xFF9E9E9E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Registered $timeAgo',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: const Color(0xFFBDBDBD),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 14),
          Container(
            width: isSmallScreen ? 32 : 36,
            height: isSmallScreen ? 32 : 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: isSmallScreen ? 16 : 18,
            ),
          ),
            ],
          ),
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallCard = constraints.maxWidth < 200;
        final titleFontSize = isSmallCard ? 11.0 : 13.0;
        final amountFontSize = isSmallCard ? 20.0 : 26.0;
        final currencyFontSize = isSmallCard ? 10.0 : 11.0;
        final padding = isSmallCard ? 16.0 : 20.0;
        
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize, 
                        color: const Color(0xFF9E9E9E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.trending_up, 
                    color: Colors.green, 
                    size: isSmallCard ? 12 : 14,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                amount,
                style: TextStyle(
                  fontSize: amountFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3142),
                ),
              ),
              Text(
                currency,
                style: TextStyle(
                  fontSize: currencyFontSize, 
                  color: const Color(0xFFBDBDBD),
                ),
              ),
          const SizedBox(height: 20),
          SizedBox(
            height: isSmallCard ? 50 : 70,
            child: _isLoading || _analyticsData == null
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : showBars
                ? _buildMiniBarChart(color)
                : _buildMiniLineChart(color, showAreaChart),
          ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniBarChart(Color color) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10,
        barTouchData: BarTouchData(enabled: false),
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: _analyticsData!.weeklyGrowth.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY:
                    entry.value.count.toDouble() +
                    2, // Ensure some height for visual
                color: color,
                width: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMiniLineChart(Color color, bool isArea) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _analyticsData!.monthlyPatients.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
            }).toList(),
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: isArea,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallCard = constraints.maxWidth < 200;
        final chartSize = isSmallCard ? 80.0 : 100.0;
        final padding = isSmallCard ? 16.0 : 20.0;
        final titleFontSize = isSmallCard ? 11.0 : 13.0;
        
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Plans',
                    style: TextStyle(
                      fontSize: titleFontSize, 
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                  Icon(
                    Icons.trending_up, 
                    color: Colors.green, 
                    size: isSmallCard ? 12 : 14,
                  ),
                ],
              ),
              SizedBox(height: isSmallCard ? 16 : 20),
              Center(
                child: SizedBox(
                  width: chartSize,
                  height: chartSize,
              child: _isLoading || _analyticsData == null
                  ? const CircularProgressIndicator()
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: isSmallCard ? 25 : 30,
                        sections: _analyticsData!.planBreakdown
                            .asMap()
                            .entries
                            .map((entry) {
                              final colors = [
                                const Color(0xFF5B4FA3),
                                const Color(0xFF00BCD4),
                                const Color(0xFF2D3142),
                                const Color(0xFF8B5CF6),
                              ];
                              return PieChartSectionData(
                                color: colors[entry.key % colors.length],
                                value: entry.value.value,
                                title: '',
                                radius: isSmallCard ? 8 : 10,
                              );
                            })
                            .toList(),
                      ),
                    ),
            ),
          ),
          SizedBox(height: isSmallCard ? 8 : 12),
          Center(
            child: Text(
              'User\nDistribution',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallCard ? 10 : 11,
                color: const Color(0xFF9E9E9E),
                height: 1.3,
              ),
            ),
          ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRightSidebar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if sidebar is in mobile view (full width)
        final isMobileView = constraints.maxWidth > 600;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: isMobileView 
                ? const BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  )
                : BorderRadius.zero,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobileView ? 10 : 16, 
              24, 
              isMobileView ? 24 : 16, 
              30,
            ),
            child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(12),
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
            padding: EdgeInsets.only(
              left: isMobileView ? 24 : 16,
              right: isMobileView ? 24 : 16,
              bottom: 24,
              top: 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar Header
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobileView ? 18 : 12,
                    vertical: isMobileView ? 14 : 10,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'MY CALENDAR',
                          style: TextStyle(
                            fontSize: isMobileView ? 11 : 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: isMobileView ? 1.5 : 1.0,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobileView ? 10 : 8,
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
                                style: TextStyle(
                                  fontSize: isMobileView ? 12 : 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: isMobileView ? 4 : 3),
                              Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: isMobileView ? 14 : 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Week Days Row
                Row(
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
                const SizedBox(height: 16),
                // Calendar Days Row
                Row(
                  children: _weekDays.map((date) {
                    final isSelected =
                        date.day == _selectedDate.day &&
                        date.month == _selectedDate.month &&
                        date.year == _selectedDate.year;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
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
                                date.day.toString(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
                  child: _isLoadingAppointments
                      ? ListView(
                          children: [
                            ShimmerWidgets.listItemShimmer(),
                            ShimmerWidgets.listItemShimmer(),
                            ShimmerWidgets.listItemShimmer(),
                          ],
                        )
                      : Builder(
                          builder: (context) {
                            final filteredAppointments = _appointments.where((
                              apt,
                            ) {
                              try {
                                final aptDate = DateTime.parse(
                                  apt['appointment_date'],
                                );
                                return aptDate.year == _selectedDate.year &&
                                    aptDate.month == _selectedDate.month &&
                                    aptDate.day == _selectedDate.day;
                              } catch (e) {
                                return false;
                              }
                            }).toList();

                            if (filteredAppointments.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: Text(
                                    'No appointments for this day',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: filteredAppointments.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final apt = filteredAppointments[index];
                                final rawTime =
                                    apt['appointment_time'] ?? '--:--';
                                // Format time to remove seconds (HH:mm:ss -> HH:mm)
                                final time =
                                    rawTime.toString().split(':').length >= 2
                                    ? '${rawTime.toString().split(':')[0]}:${rawTime.toString().split(':')[1]}'
                                    : rawTime;

                                final patientName =
                                    apt['patient_name'] ?? 'Unknown Patient';
                                final description =
                                    apt['description']?.toString() ?? '';
                                final aptReason =
                                    apt['reason']?.toString() ?? '';

                                final reason = description.isNotEmpty
                                    ? description
                                    : (aptReason.isNotEmpty
                                          ? aptReason
                                          : 'General Consultation');

                                final status = apt['status'] ?? 'pending';
                                final profileImage = apt['profile_image'];

                                Color dotColor;
                                switch (status.toLowerCase()) {
                                  case 'completed':
                                    dotColor = const Color(0xFF10B981);
                                    break;
                                  case 'cancelled':
                                    dotColor = Colors.red;
                                    break;
                                  default:
                                    dotColor = const Color(0xFFF59E0B);
                                }

                                return _buildAppointmentItem(
                                  time,
                                  patientName,
                                  reason,
                                  dotColor,
                                  status,
                                  profileImage,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildWeekDay(String day) {
    return Expanded(
      child: Center(
        child: Text(
          day,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
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

  Widget _buildAppointmentItem(
    String time,
    String patientName,
    String reason,
    Color dotColor,
    String status,
    String? profileImage,
  ) {
    final bool isCompleted = status.toLowerCase() == 'completed';
    final bool isCancelled = status.toLowerCase() == 'cancelled';
    final Color badgeColor = isCompleted
        ? const Color(0xFF10B981)
        : isCancelled
        ? Colors.red
        : const Color(0xFFF59E0B);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 300;
        final avatarSize = isSmallScreen ? 36.0 : 44.0;
        final nameFontSize = isSmallScreen ? 12.0 : 14.0;
        final reasonFontSize = isSmallScreen ? 10.0 : 11.0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                child: Row(
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: profileImage != null && profileImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: profileImage,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Icon(
                              Icons.person,
                              color: const Color(0xFF6366F1),
                              size: isSmallScreen ? 18 : 24,
                            ),
                          )
                        : Icon(
                            Icons.person, 
                            color: const Color(0xFF6366F1),
                            size: isSmallScreen ? 18 : 24,
                          ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                          fontSize: nameFontSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reason,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: reasonFontSize,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isSmallScreen ? 4 : 5,
                        height: isSmallScreen ? 4 : 5,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 6),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: isSmallScreen ? 8 : 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12, 
                  vertical: 8,
                ),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(top: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: isSmallScreen ? 12 : 14,
                      color: const Color(0xFF6366F1),
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 6),
                    Text(
                      time,
                      style: TextStyle(
                        color: const Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 11 : 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: isSmallScreen ? 10 : 12,
                      color: Colors.grey[400],
                    ),
                    SizedBox(width: isSmallScreen ? 3 : 4),
                    Text(
                      'Dr. You',
                      style: TextStyle(
                        color: const Color(0xFF6B7280),
                        fontSize: isSmallScreen ? 10 : 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
            ],
          ),
        );
      },
    );
  }
}
