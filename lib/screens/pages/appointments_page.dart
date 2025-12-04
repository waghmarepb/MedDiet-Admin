import 'package:flutter/material.dart';
import 'package:meddiet/constants/app_colors.dart';
import 'package:meddiet/widgets/common_header.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  int selectedDay = 13; // Default to today
  String selectedMonth = 'November';
  int selectedYear = 2024;

  // Sample appointment data for different dates
  final Map<int, List<Map<String, String>>> appointmentsByDate = {
    1: [
      {'time': '09:00 AM', 'title': 'General Checkup', 'doctor': 'Dr. Smith', 'patient': 'John Doe'},
      {'time': '11:00 AM', 'title': 'Follow-up Visit', 'doctor': 'Dr. Williams', 'patient': 'Jane Smith'},
    ],
    4: [
      {'time': '10:00 AM', 'title': 'Dental Consultation', 'doctor': 'Dr. Brown', 'patient': 'Mike Johnson'},
      {'time': '02:00 PM', 'title': 'Physical Therapy', 'doctor': 'Dr. Taylor', 'patient': 'Sarah Wilson'},
      {'time': '04:00 PM', 'title': 'Cardiology Checkup', 'doctor': 'Dr. Anderson', 'patient': 'Robert Lee'},
    ],
    7: [
      {'time': '09:30 AM', 'title': 'Vaccination', 'doctor': 'Dr. Martinez', 'patient': 'Emily Davis'},
      {'time': '01:00 PM', 'title': 'Lab Results Review', 'doctor': 'Dr. Garcia', 'patient': 'David Chen'},
    ],
    10: [
      {'time': '08:00 AM', 'title': 'Pediatric Consultation', 'doctor': 'Dr. Rodriguez', 'patient': 'Lisa Brown'},
      {'time': '10:30 AM', 'title': 'Nutrition Counseling', 'doctor': 'Dr. Wilson', 'patient': 'Tom Harris'},
      {'time': '03:00 PM', 'title': 'Dermatology Appointment', 'doctor': 'Dr. Lee', 'patient': 'Anna Martinez'},
    ],
    13: [
      {'time': '09:00 AM', 'title': 'Blood Pressure Check', 'doctor': 'Dr. Williams', 'patient': 'James White'},
      {'time': '10:00 AM', 'title': 'Diabetes Management', 'doctor': 'Dr. Davis', 'patient': 'Mary Johnson'},
      {'time': '11:30 AM', 'title': 'Orthopedic Consultation', 'doctor': 'Dr. Thompson', 'patient': 'Chris Anderson'},
      {'time': '01:00 PM', 'title': 'Eye Examination', 'doctor': 'Dr. Moore', 'patient': 'Patricia Taylor'},
      {'time': '02:30 PM', 'title': 'Mental Health Session', 'doctor': 'Dr. Jackson', 'patient': 'Daniel Martin'},
      {'time': '04:00 PM', 'title': 'Physiotherapy', 'doctor': 'Dr. White', 'patient': 'Jennifer Garcia'},
    ],
    16: [
      {'time': '09:00 AM', 'title': 'Allergy Testing', 'doctor': 'Dr. Miller', 'patient': 'Kevin Brown'},
      {'time': '11:00 AM', 'title': 'Surgery Follow-up', 'doctor': 'Dr. Jones', 'patient': 'Laura Wilson'},
      {'time': '02:00 PM', 'title': 'X-Ray Review', 'doctor': 'Dr. Clark', 'patient': 'Steven Lee'},
    ],
  };

  List<Map<String, String>> get selectedDayAppointments {
    return appointmentsByDate[selectedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          children: [
            CommonHeader(
              title: 'Appointments',
              action: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Schedule Appointment',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildCalendar(),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: _buildAppointmentsList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'November 2024',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left, size: 18),
                      onPressed: () {},
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right, size: 18),
                      onPressed: () {},
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Week days header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) {
              return Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Calendar grid - 5 weeks
          ...List.generate(5, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  int dateNumber = weekIndex * 7 + dayIndex + 1;
                  if (dateNumber > 30) return Expanded(child: SizedBox());
                  
                  bool hasAppointment = appointmentsByDate.containsKey(dateNumber);
                  bool isSelected = dateNumber == selectedDay;
                  
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedDay = dateNumber;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                          color: isSelected 
                            ? AppColors.primary 
                            : hasAppointment 
                                ? AppColors.primary.withOpacity(0.1) 
                                : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                          border: hasAppointment && !isSelected
                            ? Border.all(color: AppColors.primary, width: 1.5)
                            : Border.all(color: const Color(0xFFE5E5E5), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          '$dateNumber',
                          style: TextStyle(
                              color: isSelected 
                                ? Colors.white 
                                : const Color(0xFF2D3142),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    final appointments = selectedDayAppointments;
    
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedDay == 13 ? 'Today\'s Schedule' : 'Schedule',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              Text(
                '$selectedMonth $selectedDay, $selectedYear',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (appointments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No appointments scheduled',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...appointments.map((appointment) {
            return _buildAppointmentItem(
                appointment['time']!,
                appointment['title']!,
                appointment['doctor']!,
                appointment['patient']!,
            );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(String time, String title, String doctor, String patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                Text(
                  time,
                  style: const TextStyle(
                        fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      patient,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.medical_services_outlined,
                      size: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                    const SizedBox(width: 4),
                Text(
                  doctor,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Scheduled',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

