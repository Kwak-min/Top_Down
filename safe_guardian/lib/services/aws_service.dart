import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// AWS 가상환경 링크 검증 서비스 (3단계)
/// 사용자가 AWS 엔드포인트를 별도 설정 후 사용
class AwsService {
  static const AwsService _instance = AwsService._internal();
  static AwsService get instance => _instance;
  const AwsService._internal();

  static const String _prefKeyEndpoint = 'aws_endpoint';

  /// AWS 엔드포인트 URL 저장
  Future<void> saveEndpoint(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyEndpoint, url);
  }

  /// AWS 엔드포인트 URL 조회
  Future<String?> getEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyEndpoint);
  }

  /// URL을 AWS 가상환경에서 검증 (3단계 핵심)
  Future<AwsLinkResult> verifyUrl(String url) async {
    final endpoint = await getEndpoint();

    // AWS 미설정 시 스킵
    if (endpoint == null || endpoint.isEmpty) {
      return AwsLinkResult(
        isConfigured: false,
        isSafe: true,
        detail: 'AWS 가상환경이 설정되지 않았습니다. 설정에서 연결해주세요.',
        url: url,
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$endpoint/analyze-url'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AwsLinkResult(
          isConfigured: true,
          isSafe: data['safe'] ?? false,
          detail: data['reason'] ?? '분석 완료',
          url: url,
          threatType: data['threat_type'],
        );
      }

      return AwsLinkResult(
        isConfigured: true,
        isSafe: false,
        detail: 'AWS 서버 응답 오류 (${response.statusCode})',
        url: url,
      );
    } catch (e) {
      return AwsLinkResult(
        isConfigured: true,
        isSafe: false,
        detail: 'AWS 연결 실패: 네트워크를 확인하세요.',
        url: url,
      );
    }
  }
}

class AwsLinkResult {
  final bool isConfigured;
  final bool isSafe;
  final String detail;
  final String url;
  final String? threatType;

  const AwsLinkResult({
    required this.isConfigured,
    required this.isSafe,
    required this.detail,
    required this.url,
    this.threatType,
  });
}
