class ScheduleBlockModel {
  final int? id;
  final int doctorId;
  final DateTime blockDate;
  final String startTime;
  final String endTime;
  final String? reason;

  const ScheduleBlockModel({
    this.id,
    required this.doctorId,
    required this.blockDate,
    required this.startTime,
    required this.endTime,
    this.reason,
  });

  bool get isFullDay => startTime == '00:00' && endTime == '23:59';

  factory ScheduleBlockModel.fromJson(Map<String, dynamic> json) {
    final d = json['attributes'] as Map<String, dynamic>? ?? json;
    return ScheduleBlockModel(
      id: json['id'] as int?,
      doctorId: (d['doctorId'] as num?)?.toInt() ?? 0,
      blockDate: DateTime.tryParse(d['blockDate'] as String? ?? '') ?? DateTime.now(),
      startTime: d['startTime'] as String? ?? '00:00',
      endTime: d['endTime'] as String? ?? '23:59',
      reason: d['reason'] as String?,
    );
  }
}
