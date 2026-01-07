class Meal {
  final int? id;
  final String? patientId;
  final int? doctorId;
  final String mealType;
  final String mealName;
  final String? description;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fats;
  final String? time;
  final String date;
  final bool isCompleted;
  final DateTime? createdAt;

  Meal({
    this.id,
    this.patientId,
    this.doctorId,
    required this.mealType,
    required this.mealName,
    this.description,
    this.calories,
    this.protein,
    this.carbs,
    this.fats,
    this.time,
    required this.date,
    this.isCompleted = false,
    this.createdAt,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      patientId: json['patient_id']?.toString(),
      doctorId: json['doctor_id'] is String ? int.tryParse(json['doctor_id']) : json['doctor_id'],
      mealType: json['meal_type'] ?? '',
      mealName: json['meal_name'] ?? '',
      description: json['description'],
      calories: json['calories'] is String ? int.tryParse(json['calories']) : json['calories'],
      protein: json['protein'] != null ? (json['protein'] is String ? double.tryParse(json['protein']) : (json['protein'] as num?)?.toDouble()) : null,
      carbs: json['carbs'] != null ? (json['carbs'] is String ? double.tryParse(json['carbs']) : (json['carbs'] as num?)?.toDouble()) : null,
      fats: json['fats'] != null ? (json['fats'] is String ? double.tryParse(json['fats']) : (json['fats'] as num?)?.toDouble()) : null,
      time: json['time'],
      date: json['date'] ?? '',
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (doctorId != null) 'doctor_id': doctorId,
      'meal_type': mealType,
      'meal_name': mealName,
      if (description != null) 'description': description,
      if (calories != null) 'calories': calories,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fats != null) 'fats': fats,
      if (time != null) 'time': time,
      'date': date,
      'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  // Meal types
  static const List<String> mealTypes = [
    'breakfast',
    'mid_morning',
    'lunch',
    'evening_snack',
    'dinner',
  ];

  static String getMealTypeDisplay(String type) {
    switch (type) {
      case 'breakfast':
        return 'Breakfast';
      case 'mid_morning':
        return 'Mid-Morning';
      case 'lunch':
        return 'Lunch';
      case 'evening_snack':
        return 'Evening Snack';
      case 'dinner':
        return 'Dinner';
      default:
        return type;
    }
  }
}

