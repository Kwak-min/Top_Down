import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/aws_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _awsController = TextEditingController();
  bool _isProtectionEnabled = true;
  bool _isNotificationEnabled = true;
  String _emergencyContact = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _awsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final endpoint = await AwsService.instance.getEndpoint();
    setState(() {
      _awsController.text = endpoint ?? '';
    });
  }

  Future<void> _saveAwsEndpoint() async {
    setState(() => _isSaving = true);
    await AwsService.instance.saveEndpoint(_awsController.text.trim());
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ AWS 엔드포인트가 저장되었습니다'),
          backgroundColor: AppTheme.safeColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ 설정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 보호 설정
          _buildSectionHeader('🛡️ 보호 설정'),
          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.shield,
                  title: '실시간 보호',
                  subtitle: '스미싱 탐지를 항상 켜둡니다',
                  value: _isProtectionEnabled,
                  onChanged: (v) => setState(() => _isProtectionEnabled = v),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.notifications,
                  title: '위험 알림',
                  subtitle: '위험 탐지 시 즉시 알림을 받습니다',
                  value: _isNotificationEnabled,
                  onChanged: (v) => setState(() => _isNotificationEnabled = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // AWS 설정
          _buildSectionHeader('☁️ AWS 가상환경 설정 (3단계)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AWS Lambda 엔드포인트 URL',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSM,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '링크를 가상환경에서 안전하게 검증합니다.',
                    style: TextStyle(fontSize: AppTheme.fontSizeXS, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _awsController,
                    style: const TextStyle(fontSize: AppTheme.fontSizeSM),
                    decoration: InputDecoration(
                      hintText: 'https://xxxxxx.execute-api.ap-northeast-2.amazonaws.com/prod',
                      prefixIcon: const Icon(Icons.cloud),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveAwsEndpoint,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? '저장 중...' : '저장'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.warningColor.withOpacity(0.5)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.warningColor, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AWS API Gateway + Lambda를 설정하면 의심 링크를 가상환경에서 자동 검증합니다.\n미설정 시 1·2단계만 동작합니다.',
                            style: TextStyle(fontSize: AppTheme.fontSizeXS),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 긴급 연락처
          _buildSectionHeader('📞 긴급 연락처'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '가족 연락처 (위험 감지 시 통보)',
                    style: TextStyle(fontSize: AppTheme.fontSizeSM, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _emergencyContact,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: AppTheme.fontSizeMD),
                    decoration: InputDecoration(
                      hintText: '가족 전화번호 입력',
                      prefixIcon: const Icon(Icons.family_restroom, size: 28),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                    onChanged: (v) => _emergencyContact = v,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 앱 정보
          _buildSectionHeader('ℹ️ 앱 정보'),
          Card(
            child: Column(
              children: [
                _buildInfoTile('앱 이름', '안심지킴이 (SafeGuardian)'),
                const Divider(height: 1),
                _buildInfoTile('버전', '1.0.0'),
                const Divider(height: 1),
                _buildInfoTile('탐지 엔진', 'AI 키워드 분석 v1.0'),
                const Divider(height: 1),
                _buildInfoTile('개발 목적', '시니어 피싱 방어 연구'),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeMD,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.primaryColor, size: 28),
      title: Text(title, style: const TextStyle(fontSize: AppTheme.fontSizeMD, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: AppTheme.fontSizeXS)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.safeColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: AppTheme.fontSizeSM, color: AppTheme.textSecondary)),
      trailing: Text(value, style: const TextStyle(fontSize: AppTheme.fontSizeSM, fontWeight: FontWeight.w600)),
    );
  }
}
