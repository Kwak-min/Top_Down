import '../models/analysis_result.dart';

/// AI 기반 스미싱 탐지 서비스 (2단계)
/// 키워드 점수 + 패턴 분석 기반
class SmishingDetector {
  static const SmishingDetector _instance = SmishingDetector._internal();
  static SmishingDetector get instance => _instance;
  const SmishingDetector._internal();

  // 고위험 키워드 (각 20점)
  static const List<String> _highRiskKeywords = [
    '계좌번호', '비밀번호', '인증번호', '주민등록번호', '신용카드',
    '개인정보', '보안카드', 'OTP', '금융감독원', '검찰청',
    '경찰청', '법원', '세금', '환급', '압류', '체납',
    '당첨', '무료', '긴급', '즉시', '지금바로',
  ];

  // 중위험 키워드 (각 10점)
  static const List<String> _mediumRiskKeywords = [
    '클릭', '접속', '확인하세요', '로그인', '업데이트',
    '택배', '배송', '반송', '미수령', '지원금',
    '보조금', '혜택', '이벤트', '당첨자', '가족',
    '자녀', '아들', '딸', '엄마', '아빠',
  ];

  // URL 패턴
  static final RegExp _urlPattern = RegExp(
    r'(https?://|http://|www\.|bit\.ly|tinyurl|goo\.gl|[a-zA-Z0-9-]+\.(com|co\.kr|net|org|kr|info|biz)(/\S*)?)',
    caseSensitive: false,
  );

  // 위험 전화번호 패턴
  static final RegExp _suspiciousNumberPattern = RegExp(
    r'^(070|050|00)',  // 인터넷 전화, 국제전화
  );

  /// 문자 메시지 분석
  AnalysisResult analyze({
    required String message,
    required String senderNumber,
  }) {
    int totalScore = 0;
    final List<String> detectedKeywords = [];
    String? suspiciousUrl;

    // 고위험 키워드 점수
    for (final keyword in _highRiskKeywords) {
      if (message.contains(keyword)) {
        totalScore += 20;
        detectedKeywords.add(keyword);
      }
    }

    // 중위험 키워드 점수
    for (final keyword in _mediumRiskKeywords) {
      if (message.contains(keyword)) {
        totalScore += 10;
        detectedKeywords.add(keyword);
      }
    }

    // URL 포함 시 추가 점수
    final urlMatch = _urlPattern.firstMatch(message);
    if (urlMatch != null) {
      suspiciousUrl = urlMatch.group(0);
      totalScore += 25;
    }

    // 의심 전화번호 패턴
    if (_suspiciousNumberPattern.hasMatch(senderNumber)) {
      totalScore += 15;
    }

    // 짧은 숫자 링크 포함 (bit.ly 등)
    if (message.contains('bit.ly') || message.contains('tinyurl')) {
      totalScore += 20;
    }

    // 긴급성 표현 조합 점수
    final urgentPhrases = ['즉시', '빨리', '지금', '긴급', '바로', '오늘까지', '마감'];
    int urgentCount = urgentPhrases.where((p) => message.contains(p)).length;
    if (urgentCount >= 2) totalScore += 15;

    // 위험도 판정
    RiskLevel riskLevel;
    String summary;

    if (totalScore >= 50) {
      riskLevel = RiskLevel.danger;
      summary = '⚠️ 스미싱 문자로 의심됩니다! 절대 링크를 누르지 마세요!';
    } else if (totalScore >= 25) {
      riskLevel = RiskLevel.warning;
      summary = '주의가 필요한 문자입니다. 발신자를 꼭 확인하세요.';
    } else {
      riskLevel = RiskLevel.safe;
      summary = '안전한 문자로 판단됩니다.';
    }

    return AnalysisResult(
      messageText: message,
      senderNumber: senderNumber,
      analyzedAt: DateTime.now(),
      riskLevel: riskLevel,
      steps: [],
      detectedKeywords: detectedKeywords.toSet().toList(),
      suspiciousUrl: suspiciousUrl,
      summary: summary,
    );
  }

  /// 위험 키워드 목록 반환 (UI 표시용)
  List<String> getDetectedKeywords(String message) {
    final List<String> found = [];
    for (final k in [..._highRiskKeywords, ..._mediumRiskKeywords]) {
      if (message.contains(k)) found.add(k);
    }
    return found.toSet().toList();
  }

  /// URL 추출
  String? extractUrl(String message) {
    final match = _urlPattern.firstMatch(message);
    return match?.group(0);
  }
}
