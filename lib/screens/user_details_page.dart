import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meddiet/screens/main_layout.dart';
import '../models/meal.dart';
import '../models/exercise.dart';
import '../models/supplement.dart';
import '../models/weight_target.dart';
import '../services/plan_service.dart';
import '../services/auth_service.dart';
import '../constants/api_config.dart';
import '../constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserDetailsPage extends StatefulWidget {
  final String patientId;
  final String userName;
  final String userStatus;
  final String userLocation;

  const UserDetailsPage({
    super.key,
    required this.patientId,
    required this.userName,
    required this.userStatus,
    required this.userLocation,
  });

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Data lists
  List<Meal> _meals = [];
  List<Exercise> _exercises = [];
  List<Supplement> _supplements = [];
  WeightTarget? _weightTarget;
  Map<String, dynamic>? _patientData;

  // Loading states
  bool _isLoadingMeals = false;
  bool _isLoadingExercises = false;
  bool _isLoadingSupplements = false;
  bool _isLoadingWeightTarget = false;
  bool _isLoadingPatient = false;

  // Selected date for meals and exercises
  DateTime _selectedDate = DateTime.now();

  // Follow-up form controllers
  final _weightController = TextEditingController();
  final _sleepController = TextEditingController();
  final _waterController = TextEditingController();
  final _notesController = TextEditingController();
  final _cravingsController = TextEditingController();
  String _energyLevel = '7';
  String _hungerLevel = '3';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _sleepController.dispose();
    _waterController.dispose();
    _notesController.dispose();
    _cravingsController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadPatientData(),
      _loadMeals(),
      _loadExercises(),
      _loadSupplements(),
      _loadWeightTarget(),
    ]);
  }

  Future<void> _loadPatientData() async {
    setState(() => _isLoadingPatient = true);
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiEndpoints.patientDetails}/${widget.patientId}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() => _patientData = data['data']);
        }
      }
    } catch (e) {
      debugPrint('Error loading patient data: $e');
    } finally {
      setState(() => _isLoadingPatient = false);
    }
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoadingMeals = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final response = await PlanService.getMeals(
      widget.patientId,
      date: dateStr,
    );
    if (response.success && response.data != null) {
      setState(() => _meals = response.data!);
    }
    setState(() => _isLoadingMeals = false);
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoadingExercises = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final response = await PlanService.getExercises(
      widget.patientId,
      date: dateStr,
    );
    if (response.success && response.data != null) {
      setState(() => _exercises = response.data!);
    }
    setState(() => _isLoadingExercises = false);
  }

  Future<void> _loadSupplements() async {
    setState(() => _isLoadingSupplements = true);
    final response = await PlanService.getSupplements(widget.patientId);
    if (response.success && response.data != null) {
      setState(() => _supplements = response.data!);
    }
    setState(() => _isLoadingSupplements = false);
  }

  Future<void> _loadWeightTarget() async {
    setState(() => _isLoadingWeightTarget = true);
    final response = await PlanService.getWeightTarget(widget.patientId);
    if (response.success) {
      setState(() => _weightTarget = response.data);
    }
    setState(() => _isLoadingWeightTarget = false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
              _buildHeader(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Expanded(child: _buildUserProfile()),
                            const SizedBox(height: 20),
                            Expanded(flex: 2, child: _buildInfoSection()),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Right Column
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildDateSelector(),
                              const SizedBox(height: 20),
                              _buildDietPlanSection(),
                              const SizedBox(height: 20),
                              _buildExerciseSection(),
                              const SizedBox(height: 20),
                              _buildSupplementsSection(),
                              const SizedBox(height: 20),
                              _buildWeightTargetSection(),
                              const SizedBox(height: 20),
                              _buildFollowUpSection(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 24),
            color: const Color(0xFF2D3142),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Patient Details',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              Text(
                'Patient ID: ${widget.patientId}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B4FA3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _loadMeals();
              _loadExercises();
            },
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                _loadMeals();
                _loadExercises();
              }
            },
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
              _loadMeals();
              _loadExercises();
            },
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person, size: 40, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 16),
          Text(
            widget.userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.userStatus,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                widget.userLocation,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Text(
                  'Patient ID',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${widget.patientId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Age',
                  _isLoadingPatient
                      ? '...'
                      : (_patientData?['age']?.toString() ?? 'N/A') +
                            (_patientData?['age'] != null ? ' yrs' : ''),
                  Icons.cake,
                  const Color(0xFF5B4FA3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Gender',
                  _isLoadingPatient
                      ? '...'
                      : (_patientData?['gender'] ?? 'N/A'),
                  Icons.person,
                  const Color(0xFF00BCD4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Blood',
                  _isLoadingPatient
                      ? '...'
                      : (_patientData?['blood_type'] ?? 'N/A'),
                  Icons.bloodtype,
                  const Color(0xFFE91E63),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Weight',
                  _isLoadingPatient
                      ? '...'
                      : (_patientData?['weight']?.toString() ?? 'N/A') +
                            (_patientData?['weight'] != null ? ' kg' : ''),
                  Icons.monitor_weight,
                  const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Height',
                  _isLoadingPatient
                      ? '...'
                      : (_patientData?['height']?.toString() ?? 'N/A') +
                            (_patientData?['height'] != null ? ' cm' : ''),
                  Icons.height,
                  const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'BMI',
                  '24.5',
                  Icons.analytics,
                  const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDietPlanSection() {
    int totalCalories = _meals.fold(
      0,
      (sum, meal) => sum + (meal.calories ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diet Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$totalCalories',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'kcal/day',
                          style: TextStyle(fontSize: 9, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _showAddMealDialog(),
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color(0xFF4CAF50),
                      size: 32,
                    ),
                    tooltip: 'Add Meal',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingMeals)
            const Center(child: CircularProgressIndicator())
          else if (_meals.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No meals planned for this date.\nTap + to add a meal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9E9E9E)),
                ),
              ),
            )
          else
            ..._meals.map(
              (meal) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildMealItem(meal),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMealItem(Meal meal) {
    Color color = _getMealColor(meal.mealType);
    IconData icon = _getMealIcon(meal.mealType);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Meal.getMealTypeDisplay(meal.mealType),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meal.mealName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          if (meal.time != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                meal.time!,
                style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '${meal.calories ?? 0}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 8,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              size: 20,
              color: Color(0xFF9E9E9E),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditMealDialog(meal);
              } else if (value == 'delete') {
                _confirmDeleteMeal(meal);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMealColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return const Color(0xFFFF9800);
      case 'mid_morning':
        return const Color(0xFF4CAF50);
      case 'lunch':
        return const Color(0xFF2196F3);
      case 'evening_snack':
        return const Color(0xFF9C27B0);
      case 'dinner':
        return const Color(0xFF5B4FA3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'mid_morning':
        return Icons.local_drink;
      case 'lunch':
        return Icons.lunch_dining;
      case 'evening_snack':
        return Icons.set_meal;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  Widget _buildExerciseSection() {
    int totalCaloriesBurn = _exercises.fold(
      0,
      (sum, ex) => sum + (ex.caloriesBurn ?? 0),
    );
    int totalMinutes = _exercises.fold(
      0,
      (sum, ex) => sum + (ex.durationMins ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Exercise Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$totalMinutes min • $totalCaloriesBurn kcal',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF5722),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _showAddExerciseDialog(),
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color(0xFFFF5722),
                      size: 32,
                    ),
                    tooltip: 'Add Exercise',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingExercises)
            const Center(child: CircularProgressIndicator())
          else if (_exercises.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No exercises planned for this date.\nTap + to add an exercise.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9E9E9E)),
                ),
              ),
            )
          else
            ..._exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildExerciseItem(exercise),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(Exercise exercise) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5722).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF5722).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_run,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                if (exercise.exerciseType != null)
                  Text(
                    Exercise.getExerciseTypeDisplay(exercise.exerciseType!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
              ],
            ),
          ),
          if (exercise.durationMins != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${exercise.durationMins} min',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF5722),
                ),
              ),
            ),
          const SizedBox(width: 8),
          if (exercise.caloriesBurn != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${exercise.caloriesBurn} kcal',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF5722),
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              size: 20,
              color: Color(0xFF9E9E9E),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditExerciseDialog(exercise);
              } else if (value == 'delete') {
                _confirmDeleteExercise(exercise);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupplementsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.medication,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Supplements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _showAddSupplementDialog(),
                icon: const Icon(
                  Icons.add_circle,
                  color: Color(0xFF9C27B0),
                  size: 32,
                ),
                tooltip: 'Add Supplement',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingSupplements)
            const Center(child: CircularProgressIndicator())
          else if (_supplements.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No supplements prescribed.\nTap + to add a supplement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9E9E9E)),
                ),
              ),
            )
          else
            ..._supplements.map(
              (supplement) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildSupplementItem(supplement),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupplementItem(Supplement supplement) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF9C27B0).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medication, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplement.supplementName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                if (supplement.dosage != null || supplement.frequency != null)
                  Text(
                    '${supplement.dosage ?? ''} ${supplement.frequency != null ? '• ${supplement.frequency}' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              size: 20,
              color: Color(0xFF9E9E9E),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditSupplementDialog(supplement);
              } else if (value == 'delete') {
                _confirmDeleteSupplement(supplement);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTargetSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00BCD4), Color(0xFF4DD0E1)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.monitor_weight,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Weight Target',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _showSetWeightTargetDialog(),
                icon: Icon(
                  _weightTarget == null ? Icons.add_circle : Icons.edit,
                  color: const Color(0xFF00BCD4),
                  size: 32,
                ),
                tooltip: _weightTarget == null
                    ? 'Set Weight Target'
                    : 'Edit Weight Target',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingWeightTarget)
            const Center(child: CircularProgressIndicator())
          else if (_weightTarget == null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No weight target set.\nTap + to set a weight target.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9E9E9E)),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildWeightCard(
                    'Current',
                    '${_weightTarget!.currentWeight} kg',
                    Icons.monitor_weight_outlined,
                    const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, color: Color(0xFF9E9E9E)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWeightCard(
                    'Target',
                    '${_weightTarget!.targetWeight} kg',
                    Icons.flag,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWeightCard(
                    'To Lose',
                    '${_weightTarget!.weightDifference.abs().toStringAsFixed(1)} kg',
                    _weightTarget!.isWeightLossGoal
                        ? Icons.trending_down
                        : Icons.trending_up,
                    _weightTarget!.isWeightLossGoal
                        ? const Color(0xFFFF5722)
                        : const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildWeightCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFollowup() async {
    final weight = double.tryParse(_weightController.text);
    final sleep = double.tryParse(_sleepController.text);
    final cravings = _cravingsController.text;
    final notes = _notesController.text;

    if (weight == null && sleep == null && cravings.isEmpty && notes.isEmpty) {
      _showSnackBar('Please enter at least one detail');
      return;
    }

    setState(() => _isLoadingPatient = true);

    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiEndpoints.patientFollowups(widget.patientId)}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
        body: jsonEncode({
          'date': DateTime.now().toIso8601String().split('T')[0],
          'weight': weight,
          'sleep_hours': sleep,
          'cravings': cravings,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        _showSnackBar('Follow-up recorded successfully');
        _weightController.clear();
        _sleepController.clear();
        _cravingsController.clear();
        _notesController.clear();
        _waterController.clear();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to save follow-up');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPatient = false);
      }
    }
  }

  Widget _buildFollowUpSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_turned_in,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Follow-up Form',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'Weight (kg)',
                  controller: _weightController,
                  icon: Icons.monitor_weight_outlined,
                  hint: 'e.g. 72.5',
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildFormField(
                  label: 'Sleep (hrs)',
                  controller: _sleepController,
                  icon: Icons.bedtime_outlined,
                  hint: 'e.g. 7',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'Water (L)',
                  controller: _waterController,
                  icon: Icons.water_drop_outlined,
                  hint: 'e.g. 3.5',
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Energy Level',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _energyLevel,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                          items:
                              List.generate(
                                10,
                                (index) => (index + 1).toString(),
                              ).map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _energyLevel = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hunger Level',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _hungerLevel,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                          items:
                              List.generate(
                                10,
                                (index) => (index + 1).toString(),
                              ).map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _hungerLevel = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildFormField(
                  label: 'Any Cravings?',
                  controller: _cravingsController,
                  icon: Icons.fastfood_outlined,
                  hint: 'e.g. Sweets',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildFormField(
            label: 'Diet Adherence & Notes',
            controller: _notesController,
            icon: Icons.notes,
            hint: 'How was the diet adherence? Any difficulties?',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoadingPatient ? null : _saveFollowup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _isLoadingPatient
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Follow-up',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9E9E9E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6366F1)),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF6366F1),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // DIALOG METHODS
  // ============================================

  void _showAddMealDialog() {
    _showMealDialog(null);
  }

  void _showEditMealDialog(Meal meal) {
    _showMealDialog(meal);
  }

  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF6366F1),
              onPrimary: Colors.white,
              onSurface: const Color(0xFF6366F1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (mounted) {
        setState(() {
          final now = DateTime.now();
          final dt = DateTime(
            now.year,
            now.month,
            now.day,
            picked.hour,
            picked.minute,
          );
          controller.text = DateFormat('HH:mm').format(dt);
        });
      }
    }
  }

  void _showMealDialog(Meal? meal) {
    final isEdit = meal != null;
    final nameController = TextEditingController(text: meal?.mealName ?? '');
    final descController = TextEditingController(text: meal?.description ?? '');
    final caloriesController = TextEditingController(
      text: meal?.calories?.toString() ?? '',
    );
    final timeController = TextEditingController(text: meal?.time ?? '');
    String selectedType = meal?.mealType ?? 'breakfast';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Meal' : 'Add Meal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Meal Type',
                  border: OutlineInputBorder(),
                ),
                items: Meal.mealTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(Meal.getMealTypeDisplay(type)),
                  );
                }).toList(),
                onChanged: (value) => selectedType = value!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Meal Name *',
                  hintText: 'e.g., Oats with fruits',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Calories',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: timeController,
                      readOnly: true,
                      onTap: () => _selectTime(context, timeController),
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        hintText: 'Select time',
                        suffixIcon: Icon(Icons.access_time, size: 20),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                debugPrint('❌ Validation failed: No meal name entered');
                _showSnackBar('Please enter meal name', isError: true);
                return;
              }

              final newMeal = Meal(
                mealType: selectedType,
                mealName: nameController.text,
                description: descController.text.isEmpty
                    ? null
                    : descController.text,
                calories: int.tryParse(caloriesController.text),
                time: timeController.text.isEmpty ? null : timeController.text,
                date: DateFormat('yyyy-MM-dd').format(_selectedDate),
              );

              Navigator.pop(context);

              try {
                if (isEdit) {
                  debugPrint(
                    '🍽️ Updating meal: ${meal.id} for patient: ${widget.patientId}',
                  );
                  final response = await PlanService.updateMeal(
                    widget.patientId,
                    meal.id.toString(),
                    newMeal,
                  );
                  if (response.success) {
                    debugPrint('✅ Meal updated successfully');
                    _showSnackBar('Meal updated successfully');
                    _loadMeals();
                  } else {
                    debugPrint('❌ Failed to update meal: ${response.message}');
                    _showSnackBar(response.message, isError: true);
                  }
                } else {
                  debugPrint(
                    '🍽️ Adding meal for patient: ${widget.patientId}',
                  );
                  debugPrint('📝 Meal data: ${newMeal.toJson()}');
                  final response = await PlanService.addMeal(
                    widget.patientId,
                    newMeal,
                  );
                  if (response.success) {
                    debugPrint('✅ Meal added successfully');
                    _showSnackBar('Meal added successfully');
                    _loadMeals();
                  } else {
                    debugPrint('❌ Failed to add meal: ${response.message}');
                    _showSnackBar(response.message, isError: true);
                  }
                }
              } catch (e, stackTrace) {
                debugPrint('❌ EXCEPTION in meal dialog: $e');
                debugPrint('Stack trace: $stackTrace');
                _showSnackBar('Error: $e', isError: true);
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMeal(Meal meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to delete "${meal.mealName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final response = await PlanService.deleteMeal(
                widget.patientId,
                meal.id.toString(),
              );
              if (response.success) {
                _showSnackBar('Meal deleted successfully');
                _loadMeals();
              } else {
                _showSnackBar(response.message, isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog() {
    _showExerciseDialog(null);
  }

  void _showEditExerciseDialog(Exercise exercise) {
    _showExerciseDialog(exercise);
  }

  void _showExerciseDialog(Exercise? exercise) {
    final isEdit = exercise != null;
    final nameController = TextEditingController(
      text: exercise?.exerciseName ?? '',
    );
    final durationController = TextEditingController(
      text: exercise?.durationMins?.toString() ?? '',
    );
    final caloriesController = TextEditingController(
      text: exercise?.caloriesBurn?.toString() ?? '',
    );
    final instructionsController = TextEditingController(
      text: exercise?.instructions ?? '',
    );
    String? selectedType = exercise?.exerciseType ?? 'cardio';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Exercise' : 'Add Exercise'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name *',
                  hintText: 'e.g., Morning Walk',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Exercise Type',
                  border: OutlineInputBorder(),
                ),
                items: Exercise.exerciseTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(Exercise.getExerciseTypeDisplay(type)),
                  );
                }).toList(),
                onChanged: (value) => selectedType = value,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (mins)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Calories Burn',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                _showSnackBar('Please enter exercise name', isError: true);
                return;
              }

              final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
              final newExercise = Exercise(
                exerciseName: nameController.text,
                exerciseType: selectedType,
                durationMins: int.tryParse(durationController.text),
                caloriesBurn: int.tryParse(caloriesController.text),
                instructions: instructionsController.text.isEmpty
                    ? null
                    : instructionsController.text,
                date: dateStr,
              );

              Navigator.pop(context);

              if (isEdit) {
                final response = await PlanService.updateExercise(
                  widget.patientId,
                  exercise.id.toString(),
                  newExercise,
                );
                if (response.success) {
                  _showSnackBar('Exercise updated successfully');
                  _loadExercises();
                } else {
                  _showSnackBar(response.message, isError: true);
                }
              } else {
                // STEP 1: Check if exercises exist using GET API
                debugPrint('📡 Checking existing exercises for date: $dateStr');
                final getResponse = await PlanService.getExercises(
                  widget.patientId,
                  date: dateStr,
                );

                if (getResponse.success) {
                  final existingExercises = getResponse.data ?? [];
                  debugPrint(
                    '✅ GET API: Found ${existingExercises.length} existing exercises',
                  );

                  if (existingExercises.isNotEmpty) {
                    debugPrint('📋 Existing exercises:');
                    for (var ex in existingExercises) {
                      debugPrint(
                        '   - ${ex.exerciseName} (${ex.exerciseType})',
                      );
                    }
                  }
                }

                // STEP 2: Add new exercise using POST API
                debugPrint('📡 Adding new exercise using POST API...');
                final response = await PlanService.addExercise(
                  widget.patientId,
                  newExercise,
                );
                if (response.success) {
                  _showSnackBar('Exercise added successfully');
                  _loadExercises();
                } else {
                  _showSnackBar(response.message, isError: true);
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExercise(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text(
          'Are you sure you want to delete "${exercise.exerciseName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final response = await PlanService.deleteExercise(
                widget.patientId,
                exercise.id.toString(),
              );
              if (response.success) {
                _showSnackBar('Exercise deleted successfully');
                _loadExercises();
              } else {
                _showSnackBar(response.message, isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddSupplementDialog() {
    _showSupplementDialog(null);
  }

  void _showEditSupplementDialog(Supplement supplement) {
    _showSupplementDialog(supplement);
  }

  void _showSupplementDialog(Supplement? supplement) {
    final isEdit = supplement != null;
    final nameController = TextEditingController(
      text: supplement?.supplementName ?? '',
    );
    final dosageController = TextEditingController(
      text: supplement?.dosage ?? '',
    );
    final instructionsController = TextEditingController(
      text: supplement?.instructions ?? '',
    );
    String selectedFrequency = supplement?.frequency ?? 'once daily';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Supplement' : 'Add Supplement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Supplement Name *',
                  hintText: 'e.g., Vitamin D',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g., 500mg',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedFrequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items: Supplement.frequencyOptions.map((freq) {
                  return DropdownMenuItem(value: freq, child: Text(freq));
                }).toList(),
                onChanged: (value) => selectedFrequency = value!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                _showSnackBar('Please enter supplement name', isError: true);
                return;
              }

              final newSupplement = Supplement(
                supplementName: nameController.text,
                dosage: dosageController.text.isEmpty
                    ? null
                    : dosageController.text,
                frequency: selectedFrequency,
                instructions: instructionsController.text.isEmpty
                    ? null
                    : instructionsController.text,
                startDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
              );

              Navigator.pop(context);

              if (isEdit) {
                final response = await PlanService.updateSupplement(
                  widget.patientId,
                  supplement.id.toString(),
                  newSupplement,
                );
                if (response.success) {
                  _showSnackBar('Supplement updated successfully');
                  _loadSupplements();
                } else {
                  _showSnackBar(response.message, isError: true);
                }
              } else {
                final response = await PlanService.addSupplement(
                  widget.patientId,
                  newSupplement,
                );
                if (response.success) {
                  _showSnackBar('Supplement added successfully');
                  _loadSupplements();
                } else {
                  _showSnackBar(response.message, isError: true);
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSupplement(Supplement supplement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplement'),
        content: Text(
          'Are you sure you want to delete "${supplement.supplementName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final response = await PlanService.deleteSupplement(
                widget.patientId,
                supplement.id.toString(),
              );
              if (response.success) {
                _showSnackBar('Supplement deleted successfully');
                _loadSupplements();
              } else {
                _showSnackBar(response.message, isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSetWeightTargetDialog() {
    final currentWeightController = TextEditingController(
      text: _weightTarget?.currentWeight.toString() ?? '',
    );
    final targetWeightController = TextEditingController(
      text: _weightTarget?.targetWeight.toString() ?? '',
    );
    final notesController = TextEditingController(
      text: _weightTarget?.notes ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _weightTarget == null ? 'Set Weight Target' : 'Update Weight Target',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Weight (kg) *',
                  hintText: 'e.g., 75',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Weight (kg) *',
                  hintText: 'e.g., 70',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentWeight = double.tryParse(
                currentWeightController.text,
              );
              final targetWeight = double.tryParse(targetWeightController.text);

              if (currentWeight == null || targetWeight == null) {
                _showSnackBar('Please enter valid weights', isError: true);
                return;
              }

              final newTarget = WeightTarget(
                currentWeight: currentWeight,
                targetWeight: targetWeight,
                notes: notesController.text.isEmpty
                    ? null
                    : notesController.text,
              );

              Navigator.pop(context);

              if (_weightTarget != null) {
                final response = await PlanService.updateWeightTarget(
                  widget.patientId,
                  _weightTarget!.id.toString(),
                  newTarget,
                );
                if (response.success) {
                  _showSnackBar('Weight target updated successfully');
                  _loadWeightTarget();
                } else {
                  _showSnackBar(response.message, isError: true);
                }
              } else {
                final response = await PlanService.setWeightTarget(
                  widget.patientId,
                  newTarget,
                );
                if (response.success) {
                  _showSnackBar('Weight target set successfully');
                  _loadWeightTarget();
                } else {
                  _showSnackBar(response.message, isError: true);
                }
              }
            },
            child: Text(_weightTarget == null ? 'Set' : 'Update'),
          ),
        ],
      ),
    );
  }
}
