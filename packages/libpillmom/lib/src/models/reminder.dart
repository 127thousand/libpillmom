import 'dart:convert';

class Reminder {
  final int? id;
  final int medicationId;
  final String time;
  final String days;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Reminder({
    this.id,
    required this.medicationId,
    required this.time,
    required this.days,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  })  : createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medication_id': medicationId,
      'time': time,
      'days': days,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      medicationId: json['medication_id'],
      time: json['time'],
      days: json['days'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now().toUtc(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now().toUtc(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() {
    return 'Reminder(id: $id, medicationId: $medicationId, time: $time, days: $days, isActive: $isActive)';
  }
}