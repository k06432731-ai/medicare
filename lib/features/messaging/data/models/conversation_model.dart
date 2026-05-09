class ConversationModel {
  final int id;
  final int patientId;
  final String patientName;
  final int doctorId;
  final String doctorName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int patientUnread;
  final int doctorUnread;

  const ConversationModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    this.lastMessage,
    this.lastMessageAt,
    this.patientUnread = 0,
    this.doctorUnread = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> d =
        json['attributes'] != null ? json['attributes'] as Map<String, dynamic> : json;
    return ConversationModel(
      id: json['id'] as int? ?? 0,
      patientId: d['patientId'] as int? ?? 0,
      patientName: d['patientName'] as String? ?? 'Patient',
      doctorId: d['doctorId'] as int? ?? 0,
      doctorName: d['doctorName'] as String? ?? 'Médecin',
      lastMessage: d['lastMessage'] as String?,
      lastMessageAt: DateTime.tryParse(d['lastMessageAt'] as String? ?? ''),
      patientUnread: d['patientUnread'] as int? ?? 0,
      doctorUnread: d['doctorUnread'] as int? ?? 0,
    );
  }

  /// Unread count depuis le point de vue de l'utilisateur donné
  int unreadFor(int userId) =>
      patientId == userId ? patientUnread : doctorUnread;

  /// Nom de l'autre participant
  String otherName(int userId) =>
      patientId == userId ? doctorName : patientName;
}
