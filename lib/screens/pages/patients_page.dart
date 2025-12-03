import 'package:flutter/material.dart';
import 'package:meddiet/constants/app_colors.dart';
import 'package:meddiet/widgets/common_header.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  // Sample patient data
  final List<Map<String, dynamic>> patients = const [
    {
      'name': 'Sarah Johnson',
      'id': 'PT-001',
      'status': 'Active',
      'plan': 'Weight Loss Program',
      'phone': '+1 234-567-8901',
      'lastVisit': '2 days ago',
      'age': 32,
    },
    {
      'name': 'Michael Chen',
      'id': 'PT-002',
      'status': 'Scheduled',
      'plan': 'Diabetes Management',
      'phone': '+1 234-567-8902',
      'lastVisit': '5 days ago',
      'age': 45,
    },
    {
      'name': 'Emma Williams',
      'id': 'PT-003',
      'status': 'New',
      'plan': 'Heart Healthy Diet',
      'phone': '+1 234-567-8903',
      'lastVisit': 'Today',
      'age': 58,
    },
    {
      'name': 'James Rodriguez',
      'id': 'PT-004',
      'status': 'Active',
      'plan': 'Sports Nutrition',
      'phone': '+1 234-567-8904',
      'lastVisit': '1 day ago',
      'age': 28,
    },
    {
      'name': 'Olivia Brown',
      'id': 'PT-005',
      'status': 'Active',
      'plan': 'Vegan Diet Plan',
      'phone': '+1 234-567-8905',
      'lastVisit': '3 days ago',
      'age': 35,
    },
    {
      'name': 'David Martinez',
      'id': 'PT-006',
      'status': 'Scheduled',
      'plan': 'Keto Diet',
      'phone': '+1 234-567-8906',
      'lastVisit': '1 week ago',
      'age': 41,
    },
    {
      'name': 'Sophia Taylor',
      'id': 'PT-007',
      'status': 'Active',
      'plan': 'Pregnancy Nutrition',
      'phone': '+1 234-567-8907',
      'lastVisit': 'Today',
      'age': 29,
    },
    {
      'name': 'Daniel Anderson',
      'id': 'PT-008',
      'status': 'New',
      'plan': 'General Wellness',
      'phone': '+1 234-567-8908',
      'lastVisit': 'Today',
      'age': 52,
    },
  ];

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
              title: 'All Patients',
              action: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Add New Patient',
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildSearchBar()),
                        const SizedBox(width: 16),
                        _buildFilterButton('All Status'),
                        const SizedBox(width: 12),
                        _buildFilterButton('Sort by'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    ...patients.map((patient) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPatientCard(
                          patient['name']!,
                          patient['id']!,
                          patient['status']!,
                          patient['plan']!,
                          patient['phone']!,
                          patient['lastVisit']!,
                          patient['age']!,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Total Patients', '247', Icons.people, AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Active Plans', '189', Icons.assignment_turned_in, AppColors.success),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('New This Month', '24', Icons.person_add, AppColors.accent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Scheduled', '34', Icons.schedule, AppColors.info),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF9E9E9E)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: const [
          Icon(Icons.search, color: Color(0xFF9E9E9E), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search by name, ID or phone...',
              style: TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(
    String name,
    String id,
    String status,
    String plan,
    String phone,
    String lastVisit,
    int age,
  ) {
    Color statusColor;
    Color statusBgColor;
    
    switch (status) {
      case 'Active':
        statusColor = AppColors.success;
        statusBgColor = AppColors.success.withOpacity(0.1);
        break;
      case 'Scheduled':
        statusColor = AppColors.info;
        statusBgColor = AppColors.info.withOpacity(0.1);
        break;
      case 'New':
        statusColor = AppColors.accent;
        statusBgColor = AppColors.accent.withOpacity(0.1);
        break;
      default:
        statusColor = AppColors.primary;
        statusBgColor = AppColors.primary.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                name.split(' ').map((e) => e[0]).join().toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Patient Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(Icons.badge_outlined, id),
                    const SizedBox(width: 16),
                    _buildInfoChip(Icons.cake_outlined, '$age years'),
                    const SizedBox(width: 16),
                    _buildInfoChip(Icons.phone_outlined, phone),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.restaurant_menu, size: 14, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 6),
                    Text(
                      plan,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Icon(Icons.access_time, size: 14, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 6),
                    Text(
                      'Last visit: $lastVisit',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action Buttons
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.phone, size: 20),
                  color: AppColors.success,
                  onPressed: () {},
                  tooltip: 'Call',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.message, size: 20),
                  color: AppColors.info,
                  onPressed: () {},
                  tooltip: 'Message',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  color: Colors.white,
                  onPressed: () {},
                  tooltip: 'View Details',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}

