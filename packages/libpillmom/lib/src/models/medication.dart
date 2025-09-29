class Medication {
  final int? id;
  final String name;
  final String dosage;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Reminder>? reminders;

  Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.description,
    this.createdAt,
    this.updatedAt,
    this.reminders,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      reminders: json['reminders'] != null
          ? (json['reminders'] as List)
              .map((r) => Reminder.fromJson(r))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'dosage': dosage,
      'description': description,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (reminders != null)
        'reminders': reminders!.map((r) => r.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Medication{id: $id, name: $name, dosage: $dosage}';
  }
}

class Reminder {
  final int? id;
  final int medicationId;
  final String time;
  final String days;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Medication? medication;

  Reminder({
    this.id,
    required this.medicationId,
    required this.time,
    required this.days,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.medication,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      medicationId: json['medication_id'],
      time: json['time'],
      days: json['days'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      medication: json['medication'] != null
          ? Medication.fromJson(json['medication'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'medication_id': medicationId,
      'time': time,
      'days': days,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (medication != null) 'medication': medication!.toJson(),
    };
  }

  @override
  String toString() {
    return 'Reminder{id: $id, medicationId: $medicationId, time: $time, days: $days, isActive: $isActive}';
  }
}