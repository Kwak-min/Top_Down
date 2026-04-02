/// 분석 결과 모델
class AnalysisResult {
  final String messageText;
  final String senderNumber;
  final DateTime analyzedAt;
  final RiskLevel riskLevel;
  final List<AnalysisStep> steps;
  final List<String> detectedKeywords;
  final String? suspiciousUrl;
  final String summary;

  const AnalysisResult({
    required this.messageText,
    required this.senderNumber,
    required this.analyzedAt,
    required this.riskLevel,
    required this.steps,
    required this.detectedKeywords,
    this.suspiciousUrl,
    required this.summary,
  });
}

/// 위험 수준
enum RiskLevel {
  safe,     // 안전
  warning,  // 주의
  danger,   // 위험
}

extension RiskLevelExtension on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.safe:    return '안전';
      case RiskLevel.warning: return '주의';
      case RiskLevel.danger:  return '위험';
    }
  }

  String get emoji {
    switch (this) {
      case RiskLevel.safe:    return '✅';
      case RiskLevel.warning: return '⚠️';
      case RiskLevel.danger:  return '🚨';
    }
  }
}

/// 4단계 분석 단계 결과
class AnalysisStep {
  final int stepNumber;
  final String title;
  final String description;
  final StepStatus status;
  final String detail;

  const AnalysisStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.detail,
  });
}

enum StepStatus {
  pending,  // 대기
  running,  // 분석중
  safe,     // 안전
  warning,  // 주의
  danger,   // 위험
  skipped,  // 건너뜀
}
