import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/analysis_result.dart';
import '../models/message_record.dart';
import 'smishing_detector.dart';
import 'police_api_service.dart';
import 'aws_service.dart';
import 'notification_service.dart';

/// 4단계 통합 방어 파이프라인 서비스
class AnalysisPipelineService {
  static final AnalysisPipelineService _instance = AnalysisPipelineService._internal();
  static AnalysisPipelineService get instance => _instance;
  AnalysisPipelineService._internal();

  static const String _prefKeyHistory = 'analysis_history';
  static const String _prefKeyBlockedCount = 'blocked_count';
  static const String _prefKeyScannedCount = 'scanned_count';

  final _detector = SmishingDetector.instance;
  final _policeApi = PoliceApiService.instance;
  final _awsService = AwsService.instance;
  final _notificationService = NotificationService.instance;

  /// 4단계 파이프라인 분석 실행
  Future<AnalysisResult> runPipeline({
    required String message,
    required String senderNumber,
    required Function(List<AnalysisStep>) onStepsUpdated,
  }) async {
    final steps = <AnalysisStep>[];
    RiskLevel finalRisk = RiskLevel.safe;
    String? suspiciousUrl;

    // ── 1단계: 경찰청 신고번호 조회 ──
    steps.add(AnalysisStep(
      stepNumber: 1,
      title: '경찰청 신고번호 조회',
      description: '발신 번호를 경찰청 피싱 DB에서 확인 중...',
      status: StepStatus.running,
      detail: '',
    ));
    onStepsUpdated(List.from(steps));
    await Future.delayed(const Duration(milliseconds: 800));

    final policeResult = await _policeApi.checkNumber(senderNumber);
    StepStatus step1Status;
    String step1Detail;

    if (policeResult.isReported) {
      step1Status = StepStatus.danger;
      step1Detail = '⛔ 신고된 피싱 번호 (${policeResult.source})';
      finalRisk = RiskLevel.danger;
    } else if (policeResult.isSuspiciousPattern) {
      step1Status = StepStatus.warning;
      step1Detail = '⚠️ ${policeResult.detail}';
      if (finalRisk == RiskLevel.safe) finalRisk = RiskLevel.warning;
    } else {
      step1Status = StepStatus.safe;
      step1Detail = '✅ ${policeResult.detail}';
    }

    steps[0] = AnalysisStep(
      stepNumber: 1,
      title: '경찰청 신고번호 조회',
      description: '발신 번호 확인 완료',
      status: step1Status,
      detail: step1Detail,
    );
    onStepsUpdated(List.from(steps));

    // ── 2단계: AI 문맥 분석 ──
    steps.add(AnalysisStep(
      stepNumber: 2,
      title: 'AI 문맥 분석',
      description: '문자 내용을 AI로 분석 중...',
      status: StepStatus.running,
      detail: '',
    ));
    onStepsUpdated(List.from(steps));
    await Future.delayed(const Duration(milliseconds: 1000));

    final aiResult = _detector.analyze(message: message, senderNumber: senderNumber);
    suspiciousUrl = aiResult.suspiciousUrl;

    StepStatus step2Status;
    String step2Detail;

    if (aiResult.riskLevel == RiskLevel.danger) {
      step2Status = StepStatus.danger;
      step2Detail = '⛔ 고위험 키워드 ${aiResult.detectedKeywords.length}개 탐지: ${aiResult.detectedKeywords.take(3).join(', ')}';
      finalRisk = RiskLevel.danger;
    } else if (aiResult.riskLevel == RiskLevel.warning) {
      step2Status = StepStatus.warning;
      step2Detail = '⚠️ 주의 키워드 탐지: ${aiResult.detectedKeywords.take(3).join(', ')}';
      if (finalRisk == RiskLevel.safe) finalRisk = RiskLevel.warning;
    } else {
      step2Status = StepStatus.safe;
      step2Detail = '✅ 스미싱 패턴 미탐지';
    }

    steps[1] = AnalysisStep(
      stepNumber: 2,
      title: 'AI 문맥 분석',
      description: 'AI 분석 완료',
      status: step2Status,
      detail: step2Detail,
    );
    onStepsUpdated(List.from(steps));

    // ── 3단계: AWS 가상환경 링크 검증 ──
    if (suspiciousUrl != null) {
      steps.add(AnalysisStep(
        stepNumber: 3,
        title: 'AWS 가상환경 링크 검증',
        description: '링크를 가상환경에서 안전하게 검사 중...',
        status: StepStatus.running,
        detail: '',
      ));
      onStepsUpdated(List.from(steps));
      await Future.delayed(const Duration(milliseconds: 1200));

      final awsResult = await _awsService.verifyUrl(suspiciousUrl);
      StepStatus step3Status;
      String step3Detail;

      if (!awsResult.isConfigured) {
        step3Status = StepStatus.skipped;
        step3Detail = '⏭️ AWS 미설정 (설정에서 연결 가능)';
      } else if (!awsResult.isSafe) {
        step3Status = StepStatus.danger;
        step3Detail = '⛔ 악성 링크 확인: ${awsResult.threatType ?? awsResult.detail}';
        finalRisk = RiskLevel.danger;
      } else {
        step3Status = StepStatus.safe;
        step3Detail = '✅ 안전한 링크 확인됨';
      }

      steps[2] = AnalysisStep(
        stepNumber: 3,
        title: 'AWS 가상환경 링크 검증',
        description: awsResult.isConfigured ? '링크 검증 완료' : 'AWS 미설정',
        status: step3Status,
        detail: step3Detail,
      );
      onStepsUpdated(List.from(steps));
    } else {
      steps.add(AnalysisStep(
        stepNumber: 3,
        title: 'AWS 가상환경 링크 검증',
        description: '링크 없음',
        status: StepStatus.skipped,
        detail: '⏭️ 문자에 링크가 없어 건너뜀',
      ));
      onStepsUpdated(List.from(steps));
    }

    // ── 4단계: 최종 판정 및 화면 차단 ──
    steps.add(AnalysisStep(
      stepNumber: 4,
      title: '최종 판정 및 차단',
      description: '분석 결과를 종합 판정 중...',
      status: StepStatus.running,
      detail: '',
    ));
    onStepsUpdated(List.from(steps));
    await Future.delayed(const Duration(milliseconds: 600));

    String step4Detail;
    StepStatus step4Status;
    String finalSummary;

    if (finalRisk == RiskLevel.danger) {
      step4Status = StepStatus.danger;
      step4Detail = '⛔ 위험 판정 → 화면 차단 활성화';
      finalSummary = '스미싱 문자로 탐지되었습니다! 링크를 절대 누르지 마세요!';
      await _notificationService.showDangerAlert(
        title: '🚨 스미싱 위험 탐지!',
        body: '스미싱 의심 문자가 탐지되었습니다. 즉시 확인하세요.',
      );
    } else if (finalRisk == RiskLevel.warning) {
      step4Status = StepStatus.warning;
      step4Detail = '⚠️ 주의 판정 → 경고 표시';
      finalSummary = '주의가 필요한 문자입니다. 발신자를 직접 확인하세요.';
    } else {
      step4Status = StepStatus.safe;
      step4Detail = '✅ 안전 판정 → 정상 전달';
      finalSummary = '안전한 문자로 확인되었습니다.';
    }

    steps[3] = AnalysisStep(
      stepNumber: 4,
      title: '최종 판정 및 차단',
      description: '분석 완료',
      status: step4Status,
      detail: step4Detail,
    );
    onStepsUpdated(List.from(steps));

    // 히스토리 저장 및 카운터 업데이트
    await _saveRecord(MessageRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderNumber: senderNumber,
      messageText: message,
      receivedAt: DateTime.now(),
      riskLevel: finalRisk,
      summary: finalSummary,
    ));

    await _incrementCounters(finalRisk);

    return AnalysisResult(
      messageText: message,
      senderNumber: senderNumber,
      analyzedAt: DateTime.now(),
      riskLevel: finalRisk,
      steps: steps,
      detectedKeywords: aiResult.detectedKeywords,
      suspiciousUrl: suspiciousUrl,
      summary: finalSummary,
    );
  }

  /// 히스토리 저장
  Future<void> _saveRecord(MessageRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_prefKeyHistory) ?? '[]';
    final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
    history.insert(0, record.toJson());
    if (history.length > 100) history.removeLast();
    await prefs.setString(_prefKeyHistory, jsonEncode(history));
  }

  /// 카운터 업데이트
  Future<void> _incrementCounters(RiskLevel risk) async {
    final prefs = await SharedPreferences.getInstance();
    int scanned = prefs.getInt(_prefKeyScannedCount) ?? 0;
    int blocked = prefs.getInt(_prefKeyBlockedCount) ?? 0;
    scanned++;
    if (risk == RiskLevel.danger) blocked++;
    await prefs.setInt(_prefKeyScannedCount, scanned);
    await prefs.setInt(_prefKeyBlockedCount, blocked);
  }

  /// 히스토리 조회
  Future<List<MessageRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_prefKeyHistory) ?? '[]';
    final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
    return history.map((e) => MessageRecord.fromJson(e)).toList();
  }

  /// 통계 조회
  Future<Map<String, int>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'scanned': prefs.getInt(_prefKeyScannedCount) ?? 0,
      'blocked': prefs.getInt(_prefKeyBlockedCount) ?? 0,
    };
  }

  /// 히스토리 초기화
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyHistory);
    await prefs.remove(_prefKeyScannedCount);
    await prefs.remove(_prefKeyBlockedCount);
  }
}
