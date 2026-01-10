import 'dart:async';
import 'package:flutter/material.dart';
import 'package:meddiet/constants/app_colors.dart';
import 'package:meddiet/constants/api_config.dart';
import 'package:meddiet/constants/api_endpoints.dart';
import 'package:meddiet/services/auth_service.dart';
import 'package:meddiet/services/plan_service.dart';
import 'package:meddiet/models/meal.dart';
import 'package:meddiet/models/exercise.dart';
import 'package:meddiet/models/supplement.dart';
import 'package:meddiet/widgets/common_header.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  int selectedPatientIndex = 0;
  String searchQuery = '';
  String? selectedMealType;

  // API data
  List<Map<String, dynamic>> _apiPatients = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Follow-up Form Controllers
  final _weightController = TextEditingController();
  final _sleepController = TextEditingController();
  final _exerciseNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _cravingsController = TextEditingController();
  final _supplementsController = TextEditingController();

  // Meal Controllers
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _dinnerController = TextEditingController();
  final _snacksController = TextEditingController();

  // Add Meal Dialog Controllers
  final _mealNameController = TextEditingController();
  final _mealCaloriesController = TextEditingController();
  final _mealTimeController = TextEditingController();
  final _mealDescriptionController = TextEditingController();
  final _mealProteinController = TextEditingController();
  final _mealCarbsController = TextEditingController();
  final _mealFatsController = TextEditingController();

  // Add Exercise Dialog Controllers
  final _exerciseDurationController = TextEditingController();
  final _exerciseCaloriesController = TextEditingController();
  final _exerciseTimeController = TextEditingController();
  final _exerciseInstructionsController = TextEditingController();
  String? selectedExerciseType;

  // Add Supplement Dialog Controllers
  final _supplementNameController = TextEditingController();
  final _supplementDosageController = TextEditingController();
  final _supplementTimeController = TextEditingController();
  final _supplementInstructionsController = TextEditingController();
  final _supplementStartDateController = TextEditingController();
  final _supplementEndDateController = TextEditingController();
  String? selectedSupplementFrequency;

  bool _isAddingMeal = false;
  bool _isAddingExercise = false;
  bool _isAddingSupplement = false;

  Timer? _refreshTimer;

  // Track completion status for real-time updates
  final Map<String, bool> _mealCompletionStatus = {};
  final Map<String, bool> _exerciseCompletionStatus = {};
  final Map<String, bool> _supplementCompletionStatus = {};

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    // Auto-refresh only completion status every 3 seconds (lightweight)
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _refreshCompletionStatus();
      }
    });
  }

  /// Lightweight refresh - only fetch completion status for current patient
  Future<void> _refreshCompletionStatus() async {
    if (_apiPatients.isEmpty || selectedPatientIndex >= _apiPatients.length) {
      return;
    }

    final patient = _apiPatients[selectedPatientIndex];
    final patientId = patient['id'] as String;
    final today = DateTime.now().toIso8601String().split('T')[0];

    try {
      // Fetch only today's meals, exercises, and supplements (lightweight)
      final results = await Future.wait([
        PlanService.getMeals(patientId, date: today),
        PlanService.getExercises(patientId, date: today),
        PlanService.getSupplements(patientId),
      ]);

      if (mounted) {
        setState(() {
          // Update meals
          if (results[0].success && results[0].data != null) {
            final mealsList = results[0].data as List<Meal>;
            final meals = mealsList.map((m) => m.toJson()).toList();
            patient['mealsToday'] = meals;

            // Track completion status
            for (var meal in meals) {
              final mealId = meal['id'].toString();
              _mealCompletionStatus[mealId] =
                  meal['is_completed'] == true || meal['is_completed'] == 1;
            }
          }

          // Update exercises
          if (results[1].success && results[1].data != null) {
            final exercisesList = results[1].data as List<Exercise>;
            final exercises = exercisesList.map((e) => e.toJson()).toList();
            patient['exercisesToday'] = exercises;

            // Track completion status
            for (var exercise in exercises) {
              final exerciseId = exercise['id'].toString();
              _exerciseCompletionStatus[exerciseId] =
                  exercise['is_completed'] == true ||
                  exercise['is_completed'] == 1;
            }
          }

          // Update supplements
          if (results[2].success && results[2].data != null) {
            final supplementsList = results[2].data as List<Supplement>;
            final supplements = supplementsList.map((s) => s.toJson()).toList();
            patient['supplementsToday'] = supplements;

            // Track completion status
            for (var supplement in supplements) {
              final supplementId = supplement['id'].toString();
              _supplementCompletionStatus[supplementId] =
                  supplement['is_completed'] == true ||
                  supplement['is_completed'] == 1;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error refreshing completion status: $e');
      // Silently fail - don't show errors to user during background refresh
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _sleepController.dispose();
    _exerciseNameController.dispose();
    _notesController.dispose();
    _cravingsController.dispose();
    _supplementsController.dispose();
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    _snacksController.dispose();
    _mealNameController.dispose();
    _mealCaloriesController.dispose();
    _mealTimeController.dispose();
    _mealDescriptionController.dispose();
    _mealProteinController.dispose();
    _mealCarbsController.dispose();
    _mealFatsController.dispose();
    _exerciseDurationController.dispose();
    _exerciseCaloriesController.dispose();
    _exerciseTimeController.dispose();
    _exerciseInstructionsController.dispose();
    _supplementNameController.dispose();
    _supplementDosageController.dispose();
    _supplementTimeController.dispose();
    _supplementInstructionsController.dispose();
    _supplementStartDateController.dispose();
    _supplementEndDateController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Cache for patients steps data
  final Map<String, Map<String, dynamic>> _patientsStepsData = {};

  // Cache for patients meals data
  final Map<String, List<dynamic>> _patientsMealsData = {};

  // Cache for patients exercises data
  final Map<String, List<dynamic>> _patientsExercisesData = {};

  // Cache for patients supplements data
  final Map<String, List<dynamic>> _patientsSupplementsData = {};

  /// Refresh only meals for a specific patient
  Future<void> _refreshPatientMeals(String patientId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiEndpoints.patientMeals(patientId)}?date=$today',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _patientsMealsData[patientId] = data['data'] as List<dynamic>;
          });
          debugPrint('✅ Refreshed meals for patient $patientId');
        }
      }
    } catch (e) {
      debugPrint('❌ Error refreshing meals: $e');
    }
  }

  /// Refresh only exercises for a specific patient
  Future<void> _refreshPatientExercises(String patientId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiEndpoints.patientExercises(patientId)}?date=$today',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _patientsExercisesData[patientId] = data['data'] as List<dynamic>;
          });
          debugPrint('✅ Refreshed exercises for patient $patientId');
        }
      }
    } catch (e) {
      debugPrint('❌ Error refreshing exercises: $e');
    }
  }

  /// Refresh only supplements for a specific patient
  Future<void> _refreshPatientSupplements(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiEndpoints.patientSupplements(patientId)}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _patientsSupplementsData[patientId] = data['data'] as List<dynamic>;
          });
          debugPrint('✅ Refreshed supplements for patient $patientId');
        }
      }
    } catch (e) {
      debugPrint('❌ Error refreshing supplements: $e');
    }
  }

  /// Smart refresh - only refreshes specific data without full page reload
  Future<void> _smartRefresh(
    String patientId, {
    bool meals = false,
    bool exercises = false,
    bool supplements = false,
  }) async {
    final futures = <Future>[];

    if (meals) futures.add(_refreshPatientMeals(patientId));
    if (exercises) futures.add(_refreshPatientExercises(patientId));
    if (supplements) futures.add(_refreshPatientSupplements(patientId));

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// Fetch patients from API
  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch patients and steps data in parallel
      final responses = await Future.wait([
        http.get(
          Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patients}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AuthService.token}',
          },
        ),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patientsStepsToday}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AuthService.token}',
          },
        ),
      ]);

      final patientsResponse = responses[0];
      final stepsResponse = responses[1];

      debugPrint('Patients API Response: ${patientsResponse.statusCode}');
      debugPrint('Steps API Response: ${stepsResponse.statusCode}');

      // Process steps data first
      if (stepsResponse.statusCode == 200) {
        final stepsData = jsonDecode(stepsResponse.body);
        if (stepsData['success'] == true && stepsData['data'] != null) {
          final List<dynamic> stepsList = stepsData['data'];
          for (var step in stepsList) {
            final patientId = step['patient_id']?.toString() ?? '';
            if (patientId.isNotEmpty) {
              _patientsStepsData[patientId] = {
                'steps': _parseInt(step['steps']),
                'targetSteps': _parseInt(step['target_steps']),
                'status': step['status'] ?? 'unknown',
                'caloriesBurned': _parseDouble(step['calories_burned']),
                'distanceKm': _parseDouble(step['distance_km']),
                'lastSync': step['last_sync'],
              };
            }
          }
          debugPrint('Loaded steps for ${_patientsStepsData.length} patients');
        }
      }

      // Process patients data
      if (patientsResponse.statusCode == 200) {
        final data = jsonDecode(patientsResponse.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> patientsData = data['data'];

          // Fetch data for each patient in parallel
          debugPrint('📡 Fetching data for ${patientsData.length} patients...');
          await Future.wait([
            _fetchMealsForPatients(patientsData),
            _fetchExercisesForPatients(patientsData),
            _fetchSupplementsForPatients(patientsData),
          ]);

          setState(() {
            _apiPatients = patientsData.map((p) => _mapPatientData(p)).toList();
            _isLoading = false;
          });
          debugPrint('Loaded ${_apiPatients.length} patients from API');
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load patients';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${patientsResponse.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  /// Fetch meals for all patients
  Future<void> _fetchMealsForPatients(List<dynamic> patientsData) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Fetch meals for each patient in parallel
      final mealsFutures = patientsData.map((patient) async {
        final patientId = patient['patient_id']?.toString() ?? '';
        if (patientId.isEmpty) return;

        try {
          final response = await http.get(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiEndpoints.patientMeals(patientId)}?date=$today',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AuthService.token}',
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true && data['data'] != null) {
              _patientsMealsData[patientId] = data['data'] as List<dynamic>;
              debugPrint(
                '✅ Loaded ${_patientsMealsData[patientId]?.length ?? 0} meals for patient $patientId',
              );
            }
          }
        } catch (e) {
          debugPrint('❌ Error fetching meals for patient $patientId: $e');
        }
      }).toList();

      await Future.wait(mealsFutures);
      debugPrint(
        '📊 Total meals loaded for ${_patientsMealsData.length} patients',
      );
    } catch (e) {
      debugPrint('❌ Error in _fetchMealsForPatients: $e');
    }
  }

  /// Fetch exercises for all patients
  Future<void> _fetchExercisesForPatients(List<dynamic> patientsData) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Fetch exercises for each patient in parallel
      final exercisesFutures = patientsData.map((patient) async {
        final patientId = patient['patient_id']?.toString() ?? '';
        if (patientId.isEmpty) return;

        try {
          final response = await http.get(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiEndpoints.patientExercises(patientId)}?date=$today',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AuthService.token}',
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true && data['data'] != null) {
              _patientsExercisesData[patientId] = data['data'] as List<dynamic>;
              debugPrint(
                '✅ Loaded ${_patientsExercisesData[patientId]?.length ?? 0} exercises for patient $patientId',
              );
            }
          }
        } catch (e) {
          debugPrint('❌ Error fetching exercises for patient $patientId: $e');
        }
      }).toList();

      await Future.wait(exercisesFutures);
      debugPrint(
        '📊 Total exercises loaded for ${_patientsExercisesData.length} patients',
      );
    } catch (e) {
      debugPrint('❌ Error in _fetchExercisesForPatients: $e');
    }
  }

  /// Fetch supplements for all patients
  Future<void> _fetchSupplementsForPatients(List<dynamic> patientsData) async {
    try {
      // Fetch supplements for each patient in parallel
      final supplementsFutures = patientsData.map((patient) async {
        final patientId = patient['patient_id']?.toString() ?? '';
        if (patientId.isEmpty) return;

        try {
          final response = await http.get(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiEndpoints.patientSupplements(patientId)}',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AuthService.token}',
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true && data['data'] != null) {
              _patientsSupplementsData[patientId] =
                  data['data'] as List<dynamic>;
              debugPrint(
                '✅ Loaded ${_patientsSupplementsData[patientId]?.length ?? 0} supplements for patient $patientId',
              );
            }
          }
        } catch (e) {
          debugPrint('❌ Error fetching supplements for patient $patientId: $e');
        }
      }).toList();

      await Future.wait(supplementsFutures);
      debugPrint(
        '📊 Total supplements loaded for ${_patientsSupplementsData.length} patients',
      );
    } catch (e) {
      debugPrint('❌ Error in _fetchSupplementsForPatients: $e');
    }
  }

  /// Parse dynamic value to double (handles strings and numbers)
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Calculate patient's today's progress percentage
  int _calculatePatientProgress(String patientId) {
    // Get today's data for the patient
    final meals = _patientsMealsData[patientId] ?? [];
    final exercises = _patientsExercisesData[patientId] ?? [];
    final supplements = _patientsSupplementsData[patientId] ?? [];
    final stepsData = _patientsStepsData[patientId];

    // Count completed items
    final completedMeals = meals
        .where(
          (m) =>
              m['is_completed'] == true ||
              m['is_completed'] == 1 ||
              m['is_completed'] == '1' ||
              m['is_completed'] == 'true',
        )
        .length;
    final completedExercises = exercises
        .where(
          (e) =>
              e['is_completed'] == true ||
              e['is_completed'] == 1 ||
              e['is_completed'] == '1' ||
              e['is_completed'] == 'true',
        )
        .length;
    final completedSupplements = supplements
        .where(
          (s) =>
              s['is_completed'] == true ||
              s['is_completed'] == 1 ||
              s['is_completed'] == '1' ||
              s['is_completed'] == 'true',
        )
        .length;

    // Calculate steps progress (0 or 1 task)
    double stepsProgress = 0.0;
    if (stepsData != null) {
      final currentSteps = (stepsData['steps'] ?? 0).toDouble();
      final targetSteps = (stepsData['target_steps'] ?? 10000).toDouble();
      stepsProgress = targetSteps > 0
          ? (currentSteps / targetSteps).clamp(0.0, 1.0)
          : 0.0;
    }

    // Total tasks = meals + exercises + supplements + steps
    final totalTasks =
        meals.length +
        exercises.length +
        supplements.length +
        (stepsData != null ? 1 : 0);

    if (totalTasks == 0) return 0;

    // Completed tasks = completed items + steps progress
    final completedTasks =
        completedMeals +
        completedExercises +
        completedSupplements +
        stepsProgress;

    // Calculate percentage
    final percentage = ((completedTasks / totalTasks) * 100).round();
    return percentage.clamp(0, 100);
  }

  /// Parse dynamic value to int (handles strings and numbers)
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Map API patient data to UI format
  Map<String, dynamic> _mapPatientData(Map<String, dynamic> apiPatient) {
    final weight = _parseDouble(apiPatient['weight']);
    final height = _parseDouble(apiPatient['height']);
    final patientId = apiPatient['patient_id']?.toString() ?? '';

    // Get steps data for this patient
    final stepsData = _patientsStepsData[patientId] ?? {};
    final steps = stepsData['steps'] ?? 0;
    final targetSteps = stepsData['targetSteps'] ?? 10000;
    final caloriesBurned = stepsData['caloriesBurned'] ?? 0.0;
    final distanceKm = stepsData['distanceKm'] ?? 0.0;

    // Get meals data for this patient and transform to UI format
    final mealsData = _patientsMealsData[patientId] ?? [];
    final mealsToday = mealsData.map((meal) {
      return {
        'id': meal['id'],
        'meal_name': meal['meal_name'] ?? 'Unknown Meal',
        'name': meal['meal_name'] ?? 'Unknown Meal',
        'time': meal['time'] ?? 'N/A',
        'calories': _parseInt(meal['calories']),
        'meal_type': meal['meal_type'] ?? 'other',
        'type': meal['meal_type'] ?? 'other',
        'description': meal['description'],
        'protein': meal['protein'],
        'carbs': meal['carbs'],
        'fats': meal['fats'],
        'is_completed': meal['is_completed'] ?? false,
      };
    }).toList();

    // Calculate total calories from meals
    int totalCalories = 0;
    for (var meal in mealsData) {
      totalCalories += _parseInt(meal['calories']);
    }

    // Get exercises data for this patient and transform to UI format
    final exercisesData = _patientsExercisesData[patientId] ?? [];
    final exercisesToday = exercisesData.map((exercise) {
      final durationMins = _parseInt(exercise['duration_mins']);
      return {
        'id': exercise['id'],
        'exercise_name': exercise['exercise_name'] ?? 'Unknown Exercise',
        'name': exercise['exercise_name'] ?? 'Unknown Exercise',
        'exercise_type': exercise['exercise_type'] ?? 'other',
        'type': exercise['exercise_type'] ?? 'other',
        'duration': '$durationMins min',
        'time': exercise['time'] ?? 'Not specified',
        'calories': _parseInt(exercise['calories_burn']),
        'caloriesBurn': _parseInt(exercise['calories_burn']),
        'instructions': exercise['instructions'],
        'is_completed': exercise['is_completed'] ?? false,
      };
    }).toList();

    // Calculate total exercise minutes
    int totalExerciseMinutes = 0;
    for (var exercise in exercisesData) {
      totalExerciseMinutes += _parseInt(exercise['duration_mins']);
    }

    // Get supplements data for this patient and transform to UI format
    final supplementsData = _patientsSupplementsData[patientId] ?? [];
    final supplementsToday = supplementsData.map((supplement) {
      return {
        'id': supplement['id'],
        'supplement_name':
            supplement['supplement_name'] ?? 'Unknown Supplement',
        'name': supplement['supplement_name'] ?? 'Unknown Supplement',
        'dosage': supplement['dosage'] ?? 'N/A',
        'frequency': supplement['frequency'] ?? 'N/A',
        'instructions': supplement['instructions'],
        'startDate': supplement['start_date'],
        'endDate': supplement['end_date'],
        'is_completed': supplement['is_completed'] ?? false,
      };
    }).toList();

    return {
      'name': apiPatient['name'] ?? 'Unknown',
      'id': patientId,
      'patient_id': patientId,
      'age': _parseInt(apiPatient['age']),
      'gender': apiPatient['gender'] ?? 'Unknown',
      'phone': apiPatient['phone'] ?? '',
      'email': apiPatient['email'] ?? '',
      'plan': 'MedDiet Program',
      'status': 'Active',
      'avatar':
          apiPatient['profile_image'] ??
          'https://i.pravatar.cc/150?u=$patientId',
      // Health Metrics (with real steps data from API)
      'weight': weight,
      'height': height,
      'bmi': _calculateBMI(weight, height),
      'targetWeight': 0.0,
      'steps': steps,
      'targetSteps': targetSteps,
      'caloriesBurned': caloriesBurned,
      'caloriesIntake': totalCalories,
      'targetCalories': 2000,
      'waterIntake': 0,
      'targetWater': 8,
      'sleepHours': 0.0,
      'heartRate': 0,
      'bloodPressure': 'N/A',
      'bloodSugar': 0,
      'bloodType': apiPatient['blood_type'] ?? 'Unknown',
      'exerciseMinutes': totalExerciseMinutes,
      'targetExercise': 60,
      'workoutType': 'N/A',
      'distanceKm': distanceKm,
      'mealsToday': mealsToday,
      'exercisesToday': exercisesToday,
      'supplementsToday': supplementsToday,
      'weightProgress': [],
      'lastVisit': 'N/A',
      'nextAppointment': 'N/A',
      'createdAt': apiPatient['created_at'] ?? '',
    };
  }

  double _calculateBMI(double weight, double height) {
    if (weight <= 0 || height <= 0) return 0.0;
    // BMI = weight(kg) / height(m)^2
    final heightInMeters = height / 100;
    return double.parse(
      (weight / (heightInMeters * heightInMeters)).toStringAsFixed(1),
    );
  }

  // Store passwords for each patient (in real app, this would be in database)
  final Map<String, String> patientPasswords = {};

  String _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(
      12,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _getOrCreatePassword(String patientId) {
    if (!patientPasswords.containsKey(patientId)) {
      patientPasswords[patientId] = _generatePassword();
    }
    return patientPasswords[patientId]!;
  }

  void _shareCredentialsViaWhatsApp(Map<String, dynamic> patient) async {
    final password = _getOrCreatePassword(patient['id']);
    final username =
        patient['email'] ??
        '${patient['name'].toLowerCase().replaceAll(' ', '.')}@meddiet.com';

    final message =
        '''
🏥 *MedDiet Admin - Patient Credentials*

Hello ${patient['name']},

Your account has been created successfully!

*Login Credentials:*
👤 Username: $username
🔐 Password: $password

Please keep these credentials safe and change your password after first login.

Download the MedDiet app and start your health journey today!

Best regards,
MedDiet Team
    ''';

    // Remove all non-numeric characters from phone number
    final phoneNumber = (patient['phone'] ?? '').replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final whatsappUrl =
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to regular share
        await Share.share(message);
      }
    } catch (e) {
      // Fallback to regular share
      await Share.share(message);
    }
  }

  void _resetPassword(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_reset,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Reset Password',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to reset the password for ${patient['name']}?',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A new password will be generated and can be shared with the patient.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  patientPasswords[patient['id']] = _generatePassword();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Password reset for ${patient['name']}'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Reset Password',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPatientMenu(Map<String, dynamic> patient) {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 100, 0, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'share',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Share Credentials via WhatsApp',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          onTap: () {
            Future.delayed(
              const Duration(milliseconds: 100),
              () => _shareCredentialsViaWhatsApp(patient),
            );
          },
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'reset',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_reset,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Reset Password', style: TextStyle(fontSize: 14)),
            ],
          ),
          onTap: () {
            Future.delayed(
              const Duration(milliseconds: 100),
              () => _resetPassword(patient),
            );
          },
        ),
      ],
    );
  }

  // Convert meal type display name to API format
  String _convertMealTypeToApi(String displayType) {
    switch (displayType) {
      case 'Breakfast':
        return 'breakfast';
      case 'Morning Snack':
        return 'mid_morning';
      case 'Lunch':
        return 'lunch';
      case 'Afternoon Snack':
      case 'Evening Snack':
        return 'evening_snack';
      case 'Dinner':
        return 'dinner';
      default:
        return 'breakfast';
    }
  }

  // Convert API meal type to display name
  String _convertMealTypeToDisplay(String apiType) {
    switch (apiType) {
      case 'breakfast':
        return 'Breakfast';
      case 'mid_morning':
        return 'Morning Snack';
      case 'lunch':
        return 'Lunch';
      case 'evening_snack':
        return 'Evening Snack';
      case 'dinner':
        return 'Dinner';
      default:
        return apiType;
    }
  }

  // Get color for meal type
  Color _getMealTypeColor(String apiType) {
    switch (apiType) {
      case 'breakfast':
        return Colors.orange;
      case 'mid_morning':
        return Colors.green;
      case 'lunch':
        return Colors.blue;
      case 'evening_snack':
        return Colors.purple;
      case 'dinner':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  // Get icon for meal type
  IconData _getMealTypeIcon(String apiType) {
    switch (apiType) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'mid_morning':
        return Icons.coffee;
      case 'lunch':
        return Icons.restaurant;
      case 'evening_snack':
        return Icons.local_cafe;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  // Get list of already added meal types for today
  Set<String> _getUsedMealTypes() {
    if (selectedPatientIndex < 0 || selectedPatientIndex >= patients.length) {
      return {};
    }

    final patient = patients[selectedPatientIndex];
    final meals = patient['mealsToday'] as List? ?? [];

    return meals
        .map((meal) => (meal['meal_type'] ?? meal['type'] ?? 'other') as String)
        .toSet();
  }

  // ========== EXERCISE HELPERS ==========

  // Get list of already added exercise types for today
  Set<String> _getUsedExerciseTypes() {
    if (selectedPatientIndex < 0 || selectedPatientIndex >= patients.length) {
      return {};
    }

    final patient = patients[selectedPatientIndex];
    final patientId = patient['patient_id'] ?? patient['id'];
    final exercises = _patientsExercisesData[patientId] ?? [];

    return exercises
        .map(
          (exercise) =>
              (exercise['exercise_type'] as String?)?.toLowerCase() ?? '',
        )
        .toSet();
  }

  // Get color for exercise type
  Color _getExerciseTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'cardio':
        return Colors.red;
      case 'strength':
        return Colors.blue;
      case 'flexibility':
        return Colors.purple;
      case 'balance':
        return Colors.teal;
      case 'walking':
        return Colors.green;
      case 'yoga':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  // Get icon for exercise type
  IconData _getExerciseTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'cardio':
        return Icons.directions_run;
      case 'strength':
        return Icons.fitness_center;
      case 'flexibility':
        return Icons.self_improvement;
      case 'balance':
        return Icons.accessibility_new;
      case 'walking':
        return Icons.directions_walk;
      case 'yoga':
        return Icons.spa;
      default:
        return Icons.sports;
    }
  }

  // ========== SUPPLEMENT HELPERS ==========

  // Get list of already added supplement names
  Set<String> _getUsedSupplementNames() {
    if (selectedPatientIndex < 0 || selectedPatientIndex >= patients.length) {
      return {};
    }

    final patient = patients[selectedPatientIndex];
    final patientId = patient['patient_id'] ?? patient['id'];
    final supplements = _patientsSupplementsData[patientId] ?? [];

    return supplements
        .map(
          (supplement) =>
              (supplement['supplement_name'] as String?)?.toLowerCase() ?? '',
        )
        .toSet();
  }

  // Get color for supplement (based on name patterns or default)
  Color _getSupplementColor(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('vitamin')) return Colors.orange;
    if (lowerName.contains('protein')) return Colors.blue;
    if (lowerName.contains('omega') || lowerName.contains('fish oil'))
      return Colors.teal;
    if (lowerName.contains('calcium')) return Colors.purple;
    if (lowerName.contains('iron')) return Colors.red;
    if (lowerName.contains('magnesium')) return Colors.green;
    return Colors.indigo;
  }

  // Get icon for supplement
  IconData _getSupplementIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('vitamin')) return Icons.water_drop;
    if (lowerName.contains('protein')) return Icons.fitness_center;
    if (lowerName.contains('omega') || lowerName.contains('fish oil')) {
      return Icons.set_meal;
    }
    if (lowerName.contains('calcium') || lowerName.contains('bone')) {
      return Icons.healing;
    }
    return Icons.medication;
  }

  /// Handle adding a new exercise
  Future<void> _handleAddExercise() async {
    // Validation
    if (selectedExerciseType == null || selectedExerciseType!.isEmpty) {
      debugPrint('❌ Validation failed: No exercise type selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an exercise type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_exerciseNameController.text.trim().isEmpty) {
      debugPrint('❌ Validation failed: No exercise name entered');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter exercise name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isAddingExercise = true);

    try {
      final patient = patients[selectedPatientIndex];
      final patientId = patient['patient_id'] ?? patient['id'];
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      debugPrint('🏃 Preparing to add exercise for patient: $patientId');
      debugPrint('📝 Exercise Type: $selectedExerciseType');
      debugPrint('📝 Exercise Name: ${_exerciseNameController.text.trim()}');

      // STEP 1: Check if exercises exist using GET API
      debugPrint('📡 Step 1: Checking existing exercises using GET API...');
      final getResponse = await PlanService.getExercises(
        patientId,
        date: today,
      );

      if (getResponse.success) {
        final existingExercises = getResponse.data ?? [];
        debugPrint(
          '✅ GET API successful: Found ${existingExercises.length} existing exercises for $today',
        );

        // Log existing exercises
        if (existingExercises.isNotEmpty) {
          debugPrint('📋 Existing exercises:');
          for (var ex in existingExercises) {
            debugPrint('   - ${ex.exerciseName} (${ex.exerciseType})');
          }
        } else {
          debugPrint('ℹ️ No exercises found for this date');
        }
      } else {
        debugPrint('⚠️ GET API returned error: ${getResponse.message}');
      }

      // STEP 2: Create and add new exercise using POST API
      debugPrint('📡 Step 2: Adding new exercise using POST API...');
      final exercise = Exercise(
        exerciseName: _exerciseNameController.text.trim(),
        exerciseType: selectedExerciseType?.toLowerCase(),
        durationMins: _exerciseDurationController.text.trim().isNotEmpty
            ? int.tryParse(_exerciseDurationController.text.trim())
            : null,
        caloriesBurn: _exerciseCaloriesController.text.trim().isNotEmpty
            ? int.tryParse(_exerciseCaloriesController.text.trim())
            : null,
        instructions: _exerciseInstructionsController.text.trim().isNotEmpty
            ? _exerciseInstructionsController.text.trim()
            : null,
        date: today,
      );

      final response = await PlanService.addExercise(patientId, exercise);

      if (response.success) {
        debugPrint('✅ Exercise added successfully via POST API');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh only exercises for this patient (smooth update)
        debugPrint('🔄 Refreshing exercises for patient $patientId...');
        await _smartRefresh(patientId, exercises: true);
      } else {
        debugPrint('❌ Failed to add exercise: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPTION in _handleAddExercise: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingExercise = false);
      }
    }
  }

  /// Handle adding a new supplement
  Future<void> _handleAddSupplement() async {
    // Validation
    if (_supplementNameController.text.trim().isEmpty) {
      debugPrint('❌ Validation failed: No supplement name entered');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter supplement name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isAddingSupplement = true);

    try {
      final patient = patients[selectedPatientIndex];
      final patientId = patient['patient_id'] ?? patient['id'];
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      debugPrint('💊 Preparing to add supplement for patient: $patientId');
      debugPrint(
        '📝 Supplement Name: ${_supplementNameController.text.trim()}',
      );

      final supplement = Supplement(
        supplementName: _supplementNameController.text.trim(),
        dosage: _supplementDosageController.text.trim().isNotEmpty
            ? _supplementDosageController.text.trim()
            : null,
        frequency: selectedSupplementFrequency ?? 'once daily',
        instructions: _supplementInstructionsController.text.trim().isNotEmpty
            ? _supplementInstructionsController.text.trim()
            : null,
        startDate: today,
        endDate: null,
      );

      final response = await PlanService.addSupplement(patientId, supplement);

      if (response.success) {
        debugPrint('✅ Supplement added successfully via API');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh only supplements for this patient (smooth update)
        debugPrint('🔄 Refreshing supplements for patient $patientId...');
        await _smartRefresh(patientId, supplements: true);
      } else {
        debugPrint('❌ Failed to add supplement: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPTION in _handleAddSupplement: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingSupplement = false);
      }
    }
  }

  /// Show edit supplement dialog
  void _showBMIDialog(Map<String, dynamic> patient) {
    final height = patient['height'] as double? ?? 170.0; // cm
    final progressRaw = patient['weightProgress'] as List? ?? [];
    final weights = progressRaw.map((e) => (e as num).toDouble()).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 700,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.monitor_weight,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BMI Analysis',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Historical BMI tracking and trends',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current BMI Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current BMI',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    patient['bmi'].toString(),
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              _buildBMICategoryChip(
                                patient['bmi'] as double? ?? 0.0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Recent Records',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (weights.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                'No historical BMI data found',
                                style: TextStyle(color: Color(0xFF9E9E9E)),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: weights.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              // Latest weights are usually at the end, so reverse for display
                              final weight =
                                  weights[weights.length - 1 - index];
                              final bmi = _calculateBMI(weight, height);
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E5E5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Record ${weights.length - index}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF9E9E9E),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Weight: $weight kg',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF2D3142),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'BMI',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF9E9E9E),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          bmi.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBMICategoryChip(double bmi) {
    String category = 'Normal';
    Color color = Colors.green;

    if (bmi < 18.5) {
      category = 'Underweight';
      color = Colors.orange;
    } else if (bmi >= 25 && bmi < 30) {
      category = 'Overweight';
      color = Colors.orange;
    } else if (bmi >= 30) {
      category = 'Obese';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showEditSupplementDialog(Map<String, dynamic> supplement) {
    // Populate form with supplement data
    _supplementNameController.text =
        supplement['supplement_name'] ?? supplement['name'] ?? '';
    _supplementDosageController.text = supplement['dosage'] ?? '';
    _supplementInstructionsController.text = supplement['instructions'] ?? '';

    final frequency = supplement['frequency'] ?? 'Once Daily';
    setState(() => selectedSupplementFrequency = frequency);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 700,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.blue.withValues(alpha: 0.8)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Supplement',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Update supplement details',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildDialogTextField(
                                'Supplement Name',
                                'e.g., Vitamin D3',
                                controller: _supplementNameController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildDialogTextField(
                                'Dosage',
                                'e.g., 1000 IU',
                                controller: _supplementDosageController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSupplementFrequencyDropdown(),
                        const SizedBox(height: 16),
                        _buildDialogTextField(
                          'Instructions',
                          'e.g., Take with food',
                          controller: _supplementInstructionsController,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isAddingSupplement
                            ? null
                            : () {
                                Navigator.pop(context);
                                _handleUpdateSupplement(supplement);
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.blue.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: _isAddingSupplement
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Update Supplement',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Handle updating an existing supplement
  Future<void> _handleUpdateSupplement(
    Map<String, dynamic> oldSupplement,
  ) async {
    // Validation
    if (_supplementNameController.text.trim().isEmpty) {
      debugPrint('❌ Validation failed: No supplement name entered');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter supplement name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final patient = patients[selectedPatientIndex];
      final patientId = patient['patient_id'] ?? patient['id'];
      final supplementId = oldSupplement['id'];

      debugPrint(
        '📝 Updating supplement ID: $supplementId for patient: $patientId',
      );

      final updatedSupplement = Supplement(
        supplementName: _supplementNameController.text.trim(),
        dosage: _supplementDosageController.text.trim().isNotEmpty
            ? _supplementDosageController.text.trim()
            : null,
        frequency: selectedSupplementFrequency ?? 'once daily',
        instructions: _supplementInstructionsController.text.trim().isNotEmpty
            ? _supplementInstructionsController.text.trim()
            : null,
        startDate:
            oldSupplement['start_date'] ??
            DateFormat('yyyy-MM-dd').format(DateTime.now()),
        endDate: oldSupplement['end_date'],
      );

      final response = await PlanService.updateSupplement(
        patientId,
        supplementId.toString(),
        updatedSupplement,
      );

      if (response.success) {
        debugPrint('✅ Supplement updated successfully');
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Supplement updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Refresh only supplements for this patient (smooth update)
        await _smartRefresh(patientId, supplements: true);
      } else {
        debugPrint('❌ Failed to update supplement: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPTION in _handleUpdateSupplement: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Confirm and delete supplement
  Future<void> _confirmDeleteSupplement(Map<String, dynamic> supplement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Supplement'),
          content: Text(
            'Are you sure you want to delete "${supplement['supplement_name'] ?? supplement['name'] ?? 'this supplement'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _handleDeleteSupplement(supplement);
    }
  }

  /// Handle deleting a supplement
  Future<void> _handleDeleteSupplement(Map<String, dynamic> supplement) async {
    try {
      final patient = patients[selectedPatientIndex];
      final patientId = patient['patient_id'] ?? patient['id'];
      final supplementId = supplement['id'];

      debugPrint(
        '🗑️ Deleting supplement ID: $supplementId for patient: $patientId',
      );

      final response = await PlanService.deleteSupplement(
        patientId,
        supplementId.toString(),
      );

      if (response.success) {
        debugPrint('✅ Supplement deleted successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Supplement deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Refresh only supplements for this patient (smooth update)
        await _smartRefresh(patientId, supplements: true);
      } else {
        debugPrint('❌ Failed to delete supplement: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPTION in _handleDeleteSupplement: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Confirm and delete all exercises for the selected patient
  void _confirmDeleteAllExercises() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete All Exercises'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete ALL exercises for today? This action cannot be undone.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleDeleteAllExercises();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  /// Handle deleting all exercises
  Future<void> _handleDeleteAllExercises() async {
    if (selectedPatientIndex < 0 || selectedPatientIndex >= patients.length) {
      debugPrint('❌ Invalid patient index');
      return;
    }

    try {
      final patient = patients[selectedPatientIndex];
      final patientId = patient['patient_id'] ?? patient['id'];
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      debugPrint('🗑️ Starting delete all exercises for patient: $patientId');

      // Get all exercises for today
      final getResponse = await PlanService.getExercises(
        patientId,
        date: today,
      );

      if (!getResponse.success ||
          getResponse.data == null ||
          getResponse.data!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No exercises to delete'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final exercises = getResponse.data!;
      debugPrint('📋 Found ${exercises.length} exercises to delete');

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Deleting ${exercises.length} exercises...'),
              ],
            ),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      // Delete each exercise
      int deletedCount = 0;
      int failedCount = 0;

      for (var exercise in exercises) {
        try {
          final deleteResponse = await PlanService.deleteExercise(
            patientId,
            exercise.id.toString(),
          );

          if (deleteResponse.success) {
            deletedCount++;
            debugPrint('✅ Deleted exercise: ${exercise.exerciseName}');
          } else {
            failedCount++;
            debugPrint(
              '❌ Failed to delete exercise ${exercise.id}: ${deleteResponse.message}',
            );
          }
        } catch (e) {
          failedCount++;
          debugPrint('❌ Exception deleting exercise ${exercise.id}: $e');
        }
      }

      // Hide loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      debugPrint('✅ Deleted $deletedCount exercises, $failedCount failed');

      if (mounted) {
        if (failedCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully deleted $deletedCount exercises'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Deleted $deletedCount exercises, $failedCount failed',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      // Refresh only exercises for this patient (smooth update)
      debugPrint('🔄 Refreshing exercises for patient $patientId...');
      await _smartRefresh(patientId, exercises: true);
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPTION in _handleDeleteAllExercises: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Delete individual meal
  Future<void> _deleteMeal(String patientId, dynamic mealId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Meal'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this meal? This action cannot be undone.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      debugPrint('🗑️ Deleting meal $mealId for patient $patientId');

      final response = await PlanService.deleteMeal(
        patientId,
        mealId.toString(),
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meal deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Smooth refresh - only meals section
          await _smartRefresh(patientId, meals: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete meal: ${response.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error deleting meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Delete individual exercise
  Future<void> _deleteExercise(String patientId, dynamic exerciseId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Exercise'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this exercise? This action cannot be undone.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      debugPrint('🗑️ Deleting exercise $exerciseId for patient $patientId');

      final response = await PlanService.deleteExercise(
        patientId,
        exerciseId.toString(),
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exercise deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Smooth refresh - only exercises section
          await _smartRefresh(patientId, exercises: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete exercise: ${response.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error deleting exercise: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show edit exercise dialog
  void _showEditExerciseDialog(Map<String, dynamic> exercise) {
    // Populate form with exercise data
    _exerciseNameController.text =
        exercise['exercise_name'] ?? exercise['name'] ?? '';
    _exerciseDurationController.text =
        exercise['duration']?.toString().replaceAll(' min', '') ?? '';
    _exerciseCaloriesController.text = exercise['calories']?.toString() ?? '';
    _exerciseInstructionsController.text = exercise['instructions'] ?? '';

    final exerciseType = exercise['type'] ?? 'cardio';
    setState(() => selectedExerciseType = exerciseType);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 700,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Exercise',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Update exercise details',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildExerciseTypeDropdown(
                                editingExerciseType: exerciseType,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _buildDialogTextField(
                                'Exercise Name',
                                'e.g., Morning Run',
                                controller: _exerciseNameController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogTextField(
                                'Duration (mins)',
                                'e.g., 30',
                                controller: _exerciseDurationController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDialogTextField(
                                'Calories Burned',
                                'e.g., 250',
                                controller: _exerciseCaloriesController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDialogTextField(
                                'Time',
                                'Select time',
                                controller: _exerciseTimeController,
                                readOnly: true,
                                suffixIcon: const Icon(
                                  Icons.access_time,
                                  size: 20,
                                ),
                                onTap: () => _selectTime(
                                  context,
                                  _exerciseTimeController,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDialogTextField(
                          'Instructions',
                          'e.g., Run at moderate pace',
                          controller: _exerciseInstructionsController,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isAddingExercise
                            ? null
                            : () {
                                Navigator.pop(context);
                                _handleUpdateExercise(exercise);
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: _isAddingExercise
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Update Exercise',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Handle updating an existing exercise
  Future<void> _handleUpdateExercise(Map<String, dynamic> oldExercise) async {
    // Validation
    if (selectedExerciseType == null || selectedExerciseType!.isEmpty) {
      debugPrint('❌ Validation failed: No exercise type selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an exercise type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_exerciseNameController.text.trim().isEmpty) {
      debugPrint('❌ Validation failed: No exercise name entered');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter exercise name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final patient = patients[selectedPatientIndex];
      final patientId = patient['patient_id'] ?? patient['id'];
      final exerciseId = oldExercise['id'];

      debugPrint(
        '📝 Updating exercise ID: $exerciseId for patient: $patientId',
      );

      final updatedExercise = Exercise(
        exerciseName: _exerciseNameController.text.trim(),
        exerciseType: selectedExerciseType?.toLowerCase(),
        durationMins: _exerciseDurationController.text.trim().isNotEmpty
            ? int.tryParse(_exerciseDurationController.text.trim())
            : null,
        caloriesBurn: _exerciseCaloriesController.text.trim().isNotEmpty
            ? int.tryParse(_exerciseCaloriesController.text.trim())
            : null,
        instructions: _exerciseInstructionsController.text.trim().isNotEmpty
            ? _exerciseInstructionsController.text.trim()
            : null,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      final response = await PlanService.updateExercise(
        patientId,
        exerciseId.toString(),
        updatedExercise,
      );

      if (response.success) {
        debugPrint('✅ Exercise updated successfully');
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exercise updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Refresh only exercises for this patient (smooth update)
        await _smartRefresh(patientId, exercises: true);
      } else {
        debugPrint('❌ Failed to update exercise: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPTION in _handleUpdateExercise: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Handle updating an existing meal
  Future<void> _handleUpdateMeal(Map<String, dynamic> oldMeal) async {
    // Validation
    if (selectedMealType == null || selectedMealType!.isEmpty) {
      debugPrint('❌ Validation failed: No meal type selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a meal type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_mealNameController.text.trim().isEmpty) {
      debugPrint('❌ Validation failed: No meal name entered');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter meal name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isAddingMeal = true);

    try {
      final patient = patients[selectedPatientIndex];
      final patientId = patient['patient_id'] ?? patient['id'];

      // Get meal ID - check if it's already in oldMeal or find it from cache
      String? mealId;

      if (oldMeal.containsKey('id') && oldMeal['id'] != null) {
        // ID is already in the meal object
        mealId = oldMeal['id'].toString();
        debugPrint('✅ Using meal ID from oldMeal: $mealId');
      } else {
        // Need to find ID from the meals data cache
        final mealsData = _patientsMealsData[patientId] ?? [];

        debugPrint('🔍 Looking for meal with:');
        debugPrint('   oldMeal[name]: ${oldMeal['name']}');
        debugPrint('   oldMeal[type]: ${oldMeal['type']}');
        debugPrint('   Available meals: ${mealsData.length}');

        final mealData = mealsData.firstWhere((m) {
          final mealName = oldMeal['name'] ?? oldMeal['meal_name'];
          final mealType = oldMeal['type'] ?? oldMeal['meal_type'];
          debugPrint(
            '   Checking meal: ${m['meal_name']} (${m['meal_type']}) - ID: ${m['id']}',
          );
          return m['meal_name'] == mealName && m['meal_type'] == mealType;
        }, orElse: () => {});

        if (mealData.isEmpty || mealData['id'] == null) {
          debugPrint('❌ Could not find meal ID');
          debugPrint(
            '   Searched for: ${oldMeal['name']} (${oldMeal['type']})',
          );
          debugPrint(
            '   Available meals: ${mealsData.map((m) => '${m['meal_name']} (${m['meal_type']})').join(', ')}',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Error: Could not find meal to update. Try refreshing the patient list.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          setState(() => _isAddingMeal = false);
          return;
        }

        mealId = mealData['id'].toString();
      }

      debugPrint(
        '🍽️ Preparing to update meal $mealId for patient: $patientId',
      );
      debugPrint('📝 Meal Type: ${_convertMealTypeToApi(selectedMealType!)}');
      debugPrint('📝 Meal Name: ${_mealNameController.text.trim()}');

      // Create meal object with updated data
      final meal = Meal(
        mealType: _convertMealTypeToApi(selectedMealType!),
        mealName: _mealNameController.text.trim(),
        description: _mealDescriptionController.text.trim().isNotEmpty
            ? _mealDescriptionController.text.trim()
            : null,
        calories: _mealCaloriesController.text.trim().isNotEmpty
            ? int.tryParse(_mealCaloriesController.text.trim())
            : null,
        protein: _mealProteinController.text.trim().isNotEmpty
            ? double.tryParse(_mealProteinController.text.trim())
            : null,
        carbs: _mealCarbsController.text.trim().isNotEmpty
            ? double.tryParse(_mealCarbsController.text.trim())
            : null,
        fats: _mealFatsController.text.trim().isNotEmpty
            ? double.tryParse(_mealFatsController.text.trim())
            : null,
        time: _mealTimeController.text.trim().isNotEmpty
            ? _mealTimeController.text.trim()
            : null,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      // Call API
      debugPrint('📡 Calling PlanService.updateMeal...');
      final response = await PlanService.updateMeal(patientId, mealId, meal);

      if (response.success) {
        debugPrint('✅ Meal updated successfully via API');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh only meals for this patient (smooth update)
        debugPrint('🔄 Refreshing meals for patient $patientId...');
        await _smartRefresh(patientId, meals: true);
      } else {
        debugPrint('❌ Failed to update meal: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPTION in _handleUpdateMeal: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingMeal = false);
      }
    }
  }

  Future<void> _handleAddMeal() async {
    // Validation
    if (selectedMealType == null || selectedMealType!.isEmpty) {
      debugPrint('❌ Validation failed: No meal type selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a meal type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_mealNameController.text.trim().isEmpty) {
      debugPrint('❌ Validation failed: No meal name entered');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter meal name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isAddingMeal = true);

    try {
      final patient = patients[selectedPatientIndex];
      final patientId = patient['patient_id'] ?? patient['id'];

      debugPrint('🍽️ Preparing to add meal for patient: $patientId');
      debugPrint('📝 Meal Type: ${_convertMealTypeToApi(selectedMealType!)}');
      debugPrint('📝 Meal Name: ${_mealNameController.text.trim()}');

      // Create meal object
      final meal = Meal(
        mealType: _convertMealTypeToApi(selectedMealType!),
        mealName: _mealNameController.text.trim(),
        description: _mealDescriptionController.text.trim().isNotEmpty
            ? _mealDescriptionController.text.trim()
            : null,
        calories: _mealCaloriesController.text.trim().isNotEmpty
            ? int.tryParse(_mealCaloriesController.text.trim())
            : null,
        protein: _mealProteinController.text.trim().isNotEmpty
            ? double.tryParse(_mealProteinController.text.trim())
            : null,
        carbs: _mealCarbsController.text.trim().isNotEmpty
            ? double.tryParse(_mealCarbsController.text.trim())
            : null,
        fats: _mealFatsController.text.trim().isNotEmpty
            ? double.tryParse(_mealFatsController.text.trim())
            : null,
        time: _mealTimeController.text.trim().isNotEmpty
            ? _mealTimeController.text.trim()
            : null,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      // Call API
      debugPrint('📡 Calling PlanService.addMeal...');
      final response = await PlanService.addMeal(patientId, meal);

      if (response.success) {
        debugPrint('✅ Meal added successfully via API');

        // Clear form
        _mealNameController.clear();
        _mealCaloriesController.clear();
        _mealTimeController.clear();
        _mealDescriptionController.clear();
        _mealProteinController.clear();
        _mealCarbsController.clear();
        _mealFatsController.clear();
        setState(() => selectedMealType = null);

        // Close dialog
        if (mounted) Navigator.pop(context);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh only meals for this patient (smooth update)
        debugPrint('🔄 Refreshing meals for patient $patientId...');
        await _smartRefresh(patientId, meals: true);
      } else {
        debugPrint('❌ Failed to add meal: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPTION in _handleAddMeal: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingMeal = false);
      }
    }
  }

  /// Confirm and delete all meals for the selected patient
  void _confirmDeleteAllMeals() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete All Meals'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete ALL meals for today? This action cannot be undone.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleDeleteAllMeals();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  /// Handle deleting all meals
  Future<void> _handleDeleteAllMeals() async {
    if (selectedPatientIndex < 0 || selectedPatientIndex >= patients.length) {
      debugPrint('❌ Invalid patient index');
      return;
    }

    try {
      final patient = patients[selectedPatientIndex];
      final patientId = patient['patient_id'] ?? patient['id'];
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      debugPrint('🗑️ Starting delete all meals for patient: $patientId');

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Deleting all meals...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Call API to delete all meals
      final response = await PlanService.deleteAllMeals(patientId, date: today);

      // Hide loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (response.success) {
        final deletedCount = response.data ?? 0;
        debugPrint('✅ Successfully deleted $deletedCount meals');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully deleted $deletedCount meals'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Refresh only meals for this patient (smooth update)
        debugPrint('🔄 Refreshing meals for patient $patientId...');
        await _smartRefresh(patientId, meals: true);
      } else {
        debugPrint('❌ Failed to delete meals: ${response.message}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPTION in _handleDeleteAllMeals: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showEditMealDialog(Map<String, dynamic> meal) {
    // Populate form with meal data
    _mealNameController.text = meal['name'] ?? meal['meal_name'] ?? '';
    _mealCaloriesController.text = meal['calories']?.toString() ?? '';
    _mealTimeController.text = meal['time'] ?? '';
    _mealDescriptionController.text = meal['description'] ?? '';
    _mealProteinController.text = meal['protein']?.toString() ?? '';
    _mealCarbsController.text = meal['carbs']?.toString() ?? '';
    _mealFatsController.text = meal['fats']?.toString() ?? '';

    final mealType = meal['type'] ?? meal['meal_type'] ?? 'breakfast';
    setState(() => selectedMealType = _convertMealTypeToDisplay(mealType));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 700,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Edit Meal',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildMealTypeDropdown(
                                editingMealType: mealType,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _buildDialogTextField(
                                'Meal Name',
                                'e.g., Oats with fruits',
                                controller: _mealNameController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogTextField(
                                'Calories',
                                'e.g., 450',
                                controller: _mealCaloriesController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDialogTextField(
                                'Time',
                                'Select time',
                                controller: _mealTimeController,
                                readOnly: true,
                                suffixIcon: const Icon(
                                  Icons.access_time,
                                  size: 20,
                                ),
                                onTap: () =>
                                    _selectTime(context, _mealTimeController),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogTextField(
                                'Protein (g)',
                                'e.g., 15',
                                controller: _mealProteinController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDialogTextField(
                                'Carbs (g)',
                                'e.g., 60',
                                controller: _mealCarbsController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDialogTextField(
                                'Fats (g)',
                                'e.g., 10',
                                controller: _mealFatsController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDialogTextField(
                          'Description (Optional)',
                          'Additional notes...',
                          controller: _mealDescriptionController,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isAddingMeal
                            ? null
                            : () {
                                Navigator.pop(context);
                                _handleUpdateMeal(meal);
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: _isAddingMeal
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Update Meal',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddMealDialog() {
    // Reset form
    _mealNameController.clear();
    _mealCaloriesController.clear();
    _mealTimeController.clear();
    _mealDescriptionController.clear();
    _mealProteinController.clear();
    _mealCarbsController.clear();
    _mealFatsController.clear();
    setState(() => selectedMealType = null);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 700,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Meal',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Track your daily nutrition',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(flex: 2, child: _buildMealTypeDropdown()),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _buildDialogTextField(
                                'Meal Name',
                                'e.g., Oats with fruits',
                                controller: _mealNameController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogTextField(
                                'Calories',
                                'e.g., 450',
                                controller: _mealCaloriesController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDialogTextField(
                                'Time',
                                'Select time',
                                controller: _mealTimeController,
                                readOnly: true,
                                suffixIcon: const Icon(
                                  Icons.access_time,
                                  size: 20,
                                ),
                                onTap: () =>
                                    _selectTime(context, _mealTimeController),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogTextField(
                                'Protein (g)',
                                'e.g., 15',
                                controller: _mealProteinController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDialogTextField(
                                'Carbs (g)',
                                'e.g., 50',
                                controller: _mealCarbsController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDialogTextField(
                                'Fats (g)',
                                'e.g., 10',
                                controller: _mealFatsController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDialogTextField(
                          'Description',
                          'Additional details...',
                          maxLines: 3,
                          controller: _mealDescriptionController,
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isAddingMeal ? null : _handleAddMeal,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.success,
                                AppColors.success.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: _isAddingMeal
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Add Meal',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddExerciseDialog() {
    // Reset form
    _exerciseNameController.clear();
    _exerciseDurationController.clear();
    _exerciseCaloriesController.clear();
    _exerciseTimeController.clear();
    _exerciseInstructionsController.clear();
    setState(() => selectedExerciseType = null);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 700,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Exercise',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Track your workout activity',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildExerciseTypeDropdown(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _buildDialogTextField(
                                'Exercise Name',
                                'e.g., Morning Run',
                                controller: _exerciseNameController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogTextField(
                                'Duration (mins)',
                                'e.g., 30',
                                controller: _exerciseDurationController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDialogTextField(
                                'Calories Burned',
                                'e.g., 250',
                                controller: _exerciseCaloriesController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDialogTextField(
                                'Time',
                                'Select time',
                                controller: _exerciseTimeController,
                                readOnly: true,
                                suffixIcon: const Icon(
                                  Icons.access_time,
                                  size: 20,
                                ),
                                onTap: () => _selectTime(
                                  context,
                                  _exerciseTimeController,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDialogTextField(
                          'Instructions (Optional)',
                          'Any additional notes?',
                          controller: _exerciseInstructionsController,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleAddExercise();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: _isAddingExercise
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Add Exercise',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddSupplementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 700,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue, Colors.blue.withValues(alpha: 0.8)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.medication,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Supplement',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Track your vitamins & supplements',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildSupplementNameField(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildDialogTextField(
                                'Dosage',
                                'e.g., 1000 IU',
                                controller: _supplementDosageController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSupplementFrequencyDropdown(),
                        const SizedBox(height: 16),
                        _buildDialogTextField(
                          'Instructions',
                          'e.g., Take with food',
                          controller: _supplementInstructionsController,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isAddingSupplement
                            ? null
                            : _handleAddSupplement,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.blue.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: _isAddingSupplement
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Add Supplement',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddPatientDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 800,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Patient',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Register a new patient to the system',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Personal Information Section
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogTextField(
                                  'First Name',
                                  'e.g., John',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDialogTextField(
                                  'Last Name',
                                  'e.g., Doe',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogTextField(
                                  'Email',
                                  'e.g., john@example.com',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDialogTextField(
                                  'Phone',
                                  'e.g., +1 234 567 8900',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogTextField('Age', 'e.g., 35'),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: _buildGenderDropdown()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Health Information Section
                          const Text(
                            'Health Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogTextField(
                                  'Weight (kg)',
                                  'e.g., 72',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDialogTextField(
                                  'Height (cm)',
                                  'e.g., 175',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogTextField(
                                  'Blood Type',
                                  'e.g., O+',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDietPlanDropdown()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDialogTextField(
                            'Medical Conditions',
                            'Any existing conditions?',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildDialogTextField(
                            'Allergies',
                            'Any food allergies?',
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          // Add patient logic here
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Add Patient',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealTypeDropdown({String? editingMealType}) {
    final mealTypes = [
      'Breakfast',
      'Morning Snack',
      'Lunch',
      'Afternoon Snack',
      'Dinner',
      'Evening Snack',
      'Other',
    ];

    // Get already used meal types
    final usedMealTypes = _getUsedMealTypes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meal Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedMealType,
            decoration: InputDecoration(
              hintText: 'Select meal type',
              hintStyle: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.success, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            icon: Icon(Icons.arrow_drop_down, color: AppColors.success),
            dropdownColor: Colors.white,
            items: mealTypes.map((String type) {
              final apiType = _convertMealTypeToApi(type);
              final isUsed =
                  usedMealTypes.contains(apiType) && apiType != editingMealType;

              return DropdownMenuItem<String>(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      _getMealIcon(type),
                      size: 20,
                      color: isUsed ? Colors.grey : AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUsed ? Colors.grey : const Color(0xFF2D3142),
                      ),
                    ),
                    if (isUsed) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Added',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedMealType = newValue;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseTypeDropdown({String? editingExerciseType}) {
    final exerciseTypes = [
      'cardio',
      'strength',
      'flexibility',
      'balance',
      'walking',
      'yoga',
      'other',
    ];

    final exerciseTypeLabels = {
      'cardio': 'Cardio',
      'strength': 'Strength Training',
      'flexibility': 'Flexibility',
      'balance': 'Balance',
      'walking': 'Walking',
      'yoga': 'Yoga',
      'other': 'Other',
    };

    // Get already used exercise types
    final usedExerciseTypes = _getUsedExerciseTypes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exercise Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedExerciseType,
            decoration: InputDecoration(
              hintText: 'Select exercise type',
              hintStyle: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accent, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            icon: Icon(Icons.arrow_drop_down, color: AppColors.accent),
            dropdownColor: Colors.white,
            items: exerciseTypes.map((String type) {
              final isUsed =
                  usedExerciseTypes.contains(type.toLowerCase()) &&
                  type.toLowerCase() != editingExerciseType?.toLowerCase();

              return DropdownMenuItem<String>(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      _getExerciseTypeIcon(type),
                      size: 20,
                      color: isUsed ? Colors.grey : AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      exerciseTypeLabels[type] ?? type,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUsed ? Colors.grey : const Color(0xFF2D3142),
                      ),
                    ),
                    if (isUsed) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Added',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedExerciseType = newValue;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSupplementFrequencyDropdown() {
    final frequencies = [
      'Once Daily',
      'Twice Daily',
      'Three Times Daily',
      'Every Other Day',
      'Weekly',
      'As Needed',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedSupplementFrequency,
            decoration: InputDecoration(
              hintText: 'Select frequency',
              hintStyle: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
            dropdownColor: Colors.white,
            items: frequencies.map((String freq) {
              return DropdownMenuItem<String>(
                value: freq,
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 20, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      freq,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedSupplementFrequency = newValue;
              });
            },
          ),
        ),
      ],
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Icons.breakfast_dining;
      case 'Lunch':
        return Icons.lunch_dining;
      case 'Dinner':
        return Icons.dinner_dining;
      case 'Morning Snack':
      case 'Afternoon Snack':
      case 'Evening Snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  Widget _buildSupplementNameField() {
    final usedSupplementNames = _getUsedSupplementNames();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supplement Name',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 8),
        _buildDialogTextField(
          '',
          'e.g., Vitamin D3',
          controller: _supplementNameController,
        ),
        if (usedSupplementNames.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Already added: ${usedSupplementNames.map((s) => s[0].toUpperCase() + s.substring(1)).join(", ")}',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenderDropdown() {
    final genders = ['Male', 'Female', 'Other'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: 'Select gender',
              hintStyle: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
            dropdownColor: Colors.white,
            items: genders.map((String gender) {
              return DropdownMenuItem<String>(
                value: gender,
                child: Text(
                  gender,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D3142),
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {},
          ),
        ),
      ],
    );
  }

  Widget _buildDietPlanDropdown() {
    final dietPlans = [
      'Mediterranean',
      'Keto',
      'Vegan',
      'Vegetarian',
      'Paleo',
      'Low Carb',
      'Balanced',
      'Custom',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Diet Plan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: 'Select diet plan',
              hintStyle: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
            dropdownColor: Colors.white,
            items: dietPlans.map((String plan) {
              return DropdownMenuItem<String>(
                value: plan,
                child: Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      plan,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {},
          ),
        ),
      ],
    );
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
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
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

  Widget _buildDialogTextField(
    String label,
    String hint, {
    int maxLines = 1,
    TextEditingController? controller,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.success, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  // Get patients - use API data only (no fake demo data)
  List<Map<String, dynamic>> get patients => _apiPatients;

  // Sample patient data with health metrics (REMOVED - use only real API data)
  // ignore: unused_field
  final List<Map<String, dynamic>> _samplePatients = [
    {
      'name': 'Sarah Johnson',
      'id': 'PT-001',
      'age': 32,
      'gender': 'Female',
      'phone': '+1 234-567-8901',
      'email': 'sarah.j@email.com',
      'plan': 'Weight Loss Program',
      'status': 'Active',
      'avatar': 'https://i.pravatar.cc/150?u=sarah',
      // Health Metrics
      'weight': 68.5,
      'height': 165,
      'bmi': 25.2,
      'targetWeight': 62.0,
      'steps': 8542,
      'targetSteps': 10000,
      'caloriesBurned': 420,
      'caloriesIntake': 1650,
      'targetCalories': 1800,
      'waterIntake': 6,
      'targetWater': 8,
      'sleepHours': 7.5,
      'heartRate': 72,
      'bloodPressure': '120/80',
      'bloodSugar': 95,
      // Activity
      'exerciseMinutes': 45,
      'targetExercise': 60,
      'workoutType': 'Cardio & Strength',
      // Meals
      'mealsToday': [
        {'name': 'Breakfast', 'calories': 350, 'time': '08:00 AM'},
        {'name': 'Lunch', 'calories': 550, 'time': '01:00 PM'},
        {'name': 'Snack', 'calories': 150, 'time': '04:00 PM'},
        {'name': 'Dinner', 'calories': 600, 'time': '07:30 PM'},
      ],
      // Progress
      'weightProgress': [70, 69.5, 69, 68.8, 68.5],
      'lastVisit': '2 days ago',
      'nextAppointment': 'Nov 20, 2024',
    },
    {
      'name': 'Michael Chen',
      'id': 'PT-002',
      'age': 45,
      'gender': 'Male',
      'phone': '+1 234-567-8902',
      'email': 'michael.c@email.com',
      'plan': 'Diabetes Management',
      'status': 'Active',
      'avatar': 'https://i.pravatar.cc/150?u=michael',
      'weight': 82.3,
      'height': 175,
      'bmi': 26.9,
      'targetWeight': 75.0,
      'steps': 12450,
      'targetSteps': 10000,
      'caloriesBurned': 580,
      'caloriesIntake': 1850,
      'targetCalories': 2000,
      'waterIntake': 7,
      'targetWater': 8,
      'sleepHours': 6.8,
      'heartRate': 78,
      'bloodPressure': '130/85',
      'bloodSugar': 125,
      'exerciseMinutes': 60,
      'targetExercise': 60,
      'workoutType': 'Walking & Yoga',
      'mealsToday': [
        {'name': 'Breakfast', 'calories': 400, 'time': '07:30 AM'},
        {'name': 'Lunch', 'calories': 600, 'time': '12:30 PM'},
        {'name': 'Snack', 'calories': 200, 'time': '03:30 PM'},
        {'name': 'Dinner', 'calories': 650, 'time': '07:00 PM'},
      ],
      'weightProgress': [85, 84, 83.5, 83, 82.3],
      'lastVisit': '5 days ago',
      'nextAppointment': 'Nov 18, 2024',
    },
    {
      'name': 'Emma Williams',
      'id': 'PT-003',
      'age': 58,
      'gender': 'Female',
      'phone': '+1 234-567-8903',
      'email': 'emma.w@email.com',
      'plan': 'Heart Healthy Diet',
      'status': 'Active',
      'avatar': 'https://i.pravatar.cc/150?u=emma',
      'weight': 72.0,
      'height': 160,
      'bmi': 28.1,
      'targetWeight': 65.0,
      'steps': 6200,
      'targetSteps': 8000,
      'caloriesBurned': 320,
      'caloriesIntake': 1550,
      'targetCalories': 1600,
      'waterIntake': 8,
      'targetWater': 8,
      'sleepHours': 8.2,
      'heartRate': 68,
      'bloodPressure': '125/82',
      'bloodSugar': 92,
      'exerciseMinutes': 30,
      'targetExercise': 45,
      'workoutType': 'Light Walking',
      'mealsToday': [
        {'name': 'Breakfast', 'calories': 300, 'time': '08:30 AM'},
        {'name': 'Lunch', 'calories': 500, 'time': '01:00 PM'},
        {'name': 'Snack', 'calories': 150, 'time': '04:00 PM'},
        {'name': 'Dinner', 'calories': 600, 'time': '07:00 PM'},
      ],
      'weightProgress': [74, 73.5, 73, 72.5, 72.0],
      'lastVisit': 'Today',
      'nextAppointment': 'Nov 25, 2024',
    },
    {
      'name': 'James Rodriguez',
      'id': 'PT-004',
      'age': 28,
      'gender': 'Male',
      'phone': '+1 234-567-8904',
      'email': 'james.r@email.com',
      'plan': 'Sports Nutrition',
      'status': 'Active',
      'avatar': 'JR',
      'weight': 75.5,
      'height': 180,
      'bmi': 23.3,
      'targetWeight': 78.0,
      'steps': 15200,
      'targetSteps': 12000,
      'caloriesBurned': 850,
      'caloriesIntake': 2800,
      'targetCalories': 2800,
      'waterIntake': 10,
      'targetWater': 10,
      'sleepHours': 7.0,
      'heartRate': 62,
      'bloodPressure': '115/75',
      'bloodSugar': 88,
      'exerciseMinutes': 120,
      'targetExercise': 90,
      'workoutType': 'HIIT & Weight Training',
      'mealsToday': [
        {'name': 'Breakfast', 'calories': 600, 'time': '07:00 AM'},
        {'name': 'Lunch', 'calories': 800, 'time': '12:00 PM'},
        {'name': 'Snack', 'calories': 400, 'time': '03:00 PM'},
        {'name': 'Dinner', 'calories': 1000, 'time': '08:00 PM'},
      ],
      'weightProgress': [74, 74.5, 75, 75.2, 75.5],
      'lastVisit': '1 day ago',
      'nextAppointment': 'Nov 22, 2024',
    },
    {
      'name': 'Olivia Brown',
      'id': 'PT-005',
      'age': 35,
      'gender': 'Female',
      'phone': '+1 234-567-8905',
      'email': 'olivia.b@email.com',
      'plan': 'Vegan Diet Plan',
      'status': 'Active',
      'avatar': 'OB',
      'weight': 58.0,
      'height': 162,
      'bmi': 22.1,
      'targetWeight': 58.0,
      'steps': 9800,
      'targetSteps': 10000,
      'caloriesBurned': 480,
      'caloriesIntake': 1700,
      'targetCalories': 1750,
      'waterIntake': 7,
      'targetWater': 8,
      'sleepHours': 7.8,
      'heartRate': 70,
      'bloodPressure': '118/78',
      'bloodSugar': 90,
      'exerciseMinutes': 50,
      'targetExercise': 60,
      'workoutType': 'Yoga & Pilates',
      'mealsToday': [
        {'name': 'Breakfast', 'calories': 380, 'time': '08:00 AM'},
        {'name': 'Lunch', 'calories': 520, 'time': '01:00 PM'},
        {'name': 'Snack', 'calories': 180, 'time': '04:00 PM'},
        {'name': 'Dinner', 'calories': 620, 'time': '07:30 PM'},
      ],
      'weightProgress': [59, 58.8, 58.5, 58.2, 58.0],
      'lastVisit': '3 days ago',
      'nextAppointment': 'Nov 28, 2024',
    },
  ];

  List<Map<String, dynamic>> get filteredPatients {
    if (searchQuery.isEmpty) return patients;
    return patients.where((patient) {
      return patient['name'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          patient['id'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          patient['phone'].toString().contains(searchQuery);
    }).toList();
  }

  Map<String, dynamic>? get selectedPatient {
    if (filteredPatients.isEmpty) return null;
    if (selectedPatientIndex >= filteredPatients.length) {
      return filteredPatients.first;
    }
    return filteredPatients[selectedPatientIndex];
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
              title: 'All Patients',
              action: InkWell(
                onTap: _showAddPatientDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading patients...'),
                        ],
                      ),
                    )
                  : _errorMessage != null && _apiPatients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchPatients,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        // Left Side - Patient List (30%)
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.27,
                          child: _buildPatientList(),
                        ),
                        // Right Side - Patient Details (70%)
                        Expanded(child: _buildPatientDetails()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(right: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
      ),
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  selectedPatientIndex = 0;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF9E9E9E),
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // Patient List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              itemCount: filteredPatients.length,
              itemBuilder: (context, index) {
                final patient = filteredPatients[index];
                final isSelected = index == selectedPatientIndex;
                return _buildPatientListItem(patient, isSelected, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientListItem(
    Map<String, dynamic> patient,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPatientIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E5E5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Beautiful Number Label
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppColors.primaryGradient
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFF8F9FA),
                              const Color(0xFFE5E5E5),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                ),
                Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Compact Avatar with Initials
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? AppColors.primaryGradient
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accent.withValues(alpha: 0.8),
                          AppColors.accent,
                        ],
                      ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _getInitials(patient['name'] ?? ''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Compact Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    patient['name'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFF2D3142),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    patient['id'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        patient['status'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Progress bar
                  _buildProgressBar(patient),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build progress bar for patient card
  Widget _buildProgressBar(Map<String, dynamic> patient) {
    final patientId = patient['patient_id'] ?? patient['id'] ?? '';
    final progress = _calculatePatientProgress(patientId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$progress%',
              style: TextStyle(
                fontSize: 9,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 75
                  ? Colors.green
                  : progress >= 50
                  ? Colors.orange
                  : AppColors.primary,
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientDetails() {
    final patient = selectedPatient;

    // Handle empty patients list
    if (patient == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No patients found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Patients registered with your referral code will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Header
          _buildPatientHeader(patient),
          const SizedBox(height: 30),

          // Health Metrics Grid - 4 Cards
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'BMI',
                    patient['bmi'].toString(),
                    'kg/m²',
                    Icons.monitor_weight,
                    AppColors.primary,
                    onTap: () => _showBMIDialog(patient),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Weight',
                    '${patient['weight']} kg',
                    'Target: ${patient['targetWeight']} kg',
                    Icons.scale,
                    AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildStepsCard(patient)),
                const SizedBox(width: 12),
                Expanded(child: _buildCaloriesCard(patient)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Meals Today
          _buildMealsSection(patient),
          const SizedBox(height: 24),

          // Exercise Today
          _buildExerciseSection(patient),
          const SizedBox(height: 24),

          // Supplements
          _buildSupplementsSection(patient),
          const SizedBox(height: 24),

          // Weight Progress Chart
          _buildWeightProgressCard(patient),
        ],
      ),
    );
  }

  /// Get initials from patient name (e.g., "Sagar Kumbhar" -> "SK")
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Widget _buildPatientHeader(Map<String, dynamic> patient) {
    final initials = _getInitials(patient['name'] ?? '');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with initials
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (patient['name'] as String).trim().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildHeaderInfo(
                      Icons.cake_outlined,
                      '${patient['age']} years',
                    ),
                    const SizedBox(width: 16),
                    _buildHeaderInfo(Icons.person_outline, patient['gender']),
                    const SizedBox(width: 16),
                    _buildHeaderInfo(Icons.badge_outlined, patient['id']),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.restaurant_menu,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            patient['plan'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _showFollowUpDialog(patient),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.assignment_turned_in,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Follow-up',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _showFollowUpHistoryDialog(patient),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history,
                              color: Colors.deepPurple,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'History',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: _fetchPatients,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderIconButton(Icons.phone, Colors.white),
                  const SizedBox(width: 8),
                  _buildHeaderIconButton(Icons.message, Colors.white),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showPatientMenu(patient),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white70,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Last: ${patient['lastVisit']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Next: ${patient['nextAppointment']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
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
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color),
        onPressed: () {},
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withValues(alpha: 0.02)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9E9E9E),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9E9E9E),
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCard(Map<String, dynamic> patient) {
    double progress =
        (patient['steps'] as num).toDouble() /
        (patient['targetSteps'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.info.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_walk,
                      color: AppColors.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Steps Today',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${patient['steps']}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                'Goal: ${patient['targetSteps']} steps',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9E9E9E),
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _showEditStepGoalDialog(patient),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.edit, size: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesCard(Map<String, dynamic> patient) {
    double progress =
        (patient['caloriesIntake'] as num).toDouble() /
        (patient['targetCalories'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.orange.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Calories',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '${patient['caloriesBurned']} burned',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${patient['caloriesIntake']}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Goal: ${patient['targetCalories']} kcal',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9E9E9E),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSection(Map<String, dynamic> patient) {
    // Get patient ID
    final patientId = patient['patient_id'] ?? patient['id'];
    
    // Get exercises from patient data
    final exercises = patient['exercisesToday'] as List? ?? [];

    // Handle empty exercises list
    if (exercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppColors.accent.withValues(alpha: 0.02)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.2),
            width: 1.5,
          ),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Exercise',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _showAddExerciseDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Add Exercise',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No exercise data available yet',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.accent.withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accent.withValues(alpha: 0.15),
                          AppColors.accent.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Exercise',
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
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${patient['exerciseMinutes']} min',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${patient['caloriesBurned']} kcal',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (exercises.isNotEmpty)
                    InkWell(
                      onTap: () => _confirmDeleteAllExercises(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_sweep,
                              color: Colors.red,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Delete All',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (exercises.isNotEmpty) const SizedBox(width: 8),
                  InkWell(
                    onTap: _showAddExerciseDialog,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Add Exercise',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...exercises.map((exercise) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFFFAFAFA), Colors.white],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              exercise['exercise_name'] ??
                                  exercise['name'] ??
                                  'Exercise',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                exercise['exercise_type'] ??
                                    exercise['type'] ??
                                    'cardio',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Completion Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (exercise['is_completed'] == true ||
                                        exercise['is_completed'] == 1)
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      (exercise['is_completed'] == true ||
                                          exercise['is_completed'] == 1)
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : Colors.orange.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (exercise['is_completed'] == true ||
                                            exercise['is_completed'] == 1)
                                        ? Icons.check_circle
                                        : Icons.pending,
                                    size: 12,
                                    color:
                                        (exercise['is_completed'] == true ||
                                            exercise['is_completed'] == 1)
                                        ? AppColors.success
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (exercise['is_completed'] == true ||
                                            exercise['is_completed'] == 1)
                                        ? 'Completed'
                                        : 'Pending',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          (exercise['is_completed'] == true ||
                                              exercise['is_completed'] == 1)
                                          ? AppColors.success
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Color(0xFF9E9E9E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              exercise['time'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.timer,
                              size: 14,
                              color: Color(0xFF9E9E9E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              exercise['duration'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange.withValues(alpha: 0.15),
                          Colors.orange.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${exercise['calories']}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'kcal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showEditExerciseDialog(exercise),
                    icon: const Icon(Icons.edit),
                    color: AppColors.primary,
                    iconSize: 20,
                    tooltip: 'Edit Exercise',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _deleteExercise(patientId, exercise['id']),
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    iconSize: 20,
                    tooltip: 'Delete Exercise',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMealsSection(Map<String, dynamic> patient) {
    // Get patient ID
    final patientId = patient['patient_id'] ?? patient['id'];
    
    final meals = patient['mealsToday'] as List? ?? [];

    // Handle empty meals list
    if (meals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppColors.success.withValues(alpha: 0.02)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.2),
            width: 1.5,
          ),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.restaurant,
                        color: AppColors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Meals",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _showAddMealDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.success,
                          AppColors.success.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Add Meal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No meal data available yet',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.success.withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Meals Today',
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
                  Text(
                    '${meals.length} meals',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (meals.isNotEmpty)
                    InkWell(
                      onTap: () => _confirmDeleteAllMeals(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.red,
                              Colors.red.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_sweep,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Delete All',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showAddMealDialog,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.success,
                            AppColors.success.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Add Meal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...meals.map((meal) {
            final mealType = meal['type'] ?? 'breakfast';
            final mealTypeColor = _getMealTypeColor(mealType);
            final mealTypeIcon = _getMealTypeIcon(mealType);
            final mealTypeDisplay = _convertMealTypeToDisplay(mealType);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFFFAFAFA), Colors.white],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 60,
                    decoration: BoxDecoration(
                      color: mealTypeColor,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: mealTypeColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: mealTypeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: mealTypeColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(mealTypeIcon, color: mealTypeColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal['meal_name'] ?? meal['name'] ?? 'Meal',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: mealTypeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: mealTypeColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                mealTypeDisplay,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: mealTypeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Completion Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (meal['is_completed'] == true ||
                                        meal['is_completed'] == 1)
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      (meal['is_completed'] == true ||
                                          meal['is_completed'] == 1)
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : Colors.orange.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (meal['is_completed'] == true ||
                                            meal['is_completed'] == 1)
                                        ? Icons.check_circle
                                        : Icons.pending,
                                    size: 12,
                                    color:
                                        (meal['is_completed'] == true ||
                                            meal['is_completed'] == 1)
                                        ? AppColors.success
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (meal['is_completed'] == true ||
                                            meal['is_completed'] == 1)
                                        ? 'Completed'
                                        : 'Pending',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          (meal['is_completed'] == true ||
                                              meal['is_completed'] == 1)
                                          ? AppColors.success
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              meal['time'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange.withValues(alpha: 0.15),
                          Colors.orange.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${meal['calories']}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'kcal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showEditMealDialog(meal),
                    icon: const Icon(Icons.edit),
                    color: AppColors.primary,
                    iconSize: 20,
                    tooltip: 'Edit Meal',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _deleteMeal(patientId, meal['id']),
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    iconSize: 20,
                    tooltip: 'Delete Meal',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _clearFollowUpForm() {
    _weightController.clear();
    _sleepController.clear();
    _notesController.clear();
    _cravingsController.clear();
  }

  Future<void> _saveFollowUp(String patientId) async {
    final weight = double.tryParse(_weightController.text);
    final sleep = double.tryParse(_sleepController.text);
    final cravings = _cravingsController.text;
    final notes = _notesController.text;

    if (weight == null && sleep == null && cravings.isEmpty && notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one detail')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiEndpoints.patientFollowups(patientId)}',
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
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Follow-up recorded successfully'),
              backgroundColor: AppColors.primary,
            ),
          );
          _fetchPatients();
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to save follow-up');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFollowUpHistory(
    String patientId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiEndpoints.patientFollowups(patientId)}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching follow-up history: $e');
      return [];
    }
  }

  void _showFollowUpHistoryDialog(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 800,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.deepPurple.shade700],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Follow-up History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          patient['name'] ?? 'Patient',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchFollowUpHistory(patient['patient_id']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final followups = snapshot.data ?? [];

                    if (followups.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No follow-up history yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: followups.length,
                      itemBuilder: (context, index) {
                        final followup = followups[index];
                        return _buildFollowUpHistoryCard(followup);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowUpHistoryCard(Map<String, dynamic> followup) {
    final date = followup['date'] ?? '';
    final createdAt = followup['created_at'] ?? '';
    final weight = followup['weight'];
    final sleepHours = followup['sleep_hours'];
    final cravings = followup['cravings'] ?? '';
    final notes = followup['notes'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
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
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.deepPurple,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    if (createdAt.isNotEmpty)
                      Text(
                        _formatTime(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (weight != null) ...[
                Expanded(
                  child: _buildHistoryInfoItem(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Weight',
                    value: '${weight} kg',
                    color: Colors.blue,
                  ),
                ),
              ],
              if (sleepHours != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHistoryInfoItem(
                    icon: Icons.bedtime_outlined,
                    label: 'Sleep',
                    value: '${sleepHours} hrs',
                    color: Colors.purple,
                  ),
                ),
              ],
            ],
          ),
          if (cravings.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildHistoryInfoItem(
              icon: Icons.fastfood_outlined,
              label: 'Cravings',
              value: cravings,
              color: Colors.orange,
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildHistoryInfoItem(
              icon: Icons.notes,
              label: 'Notes',
              value: notes,
              color: Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Yesterday';
      } else if (difference < 7) {
        return '$difference days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (e) {
      return '';
    }
  }

  void _showFollowUpDialog(Map<String, dynamic> patient) {
    _clearFollowUpForm(); // Clear form before showing
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 700,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Proper Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Patient Follow-up',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Recording progress for ${patient['name']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Form Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Weight & Sleep
                        Row(
                          children: [
                            Expanded(
                              child: _buildFollowUpField(
                                label: 'Current Weight (kg)',
                                controller: _weightController,
                                icon: Icons.monitor_weight_outlined,
                                hint: 'e.g. 72.5',
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildFollowUpField(
                                label: 'Sleep Duration (hrs)',
                                controller: _sleepController,
                                icon: Icons.bedtime_outlined,
                                hint: 'e.g. 7',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Cravings
                        _buildFollowUpField(
                          label: 'Any Cravings?',
                          controller: _cravingsController,
                          icon: Icons.fastfood_outlined,
                          hint: 'e.g. Sweets, Salty',
                        ),
                        const SizedBox(height: 20),

                        // Clinical Notes
                        _buildFollowUpField(
                          label: 'Diet Adherence & Clinical Notes',
                          controller: _notesController,
                          icon: Icons.notes,
                          hint:
                              'Document patient adherence and any difficulties encountered...',
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                // Proper Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: _isLoading
                            ? null
                            : () => _saveFollowUp(patient['patient_id']),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : AppColors.primaryGradient,
                            color: _isLoading ? Colors.grey : null,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              if (!_isLoading)
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: _isLoading
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
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

  Widget _buildFollowUpField({
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9E9E9E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.success, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplementsSection(Map<String, dynamic> patient) {
    // Get supplements from patient data
    final supplements = patient['supplementsToday'] as List? ?? [];

    // Handle empty supplements list
    if (supplements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue.withValues(alpha: 0.02)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.2),
            width: 1.5,
          ),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.medication,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Supplements & Vitamins',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _showAddSupplementDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue,
                          Colors.blue.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Add Supplement',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No supplement data available yet',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withValues(alpha: 0.15),
                      Colors.blue.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.medication,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Supplements & Vitamins',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${supplements.where((s) => s['status'] == 'Taken').length}/${supplements.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _showAddSupplementDialog,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue, Colors.blue.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Add Supplement',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...supplements.map((supplement) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFFFAFAFA), Colors.white],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue,
                          Colors.blue.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.withValues(alpha: 0.8),
                          Colors.blue,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medication_liquid,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                supplement['supplement_name'] ??
                                    supplement['name'] ??
                                    'Supplement',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3142),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            if (supplement['dosage'] != null &&
                                (supplement['dosage'] as String)
                                    .isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  supplement['dosage'] as String,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.repeat,
                              size: 14,
                              color: Color(0xFF9E9E9E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              supplement['frequency'] as String? ??
                                  'once daily',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Completion Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (supplement['is_completed'] == true ||
                                        supplement['is_completed'] == 1)
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      (supplement['is_completed'] == true ||
                                          supplement['is_completed'] == 1)
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : Colors.orange.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (supplement['is_completed'] == true ||
                                            supplement['is_completed'] == 1)
                                        ? Icons.check_circle
                                        : Icons.pending,
                                    size: 12,
                                    color:
                                        (supplement['is_completed'] == true ||
                                            supplement['is_completed'] == 1)
                                        ? AppColors.success
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (supplement['is_completed'] == true ||
                                            supplement['is_completed'] == 1)
                                        ? 'Completed'
                                        : 'Pending',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          (supplement['is_completed'] == true ||
                                              supplement['is_completed'] == 1)
                                          ? AppColors.success
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showEditSupplementDialog(supplement),
                    icon: const Icon(Icons.edit),
                    color: AppColors.primary,
                    iconSize: 20,
                    tooltip: 'Edit Supplement',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    onPressed: () => _confirmDeleteSupplement(supplement),
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    iconSize: 20,
                    tooltip: 'Delete Supplement',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeightProgressCard(Map<String, dynamic> patient) {
    final progressRaw = patient['weightProgress'] as List? ?? [];
    final progress = progressRaw.map((e) => (e as num).toDouble()).toList();

    // Handle empty progress list
    if (progress.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.trending_down,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Weight Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No weight data available yet',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.primary.withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.trending_down,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Weight Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(progress.first - progress.last).toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: progress.asMap().entries.map((entry) {
                final index = entry.key;
                final weight = entry.value;
                final maxWeight = progress.reduce((a, b) => a > b ? a : b);
                final minWeight = progress.reduce((a, b) => a < b ? a : b);
                final barHeight =
                    ((weight - minWeight) / (maxWeight - minWeight)) * 75 + 20;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$weight',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          height: barHeight,
                          constraints: const BoxConstraints(maxHeight: 95),
                          decoration: BoxDecoration(
                            gradient: index == progress.length - 1
                                ? AppColors.primaryGradient
                                : LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.3),
                                      AppColors.primary.withValues(alpha: 0.1),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'W${index + 1}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditStepGoalDialog(Map<String, dynamic> patient) {
    final TextEditingController controller = TextEditingController(
      text: patient['targetSteps'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, AppColors.primary.withValues(alpha: 0.02)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_walk,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Step Goal',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set daily target for ${patient['name']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Input Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Steps Goal',
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    hintText: '10000',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    suffixText: 'steps',
                    suffixStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(Icons.flag, color: AppColors.primary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.08),
                      Colors.blue.withValues(alpha: 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommended: 10,000 steps per day',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Valid range: 1,000 - 50,000 steps',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final newGoal = int.tryParse(controller.text);
                      if (newGoal == null ||
                          newGoal < 1000 ||
                          newGoal > 50000) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.white),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Please enter a valid step goal (1,000 - 50,000)',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red[600],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return;
                      }

                      // Update step goal via API
                      final patientId =
                          (patient['patient_id'] ?? patient['id'] ?? '')
                              .toString();

                      debugPrint(
                        '🔍 Updating step goal for patient: $patientId',
                      );
                      debugPrint('📊 New goal: $newGoal');
                      debugPrint('📦 Patient data: ${patient.toString()}');

                      if (patientId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.white),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Patient ID not found',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red[600],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return;
                      }

                      final response = await PlanService.updateStepGoal(
                        patientId,
                        newGoal,
                      );

                      if (!mounted) return;

                      if (response.success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Step goal updated to ${newGoal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} steps',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green[600],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );

                        // Refresh patient data
                        setState(() {
                          patient['targetSteps'] = newGoal;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Failed to update: ${response.message}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red[600],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
