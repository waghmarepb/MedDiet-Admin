class Supplement {
  final int? id;
  final String? patientId;
  final int? doctorId;
  final String supplementName;
  final String? dosage;
  final String? frequency;
  final String? instructions;
  final String startDate;
  final String? endDate;
  final bool isActive;
  final bool isCompleted;
  final DateTime? createdAt;

  Supplement({
    this.id,
    this.patientId,
    this.doctorId,
    required this.supplementName,
    this.dosage,
    this.frequency,
    this.instructions,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.isCompleted = false,
    this.createdAt,
  });

  factory Supplement.fromJson(Map<String, dynamic> json) {
    return Supplement(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      patientId: json['patient_id']?.toString(),
      doctorId: json['doctor_id'] is String ? int.tryParse(json['doctor_id']) : json['doctor_id'],
      supplementName: json['supplement_name'] ?? '',
      dosage: json['dosage'],
      frequency: json['frequency'],
      instructions: json['instructions'],
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (doctorId != null) 'doctor_id': doctorId,
      'supplement_name': supplementName,
      if (dosage != null) 'dosage': dosage,
      if (frequency != null) 'frequency': frequency,
      if (instructions != null) 'instructions': instructions,
      'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      'is_active': isActive,
      'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  // Common frequency options
  static const List<String> frequencyOptions = [
    'once daily',
    'twice daily',
    'three times daily',
    'once weekly',
    'as needed',
    'with meals',
    'before meals',
    'after meals',
  ];
}

