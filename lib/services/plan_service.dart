import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import '../constants/api_endpoints.dart';
import '../models/meal.dart';
import '../models/exercise.dart';
import '../models/supplement.dart';
import '../models/weight_target.dart';
import 'auth_service.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({required this.success, required this.message, this.data});
}

class PlanService {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AuthService.token != null) 'Authorization': 'Bearer ${AuthService.token}',
      };

  // ============================================
  // MEAL METHODS
  // ============================================

  /// Get all meals for a patient
  static Future<ApiResponse<List<Meal>>> getMeals(String patientId, {String? date}) async {
    try {
      var url = '${ApiConfig.baseUrl}${ApiEndpoints.patientMeals(patientId)}';
      if (date != null) {
        url += '?date=$date';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        final meals = data.map((e) => Meal.fromJson(e)).toList();
        return ApiResponse(success: true, message: 'Meals fetched successfully', data: meals);
      } else {
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to fetch meals');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  /// Add a new meal for patient
  static Future<ApiResponse<Meal>> addMeal(String patientId, Meal meal) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      debugPrint('[$timestamp] ========== ADD MEAL START ==========');
      debugPrint('[$timestamp] Adding meal for patient: $patientId');
      debugPrint('[$timestamp] Meal data: ${jsonEncode(meal.toJson())}');
      debugPrint('[$timestamp] API URL: ${ApiConfig.baseUrl}${ApiEndpoints.patientMeals(patientId)}');
      debugPrint('[$timestamp] Headers: $_headers');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patientMeals(patientId)}'),
        headers: _headers,
        body: jsonEncode(meal.toJson()),
      );

      debugPrint('[$timestamp] Response status: ${response.statusCode}');
      debugPrint('[$timestamp] Response body: ${response.body}');

      final json = jsonDecode(response.body);

      if (response.statusCode == 201 && json['success'] == true) {
        debugPrint('[$timestamp] ✅ Meal added successfully');
        debugPrint('[$timestamp] ========== ADD MEAL END ==========');
        return ApiResponse(
          success: true,
          message: 'Meal added successfully',
          data: Meal.fromJson(json['data']),
        );
      } else {
        debugPrint('[$timestamp] ❌ Failed to add meal: ${json['message']}');
        debugPrint('[$timestamp] Full response: $json');
        debugPrint('[$timestamp] ========== ADD MEAL END ==========');
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to add meal');
      }
    } catch (e, stackTrace) {
      debugPrint('[$timestamp] ❌ ERROR adding meal: $e');
      debugPrint('[$timestamp] Stack trace: $stackTrace');
      debugPrint('[$timestamp] ========== ADD MEAL END ==========');
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  /// Update a meal
  static Future<ApiResponse<Meal>> updateMeal(String patientId, String mealId, Meal meal) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patientMeal(patientId, mealId)}'),
        headers: _headers,
        body: jsonEncode(meal.toJson()),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return ApiResponse(
          success: true,
          message: 'Meal updated successfully',
          data: Meal.fromJson(json['data']),
        );
      } else {
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to update meal');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  /// Delete a meal
  static Future<ApiResponse<void>> deleteMeal(String patientId, String mealId) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      debugPrint('[$timestamp] 🗑️ Deleting meal $mealId for patient $patientId');
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patientMeal(patientId, mealId)}'),
        headers: _headers,
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        debugPrint('[$timestamp] ✅ Meal deleted successfully');
        return ApiResponse(success: true, message: 'Meal deleted successfully');
      } else {
        debugPrint('[$timestamp] ❌ Failed to delete meal: ${json['message']}');
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to delete meal');
      }
    } catch (e, stackTrace) {
      debugPrint('[$timestamp] ❌ Error deleting meal: $e');
      debugPrint('Stack trace: $stackTrace');
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  /// Delete all meals for a patient on a specific date
  static Future<ApiResponse<int>> deleteAllMeals(String patientId, {String? date}) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      debugPrint('[$timestamp] 🗑️ Fetching all meals to delete for patient $patientId');
      
      // First, get all meals for the date
      final mealsResponse = await getMeals(patientId, date: date);
      
      if (!mealsResponse.success || mealsResponse.data == null) {
        return ApiResponse(success: false, message: 'Failed to fetch meals');
      }
      
      final meals = mealsResponse.data!;
      if (meals.isEmpty) {
        debugPrint('[$timestamp] ℹ️ No meals to delete');
        return ApiResponse(success: true, message: 'No meals to delete', data: 0);
      }
      
      debugPrint('[$timestamp] 🗑️ Deleting ${meals.length} meals...');
      
      // Delete each meal
      int deletedCount = 0;
      int failedCount = 0;
      
      for (var meal in meals) {
        final deleteResponse = await deleteMeal(patientId, meal.id.toString());
        if (deleteResponse.success) {
          deletedCount++;
        } else {
          failedCount++;
          debugPrint('[$timestamp] ❌ Failed to delete meal ${meal.id}: ${deleteResponse.message}');
        }
      }
      
      debugPrint('[$timestamp] ✅ Deleted $deletedCount meals, $failedCount failed');
      
      if (failedCount == 0) {
        return ApiResponse(
          success: true, 
          message: 'All $deletedCount meals deleted successfully',
          data: deletedCount,
        );
      } else {
        return ApiResponse(
          success: true, 
          message: 'Deleted $deletedCount meals, $failedCount failed',
          data: deletedCount,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[$timestamp] ❌ Error in deleteAllMeals: $e');
      debugPrint('Stack trace: $stackTrace');
      return ApiResponse(success: false, message: 'Error: $e', data: 0);
    }
  }

  // ============================================
  // EXERCISE METHODS
  // ============================================

  /// Get all exercises for a patient
  static Future<ApiResponse<List<Exercise>>> getExercises(String patientId, {String? date}) async {
    try {
      var url = '${ApiConfig.baseUrl}${ApiEndpoints.patientExercises(patientId)}';
      if (date != null) {
        url += '?date=$date';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        final exercises = data.map((e) => Exercise.fromJson(e)).toList();
        return ApiResponse(success: true, message: 'Exercises fetched successfully', data: exercises);
      } else {
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to fetch exercises');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  /// Add a new exercise for patient
  static Future<ApiResponse<Exercise>> addExercise(String patientId, Exercise exercise) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      debugPrint('[$timestamp] Adding exercise for patient: $patientId');
      debugPrint('[$timestamp] Exercise data: ${jsonEncode(exercise.toJson())}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patientExercises(patientId)}'),
        headers: _headers,
        body: jsonEncode(exercise.toJson()),
      );

      debugPrint('[$timestamp] Response status: ${response.statusCode}');
      debugPrint('[$timestamp] Response body: ${response.body}');

      final json = jsonDecode(response.body);

      if (response.statusCode == 201 && json['success'] == true) {
        debugPrint('[$timestamp] Exercise added successfully');
        return ApiResponse(
          success: true,
          message: 'Exercise added successfully',
          data: Exercise.fromJson(json['data']),
        );
      } else {
        debugPrint('[$timestamp] Failed to add exercise: ${json['message']}');
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to add exercise');
      }
    } catch (e) {
      debugPrint('[$timestamp] Error adding exercise: $e');
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  /// Update an exercise
  static Future<ApiResponse<Exercise>> updateExercise(String patientId, String exerciseId, Exercise exercise) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      final url = '${ApiConfig.baseUrl}${ApiEndpoints.patientExercise(patientId, exerciseId)}';
      final body = jsonEncode(exercise.toJson());
      
      debugPrint('[$timestamp] UPDATE EXERCISE REQUEST:');
      debugPrint('[$timestamp] URL: $url');
      debugPrint('[$timestamp] Patient ID: $patientId');
      debugPrint('[$timestamp] Exercise ID: $exerciseId');
      debugPrint('[$timestamp] Body: $body');
      
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: body,
      );

      debugPrint('[$timestamp] Response status: ${response.statusCode}');
      debugPrint('[$timestamp] Response body: ${response.body}');

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        debugPrint('[$timestamp] ✅ Exercise updated successfully');
        return ApiResponse(
          success: true,
          message: 'Exercise updated successfully',
          data: Exercise.fromJson(json['data']),
        );
      } else {
        debugPrint('[$timestamp] ❌ Update failed: ${json['message']}');
        return ApiResponse(
          success: false, 
          message: json['message'] ?? 'Failed to update exercise'
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[$timestamp] ❌ EXCEPTION in updateExercise: $e');
      debugPrint('[$timestamp] Stack trace: $stackTrace');
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  /// Delete an exercise
  static Future<ApiResponse<void>> deleteExercise(String patientId, String exerciseId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patientExercise(patientId, exerciseId)}'),
        headers: _headers,
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return ApiResponse(success: true, message: 'Exercise deleted successfully');
      } else {
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to delete exercise');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  // ============================================
  // SUPPLEMENT METHODS
  // ============================================

  /// Get all supplements for a patient
  static Future<ApiResponse<List<Supplement>>> getSupplements(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patientSupplements(patientId)}'),
        headers: _headers,
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        final supplements = data.map((e) => Supplement.fromJson(e)).toList();
        return ApiResponse(success: true, message: 'Supplements fetched successfully', data: supplements);
      } else {
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to fetch supplements');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  /// Add a new supplement for patient
  static Future<ApiResponse<Supplement>> addSupplement(String patientId, Supplement supplement) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      debugPrint('[$timestamp] Adding supplement for patient: $patientId');
      debugPrint('[$timestamp] Supplement data: ${jsonEncode(supplement.toJson())}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patientSupplements(patientId)}'),
        headers: _headers,
        body: jsonEncode(supplement.toJson()),
      );

      debugPrint('[$timestamp] Response status: ${response.statusCode}');
      debugPrint('[$timestamp] Response body: ${response.body}');

      final json = jsonDecode(response.body);

      if (response.statusCode == 201 && json['success'] == true) {
        debugPrint('[$timestamp] Supplement added successfully');
        return ApiResponse(
          success: true,
          message: 'Supplement added successfully',
          data: Supplement.fromJson(json['data']),
        );
      } else {
        debugPrint('[$timestamp] Failed to add supplement: ${json['message']}');
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to add supplement');
      }
    } catch (e) {
      debugPrint('[$timestamp] Error adding supplement: $e');
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  /// Update a supplement
  static Future<ApiResponse<Supplement>> updateSupplement(String patientId, String supplementId, Supplement supplement) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patientSupplement(patientId, supplementId)}'),
        headers: _headers,
        body: jsonEncode(supplement.toJson()),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return ApiResponse(
          success: true,
          message: 'Supplement updated successfully',
          data: Supplement.fromJson(json['data']),
        );
      } else {
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to update supplement');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  /// Delete a supplement
  static Future<ApiResponse<void>> deleteSupplement(String patientId, String supplementId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patientSupplement(patientId, supplementId)}'),
        headers: _headers,
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return ApiResponse(success: true, message: 'Supplement deleted successfully');
      } else {
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to delete supplement');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  // ============================================
  // WEIGHT TARGET METHODS
  // ============================================

  /// Get weight target for a patient
  static Future<ApiResponse<WeightTarget?>> getWeightTarget(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patientWeightTarget(patientId)}'),
        headers: _headers,
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        if (json['data'] != null) {
          return ApiResponse(
            success: true,
            message: 'Weight target fetched successfully',
            data: WeightTarget.fromJson(json['data']),
          );
        } else {
          return ApiResponse(success: true, message: 'No weight target set', data: null);
        }
      } else {
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to fetch weight target');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  /// Set weight target for patient
  static Future<ApiResponse<WeightTarget>> setWeightTarget(String patientId, WeightTarget target) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      debugPrint('[$timestamp] Setting weight target for patient: $patientId');
      debugPrint('[$timestamp] Weight target data: ${jsonEncode(target.toJson())}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patientWeightTarget(patientId)}'),
        headers: _headers,
        body: jsonEncode(target.toJson()),
      );

      debugPrint('[$timestamp] Response status: ${response.statusCode}');
      debugPrint('[$timestamp] Response body: ${response.body}');

      final json = jsonDecode(response.body);

      if (response.statusCode == 201 && json['success'] == true) {
        debugPrint('[$timestamp] Weight target set successfully');
        return ApiResponse(
          success: true,
          message: 'Weight target set successfully',
          data: WeightTarget.fromJson(json['data']),
        );
      } else {
        debugPrint('[$timestamp] Failed to set weight target: ${json['message']}');
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to set weight target');
      }
    } catch (e) {
      debugPrint('[$timestamp] Error setting weight target: $e');
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  /// Update weight target
  static Future<ApiResponse<WeightTarget>> updateWeightTarget(String patientId, String targetId, WeightTarget target) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patientWeightTargetUpdate(patientId, targetId)}'),
        headers: _headers,
        body: jsonEncode(target.toJson()),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return ApiResponse(
          success: true,
          message: 'Weight target updated successfully',
          data: WeightTarget.fromJson(json['data']),
        );
      } else {
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to update weight target');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  // ============================================
  // STEPS METHODS
  // ============================================

  /// Update patient's daily step goal
  static Future<ApiResponse<Map<String, dynamic>>> updateStepGoal(String patientId, int targetSteps) async {
    try {
      final url = '${ApiConfig.baseUrl}/doctor/patient/$patientId/steps/goal';

      debugPrint('📝 Updating step goal for patient: $patientId');
      debugPrint('URL: $url');
      debugPrint('Target Steps: $targetSteps');

      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({'target_steps': targetSteps}),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return ApiResponse(
          success: true,
          message: 'Step goal updated successfully',
          data: json['data'],
        );
      } else {
        return ApiResponse(success: false, message: json['message'] ?? 'Failed to update step goal');
      }
    } catch (e) {
      debugPrint('❌ Error updating step goal: $e');
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }
}

