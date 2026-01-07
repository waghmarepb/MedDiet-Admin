class WeightTarget {
  final int? id;
  final String? patientId;
  final int? doctorId;
  final double currentWeight;
  final double targetWeight;
  final String? targetDate;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;

  WeightTarget({
    this.id,
    this.patientId,
    this.doctorId,
    required this.currentWeight,
    required this.targetWeight,
    this.targetDate,
    this.notes,
    this.isActive = true,
    this.createdAt,
  });

  factory WeightTarget.fromJson(Map<String, dynamic> json) {
    return WeightTarget(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      patientId: json['patient_id']?.toString(),
      doctorId: json['doctor_id'] is String ? int.tryParse(json['doctor_id']) : json['doctor_id'],
      currentWeight: json['current_weight'] != null 
          ? (json['current_weight'] is String 
              ? double.tryParse(json['current_weight']) ?? 0.0 
              : (json['current_weight'] as num).toDouble())
          : 0.0,
      targetWeight: json['target_weight'] != null 
          ? (json['target_weight'] is String 
              ? double.tryParse(json['target_weight']) ?? 0.0 
              : (json['target_weight'] as num).toDouble())
          : 0.0,
      targetDate: json['target_date'],
      notes: json['notes'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_weight': currentWeight,
      'target_weight': targetWeight,
      if (targetDate != null) 'target_date': targetDate,
      if (notes != null) 'notes': notes,
    };
  }

  double get weightDifference => currentWeight - targetWeight;
  bool get isWeightLossGoal => targetWeight < currentWeight;
  bool get isWeightGainGoal => targetWeight > currentWeight;
}

