class AvailabilityModel {
  final int? id;
  final int doctorId;
  final int dayOfWeek; // 0=Mon … 6=Sun
  final String startTime; // HH:mm
  final String endTime;   // HH:mm
  final bool isActive;

  const AvailabilityModel({
    this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  static const dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const dayLabelsFull = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    final d = json['attributes'] as Map<String, dynamic>? ?? json;
    return AvailabilityModel(
      id: json['id'] as int?,
      doctorId: (d['doctorId'] as num?)?.toInt() ?? 0,
      dayOfWeek: (d['dayOfWeek'] as num?)?.toInt() ?? 0,
      startTime: d['startTime'] as String? ?? '08:00',
      endTime: d['endTime'] as String? ?? '18:00',
      isActive: d['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'isActive': isActive,
      };

  AvailabilityModel copyWith({
    int? id,
    int? doctorId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isActive,
  }) =>
      AvailabilityModel(
        id: id ?? this.id,
        doctorId: doctorId ?? this.doctorId,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        isActive: isActive ?? this.isActive,
      );
}
