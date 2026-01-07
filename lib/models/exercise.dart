class Exercise {
  final int? id;
  final String? patientId;
  final int? doctorId;
  final String exerciseName;
  final int? durationMins;
  final int? caloriesBurn;
  final String? instructions;
  final String? exerciseType;
  final String date;
  final bool isCompleted;
  final DateTime? createdAt;

  Exercise({
    this.id,
    this.patientId,
    this.doctorId,
    required this.exerciseName,
    this.durationMins,
    this.caloriesBurn,
    this.instructions,
    this.exerciseType,
    required this.date,
    this.isCompleted = false,
    this.createdAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      patientId: json['patient_id']?.toString(),
      doctorId: json['doctor_id'] is String ? int.tryParse(json['doctor_id']) : json['doctor_id'],
      exerciseName: json['exercise_name'] ?? '',
      durationMins: json['duration_mins'] is String ? int.tryParse(json['duration_mins']) : json['duration_mins'],
      caloriesBurn: json['calories_burn'] is String ? int.tryParse(json['calories_burn']) : json['calories_burn'],
      instructions: json['instructions'],
      exerciseType: json['exercise_type'],
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
      'exercise_name': exerciseName,
      if (durationMins != null) 'duration_mins': durationMins,
      if (caloriesBurn != null) 'calories_burn': caloriesBurn,
      if (instructions != null) 'instructions': instructions,
      if (exerciseType != null) 'exercise_type': exerciseType,
      'date': date,
      'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  // Common exercise types
  static const List<String> exerciseTypes = [
    'cardio',
    'strength',
    'flexibility',
    'balance',
    'walking',
    'yoga',
    'other',
  ];

  static String getExerciseTypeDisplay(String type) {
    switch (type) {
      case 'cardio':
        return 'Cardio';
      case 'strength':
        return 'Strength Training';
      case 'flexibility':
        return 'Flexibility';
      case 'balance':
        return 'Balance';
      case 'walking':
        return 'Walking';
      case 'yoga':
        return 'Yoga';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }
}

