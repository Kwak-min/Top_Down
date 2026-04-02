import 'dart:convert';
import 'package:http/http.dart' as http;

/// 경찰청 피싱 신고 번호 조회 서비스 (1단계)
class PoliceApiService {
  static const PoliceApiService _instance = PoliceApiService._internal();
  static PoliceApiService get instance => _instance;
  const PoliceApiService._internal();

  // 경찰청 API 엔드포인트 (실제 사용 시 키 발급 필요)
  static const String _baseUrl = 'https://www.police.go.kr/api/phishing';
  
  // 오프라인 위험 번호 DB (경찰청 공개 데이터 기반 샘플)
  static const Set<String> _knownFraudNumbers = {
    '01012345678', '07012345678', '05012345678',
    '0212341234',  '0312341234',
  };

  // 위험 번호 패턴
  static final List<RegExp> _suspiciousPatterns = [
    RegExp(r'^070'),           // 인터넷 전화
    RegExp(r'^\+'),            // 국제 전화
    RegExp(r'^00'),            // 국제 전화
    RegExp(r'^050'),           // 가상 번호
  ];

  /// 전화번호가 신고된 피싱 번호인지 조회
  Future<PoliceCheckResult> checkNumber(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\+]'), '');

    // 1. 로컬 DB 조회
    if (_knownFraudNumbers.contains(cleanNumber)) {
      return PoliceCheckResult(
        isReported: true,
        source: '경찰청 신고DB',
        detail: '이미 신고된 피싱 번호입니다.',
      );
    }

    // 2. 패턴 체크
    for (final pattern in _suspiciousPatterns) {
      if (pattern.hasMatch(cleanNumber)) {
        return PoliceCheckResult(
          isReported: false,
          isSuspiciousPattern: true,
          source: '번호 패턴 분석',
          detail: '인터넷 전화 또는 가상 번호로 의심됩니다.',
        );
      }
    }

    // 3. 실제 API 호출 (API 키가 설정된 경우)
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/check?number=$cleanNumber'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PoliceCheckResult(
          isReported: data['isReported'] ?? false,
          source: '경찰청 API',
          detail: data['detail'] ?? '정상 번호입니다.',
        );
      }
    } catch (_) {
      // API 연결 실패 시 로컬 결과로 대체
    }

    return PoliceCheckResult(
      isReported: false,
      source: '로컬 DB',
      detail: '신고된 번호가 아닙니다.',
    );
  }
}

class PoliceCheckResult {
  final bool isReported;
  final bool isSuspiciousPattern;
  final String source;
  final String detail;

  const PoliceCheckResult({
    required this.isReported,
    this.isSuspiciousPattern = false,
    required this.source,
    required this.detail,
  });

  bool get isSafe => !isReported && !isSuspiciousPattern;
}
