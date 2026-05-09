class RecoveryStats {
  final int openCases;
  final int inProgressCases;
  final int recoveredCases;
  final int escalatedCases;
  final int todayNoShows;
  final int pendingTasks;
  final int overdueTasks;
  final int criticalScores;
  final int highScores;
  final int recoveryRate; // percentage
  final double revenueRecovered;
  final int totalActiveCases;

  const RecoveryStats({
    required this.openCases,
    required this.inProgressCases,
    required this.recoveredCases,
    required this.escalatedCases,
    required this.todayNoShows,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.criticalScores,
    required this.highScores,
    required this.recoveryRate,
    required this.revenueRecovered,
    required this.totalActiveCases,
  });

  factory RecoveryStats.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>? ?? json;
    return RecoveryStats(
      openCases: (d['openCases'] as num?)?.toInt() ?? 0,
      inProgressCases: (d['inProgressCases'] as num?)?.toInt() ?? 0,
      recoveredCases: (d['recoveredCases'] as num?)?.toInt() ?? 0,
      escalatedCases: (d['escalatedCases'] as num?)?.toInt() ?? 0,
      todayNoShows: (d['todayNoShows'] as num?)?.toInt() ?? 0,
      pendingTasks: (d['pendingTasks'] as num?)?.toInt() ?? 0,
      overdueTasks: (d['overdueTasks'] as num?)?.toInt() ?? 0,
      criticalScores: (d['criticalScores'] as num?)?.toInt() ?? 0,
      highScores: (d['highScores'] as num?)?.toInt() ?? 0,
      recoveryRate: (d['recoveryRate'] as num?)?.toInt() ?? 0,
      revenueRecovered: (d['revenueRecovered'] as num?)?.toDouble() ?? 0,
      totalActiveCases: (d['totalActiveCases'] as num?)?.toInt() ?? 0,
    );
  }

  static const empty = RecoveryStats(
    openCases: 0,
    inProgressCases: 0,
    recoveredCases: 0,
    escalatedCases: 0,
    todayNoShows: 0,
    pendingTasks: 0,
    overdueTasks: 0,
    criticalScores: 0,
    highScores: 0,
    recoveryRate: 0,
    revenueRecovered: 0,
    totalActiveCases: 0,
  );
}
