import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:meddiet/screens/user_details_page.dart';
import 'package:meddiet/screens/main_layout.dart';
import 'package:meddiet/constants/api_config.dart';
import 'package:meddiet/constants/api_endpoints.dart';
import 'package:meddiet/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // API data for appointments
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  bool _isLoadingAppointments = true;
  Map<String, List<Map<String, dynamic>>> _appointments = {};

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      if (!mounted) return;
      setState(() => _isLoadingAppointments = true);

      debugPrint('🔄 Fetching appointments from API...');
      debugPrint(
        '📍 API URL: ${ApiConfig.baseUrl}${ApiEndpoints.doctorAppointments}',
      );

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.doctorAppointments}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      debugPrint('📦 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ API Response: ${data['success']}');
        debugPrint('📊 Data count: ${data['data']?.length ?? 0}');

        if (data['success'] == true && data['data'] != null) {
          final List appointments = data['data'];
          final Map<String, List<Map<String, dynamic>>> grouped = {};

          for (var apt in appointments) {
            String dateKey = '';
            if (apt['appointment_date'] != null) {
              DateTime date = DateTime.parse(
                apt['appointment_date'].toString(),
              );
              dateKey = DateFormat('yyyy-MM-dd').format(date);
            }

            if (dateKey.isNotEmpty) {
              if (!grouped.containsKey(dateKey)) {
                grouped[dateKey] = [];
              }

              // Format time
              String formattedTime = apt['appointment_time']?.toString() ?? '';
              try {
                if (formattedTime.isNotEmpty) {
                  final parts = formattedTime.split(':');
                  if (parts.length >= 2) {
                    int hour = int.parse(parts[0]);
                    int minute = int.parse(parts[1]);
                    final period = hour >= 12 ? 'pm' : 'am';
                    final displayHour = hour > 12
                        ? hour - 12
                        : (hour == 0 ? 12 : hour);
                    formattedTime =
                        '$displayHour:${minute.toString().padLeft(2, '0')} $period';
                  }
                }
              } catch (e) {
                debugPrint('⚠️ Error formatting time: $e');
              }

              grouped[dateKey]!.add({
                'time': formattedTime,
                'title':
                    (apt['description'] != null &&
                        apt['description'].toString().isNotEmpty)
                    ? apt['description'].toString()
                    : 'Consultation with ${apt['patient_name']?.toString() ?? 'Patient'}',
                'patient': apt['patient_name']?.toString() ?? 'Patient',
                'status': apt['status']?.toString() ?? 'pending',
              });
            }
          }

          debugPrint(
            '📅 Grouped appointments by date: ${grouped.keys.length} dates',
          );
          for (var key in grouped.keys) {
            debugPrint('  - $key: ${grouped[key]!.length} appointments');
          }

          if (mounted) {
            setState(() {
              _appointments = grouped;
              _isLoadingAppointments = false;
            });
            debugPrint('✅ Appointments loaded successfully!');
          }
        } else {
          debugPrint('⚠️ No appointments data in response');
          if (mounted) {
            setState(() {
              _appointments = {};
              _isLoadingAppointments = false;
            });
          }
        }
      } else {
        debugPrint('❌ API Error: Status ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to load appointments: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching appointments: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _appointments = {};
          _isLoadingAppointments = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MainLayout(
      child: Container(
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Good Evening Mikey!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          Row(
            children: [
              // Notification button hidden as per requirement
              // InkWell(
              //   onTap: () => MainLayout.openNotifications(context),
              //   child: Container(
              //     padding: const EdgeInsets.all(10),
              //     decoration: BoxDecoration(
              //       color: Colors.white,
              //       borderRadius: BorderRadius.circular(12),
              //       border: Border.all(color: const Color(0xFFE5E5E5)),
              //     ),
              //     child: Stack(
              //       clipBehavior: Clip.none,
              //       children: [
              //         const Icon(
              //           Icons.notifications_outlined,
              //           size: 18,
              //           color: Color(0xFF2D3142),
              //         ),
              //         Positioned(
              //           right: -2,
              //           top: -2,
              //           child: Container(
              //             width: 8,
              //             height: 8,
              //             decoration: const BoxDecoration(
              //               color: Colors.red,
              //               shape: BoxShape.circle,
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              // const SizedBox(width: 12),
              InkWell(
                onTap: () => MainLayout.openProfile(context),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFFDB777),
                  child: const Text(
                    'M',
                    style: TextStyle(
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
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransactionsSection(context),
              const SizedBox(height: 40),
              _buildQuickSummary(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'All Users',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 14),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: const Icon(Icons.arrow_forward_ios, size: 14),
                ),
              ],
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This Week Summary',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '1,13,650',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const Text(
                    ' INR',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFFBDBDBD),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  _buildSummaryIndicator(
                    '24,000',
                    'INR',
                    Icons.arrow_upward,
                    Colors.green,
                  ),
                  const SizedBox(width: 20),
                  _buildSummaryIndicator(
                    '5,324',
                    'INR',
                    Icons.arrow_downward,
                    Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTransactionItem(
                context,
                patientId: '1',
                title: 'Mike Taylor',
                subtitle: 'Patient - Diet Plan Active',
                location: 'Chicago, TX',
                iconColor: const Color(0xFF5B4FA3),
                icon: Icons.person,
              ),
              const SizedBox(height: 12),
              _buildTransactionItem(
                context,
                patientId: '2',
                title: 'Jack Green',
                subtitle: 'Patient - Consultation Scheduled',
                location: 'Oakland, CO',
                iconColor: const Color(0xFF00BCD4),
                icon: Icons.person,
              ),
              const SizedBox(height: 12),
              _buildTransactionItem(
                context,
                patientId: '3',
                title: 'Carmen Lewis',
                subtitle: 'Patient - New Registration',
                location: 'Milwaukee, CA',
                iconColor: const Color(0xFFFF9800),
                icon: Icons.person,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryIndicator(
    String amount,
    String currency,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          Text(
            ' $currency',
            style: const TextStyle(fontSize: 11, color: Color(0xFFBDBDBD)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context, {
    required String patientId,
    required String title,
    required String subtitle,
    required String location,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      UserDetailsPage(
                        patientId: patientId,
                        userName: title,
                        userStatus: subtitle,
                        userLocation: location,
                      ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);
                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            child: Container(
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
          ),
        ],
      ),
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
              'Quick Summary On Your Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Patients',
                '1,234',
                'INR',
                const Color(0xFF5B4FA3),
                true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Active Plans',
                '856',
                'INR',
                const Color(0xFF00BCD4),
                false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Consultations',
                '342',
                'INR',
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
                      Row(
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(_focusedMonth),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _focusedMonth = DateTime(
                                        _focusedMonth.year,
                                        _focusedMonth.month - 1,
                                      );
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _focusedMonth = DateTime(
                                        _focusedMonth.year,
                                        _focusedMonth.month + 1,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
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
                // Calendar Days Row - Show current week
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _buildWeekDays(),
                  ),
                ),
                const SizedBox(height: 32),
                // Date Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM, d').format(_selectedDate).toUpperCase(),
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
                      ? const Center(child: CircularProgressIndicator())
                      : _buildAppointmentsList(),
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

  /// Build week days dynamically based on focused month
  List<Widget> _buildWeekDays() {
    // Get the current week - Sunday to Saturday
    DateTime today = DateTime.now();

    // Calculate the start of the current week (Sunday)
    int daysToSubtract = today.weekday % 7; // Sunday = 0, Monday = 1, etc.
    DateTime startOfWeek = today.subtract(Duration(days: daysToSubtract));

    // Normalize to start of day
    startOfWeek = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    debugPrint(
      '📅 Building week: ${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(startOfWeek.add(const Duration(days: 6)))}',
    );

    List<Widget> weekDays = [];
    for (int i = 0; i < 7; i++) {
      DateTime date = startOfWeek.add(Duration(days: i));
      bool isSelected = DateUtils.isSameDay(date, _selectedDate);
      weekDays.add(_buildCalendarDay(date, isSelected));
    }
    return weekDays;
  }

  /// Updated calendar day widget to accept DateTime
  Widget _buildCalendarDay(DateTime date, bool isSelected) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final hasAppointments = _appointments.containsKey(dateStr);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: () {
            debugPrint('🖱️ Calendar day clicked: $dateStr');
            debugPrint(
              '📅 Previous selected: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
            );
            setState(() {
              _selectedDate = date;
            });
            debugPrint('✅ New selected date: $dateStr');
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
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
                if (hasAppointments && !isSelected)
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build appointments list for selected date
  Widget _buildAppointmentsList() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final appointments = _appointments[dateStr] ?? [];

    debugPrint('📅 Building appointments list for: $dateStr');
    debugPrint('📊 Total appointments for this date: ${appointments.length}');
    debugPrint('📚 All available dates: ${_appointments.keys.toList()}');

    if (appointments.isEmpty) {
      debugPrint('⚠️ No appointments found for $dateStr');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 40,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'No appointments',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected: $dateStr',
              style: TextStyle(fontSize: 10, color: Colors.grey[300]),
            ),
          ],
        ),
      );
    }

    debugPrint('✅ Displaying ${appointments.length} appointments');
    for (var apt in appointments) {
      debugPrint('  - ${apt['time']}: ${apt['title']}');
    }

    // Define color palette for appointments
    final colors = [
      const Color(0xFFEC4899), // Pink
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF10B981), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFF59E0B), // Orange
    ];

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: appointments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final apt = appointments[index];
        final color = colors[index % colors.length];
        return _buildAppointmentItem(
          apt['time'] ?? '',
          apt['title'] ?? 'Consultation',
          color,
        );
      },
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
