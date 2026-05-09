import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class AdminStats {
  final int totalPatients;
  final int totalDoctors;
  final int totalAppointments;
  final int todayAppointments;
  final int pendingAppointments;
  final int confirmedAppointments;
  final int completedAppointments;
  final int totalPrescriptions;
  final int totalInvoices;
  final int pendingInvoices;
  final double totalRevenue;

  const AdminStats({
    required this.totalPatients,
    required this.totalDoctors,
    required this.totalAppointments,
    required this.todayAppointments,
    required this.pendingAppointments,
    required this.confirmedAppointments,
    required this.completedAppointments,
    required this.totalPrescriptions,
    required this.totalInvoices,
    required this.pendingInvoices,
    required this.totalRevenue,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>? ?? json;
    return AdminStats(
      totalPatients: (d['totalPatients'] as num?)?.toInt() ?? 0,
      totalDoctors: (d['totalDoctors'] as num?)?.toInt() ?? 0,
      totalAppointments: (d['totalAppointments'] as num?)?.toInt() ?? 0,
      todayAppointments: (d['todayAppointments'] as num?)?.toInt() ?? 0,
      pendingAppointments: (d['pendingAppointments'] as num?)?.toInt() ?? 0,
      confirmedAppointments:
          (d['confirmedAppointments'] as num?)?.toInt() ?? 0,
      completedAppointments:
          (d['completedAppointments'] as num?)?.toInt() ?? 0,
      totalPrescriptions: (d['totalPrescriptions'] as num?)?.toInt() ?? 0,
      totalInvoices: (d['totalInvoices'] as num?)?.toInt() ?? 0,
      pendingInvoices: (d['pendingInvoices'] as num?)?.toInt() ?? 0,
      totalRevenue: (d['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final dio = ref.watch(dioClientProvider);
  try {
    final response = await dio.get('/admin-stats');
    return AdminStats.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw parseDioError(e);
  }
});
