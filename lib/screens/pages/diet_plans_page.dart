import 'package:flutter/material.dart';
import 'package:meddiet/constants/app_colors.dart';
import 'package:meddiet/widgets/common_header.dart';

class DietPlansPage extends StatefulWidget {
  const DietPlansPage({super.key});

  @override
  State<DietPlansPage> createState() => _DietPlansPageState();
}

class _DietPlansPageState extends State<DietPlansPage> {
  String _selectedFilter = 'All';
  final List<String> filters = ['All', 'Active', 'Inactive', 'Archived'];

  // Sample diet plans data
  final List<Map<String, dynamic>> dietPlans = [
    {
      'name': 'Keto Plan',
      'duration': '30 days',
      'patients': 45,
      'status': 'Active',
      'color': AppColors.primary,
      'icon': Icons.restaurant_menu,
      'description': 'Low-carb ketogenic diet',
      'rating': 4.8,
    },
    {
      'name': 'Mediterranean',
      'duration': '45 days',
      'patients': 67,
      'status': 'Active',
      'color': AppColors.accent,
      'icon': Icons.local_dining,
      'description': 'Heart-healthy Mediterranean',
      'rating': 4.9,
    },
    {
      'name': 'Vegan Plan',
      'duration': '60 days',
      'patients': 34,
      'status': 'Active',
      'color': AppColors.success,
      'icon': Icons.eco,
      'description': 'Plant-based nutrition',
      'rating': 4.6,
    },
    {
      'name': 'Low Sodium',
      'duration': '28 days',
      'patients': 56,
      'status': 'Active',
      'color': AppColors.info,
      'icon': Icons.favorite,
      'description': 'Heart & blood pressure care',
      'rating': 4.7,
    },
    {
      'name': 'Diabetes Control',
      'duration': '90 days',
      'patients': 82,
      'status': 'Active',
      'color': Color(0xFFF97316),
      'icon': Icons.health_and_safety,
      'description': 'Blood sugar management',
      'rating': 4.9,
    },
    {
      'name': 'Gluten-Free',
      'duration': '35 days',
      'patients': 23,
      'status': 'Inactive',
      'color': Color(0xFFA855F7),
      'icon': Icons.no_meeting_room,
      'description': 'Celiac-friendly nutrition',
      'rating': 4.5,
    },
    {
      'name': 'Weight Loss',
      'duration': '42 days',
      'patients': 91,
      'status': 'Active',
      'color': Color(0xFF06B6D4),
      'icon': Icons.trending_down,
      'description': 'Calorie-controlled program',
      'rating': 4.8,
    },
    {
      'name': 'Muscle Gain',
      'duration': '56 days',
      'patients': 38,
      'status': 'Active',
      'color': Color(0xFFEC4899),
      'icon': Icons.fitness_center,
      'description': 'High-protein diet',
      'rating': 4.7,
    },
    {
      'name': 'IBS Management',
      'duration': '40 days',
      'patients': 19,
      'status': 'Inactive',
      'color': Color(0xFF8B5CF6),
      'icon': Icons.healing,
      'description': 'Gut-friendly nutrition',
      'rating': 4.4,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredPlans = _selectedFilter == 'All'
        ? dietPlans
        : dietPlans.where((plan) => plan['status'] == _selectedFilter).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          children: [
            // Header with action button
            CommonHeader(
              title: 'Diet Plans',
              action: _buildCreateButton(),
            ),
            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Row(
                children: [
                  Text(
                    'Filter by Status:',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() => _selectedFilter = filter);
                              },
                              backgroundColor: Colors.transparent,
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Table view of plans
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Showing ${filteredPlans.length} plan${filteredPlans.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Table Header
                    _buildTableHeader(),
                    const SizedBox(height: 12),
                    // Table Body - List of plans
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredPlans.length,
                      separatorBuilder: (context, index) => Divider(
                        color: AppColors.border,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        return _buildTableRow(context, filteredPlans[index], index);
                      },
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

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Plan Name',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Description',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Duration',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Patients',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Rating',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Status',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Action',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, Map<String, dynamic> plan, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 30)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: index % 2 == 0 ? Colors.white : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: AppColors.border.withOpacity(0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showPlanDetails(context, plan),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [plan['color'], plan['color'].withOpacity(0.5)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          plan['icon'],
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        plan['name'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    plan['description'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    plan['duration'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${plan['patients']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        plan['rating'].toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: plan['color'].withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: plan['color'].withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        plan['status'],
                        style: TextStyle(
                          color: plan['color'],
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        Icons.edit,
                        Colors.blue,
                        () {
                          _showSnackBar('${plan['name']} opened for editing');
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        Icons.delete,
                        Colors.red,
                        () {
                          _showSnackBar('${plan['name']} deleted');
                        },
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

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCreatePlanDialog(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Create New Plan',
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
    );
  }

  void _showCreatePlanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create New Diet Plan',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Plan Name',
                hintText: 'e.g., Custom Keto Plan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Plan description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Diet plan created successfully!');
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPlanDetails(BuildContext context, Map<String, dynamic> plan) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [plan['color'], plan['color'].withOpacity(0.6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    plan['icon'],
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['name'],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan['description'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailColumn('Duration', plan['duration']),
                _buildDetailColumn('Patients', '${plan['patients']}'),
                _buildDetailColumn('Rating', '${plan['rating']}⭐'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSnackBar('${plan['name']} opened for editing');
                    },
                    child: const Text('Edit Plan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

