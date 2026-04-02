import 'analysis_result.dart';

/// 분석 히스토리 레코드
class MessageRecord {
  final String id;
  final String senderNumber;
  final String messageText;
  final DateTime receivedAt;
  final RiskLevel riskLevel;
  final String summary;

  MessageRecord({
    required this.id,
    required this.senderNumber,
    required this.messageText,
    required this.receivedAt,
    required this.riskLevel,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderNumber': senderNumber,
    'messageText': messageText,
    'receivedAt': receivedAt.toIso8601String(),
    'riskLevel': riskLevel.index,
    'summary': summary,
  };

  factory MessageRecord.fromJson(Map<String, dynamic> json) => MessageRecord(
    id: json['id'],
    senderNumber: json['senderNumber'],
    messageText: json['messageText'],
    receivedAt: DateTime.parse(json['receivedAt']),
    riskLevel: RiskLevel.values[json['riskLevel']],
    summary: json['summary'],
  );
}
