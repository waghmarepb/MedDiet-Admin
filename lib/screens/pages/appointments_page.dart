import 'package:flutter/material.dart';
import 'package:meddiet/constants/app_colors.dart';
import 'package:meddiet/constants/api_config.dart';
import 'package:meddiet/constants/api_endpoints.dart';
import 'package:meddiet/services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  bool _isLoading = true;
  Map<String, List<Map<String, String>>> _liveAppointments = {};

  @override
  void initState() {
    super.initState();
    _fetchLiveAppointments();
  }

  Future<void> _fetchLiveAppointments() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

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
          final List appointments = data['data'];
          final Map<String, List<Map<String, String>>> grouped = {};

          for (var apt in appointments) {
            // Format date from DB (yyyy-MM-dd)
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

              // Format time HH:mm:ss to hh:mm AM/PM
              String formattedTime = apt['appointment_time']?.toString() ?? '';
              try {
                if (formattedTime.isNotEmpty) {
                  final parts = formattedTime.split(':');
                  if (parts.length >= 2) {
                    int hour = int.parse(parts[0]);
                    int minute = int.parse(parts[1]);
                    final period = hour >= 12 ? 'PM' : 'AM';
                    final displayHour = hour > 12
                        ? hour - 12
                        : (hour == 0 ? 12 : hour);
                    formattedTime =
                        '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
                  }
                }
              } catch (e) {
                debugPrint('Error formatting time: $e');
              }

              grouped[dateKey]!.add({
                'time': formattedTime,
                'title':
                    (apt['description'] != null &&
                        apt['description'].toString().isNotEmpty)
                    ? apt['description'].toString()
                    : 'General Consultation',
                'doctor':
                    'You', // In admin panel, doctor is usually the logged in one
                'patient': apt['patient_name']?.toString() ?? 'Patient',
                'image':
                    apt['profile_image']?.toString() ??
                    'https://i.pravatar.cc/150',
                'status': apt['status']?.toString() ?? 'pending',
              });
            }
          }

          if (mounted) {
            setState(() {
              _liveAppointments = grouped;
              _isLoading = false;
            });
          }
        }
      } else {
        throw Exception('Failed to load appointments');
      }
    } catch (e) {
      debugPrint('Error fetching live appointments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _fetchLiveAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isLargeScreen = constraints.maxWidth > 1000;
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              if (isLargeScreen)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: _buildCalendarCard(),
                                    ),
                                    const SizedBox(width: 32),
                                    Expanded(
                                      flex: 5,
                                      child: _buildScheduleCard(),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    _buildCalendarCard(),
                                    const SizedBox(height: 32),
                                    _buildScheduleCard(),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Admin',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.textGrey,
                  ),
                  Text(
                    'Appointments',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Appointments',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage and track patient consultations.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  'New Appointment',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 15,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: 32),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMMM').format(_focusedMonth),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              DateFormat('yyyy').format(_focusedMonth),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildIconButton(Icons.chevron_left, () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month - 1,
                );
              });
            }),
            const SizedBox(width: 12),
            _buildIconButton(Icons.chevron_right, () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month + 1,
                );
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;

    return Column(
      children: [
        Row(
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((
            day,
          ) {
            return Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    day.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        ...List.generate((daysInMonth + firstDayOfMonth + 6) ~/ 7, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - firstDayOfMonth + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 70));
              }

              final date = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                dayNumber,
              );
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final isToday = DateUtils.isSameDay(date, DateTime.now());
              final isSelected = DateUtils.isSameDay(date, _selectedDate);
              final hasAppointments = _liveAppointments.containsKey(dateStr);

              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 70,
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isToday
                          ? AppColors.primary.withValues(alpha: 0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? null
                          : isToday
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            )
                          : Border.all(
                              color: hasAppointments
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                            ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (hasAppointments && !isSelected)
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? AppColors.primary
                                      : AppColors.primary.withValues(
                                          alpha: 0.5,
                                        ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  Widget _buildScheduleCard() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final appointments = _liveAppointments[dateStr] ?? [];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  DateFormat('MMM d').format(_selectedDate),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (appointments.isEmpty)
            _buildEmptyState()
          else
            ...appointments.map((apt) => _buildAppointmentCard(apt)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 40,
                color: AppColors.textGrey.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No appointments scheduled',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select another day or add a new one.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, String> apt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: apt['image']!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[50],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apt['patient']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        apt['title']!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: apt['status']!),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border(
                top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      apt['time']!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 14,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Dr. ${apt['doctor']!.replaceAll('Dr. ', '')}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
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
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isConfirmed = status.toLowerCase() == 'confirmed';
    final Color color = isConfirmed ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
