import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/analysis_result.dart';
import '../services/analysis_pipeline_service.dart';
import '../widgets/danger_overlay.dart';
import '../widgets/analysis_step_card.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _messageController = TextEditingController();
  final _numberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isAnalyzing = false;
  AnalysisResult? _result;
  List<AnalysisStep> _liveSteps = [];
  bool _showDangerOverlay = false;

  // 샘플 스미싱 문자 예시
  static const List<Map<String, String>> _samples = [
    {
      'number': '07012345678',
      'message': '[KB국민은행] 고객님의 계좌가 이상거래로 정지되었습니다. 지금 바로 확인하세요→ http://kb-secure.xyz/check',
    },
    {
      'number': '01087654321',
      'message': '[국세청] 환급금 32만원이 발생했습니다. 인증번호 확인 후 즉시 수령하세요. http://nts-refund.kr',
    },
    {
      'number': '01012345678',
      'message': '엄마 나야, 핸드폰 고장났어. 지금 급하게 돈 필요한데 비밀번호 알려줘',
    },
    {
      'number': '01011112222',
      'message': '안녕하세요, 내일 오후 2시 약속 확인 부탁드립니다.',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isAnalyzing = true;
      _result = null;
      _liveSteps = [];
      _showDangerOverlay = false;
    });

    final result = await AnalysisPipelineService.instance.runPipeline(
      message: _messageController.text,
      senderNumber: _numberController.text,
      onStepsUpdated: (steps) {
        if (mounted) setState(() => _liveSteps = steps);
      },
    );

    if (mounted) {
      setState(() {
        _result = result;
        _isAnalyzing = false;
        if (result.riskLevel == RiskLevel.danger) {
          _showDangerOverlay = true;
        }
      });
    }
  }

  void _loadSample(Map<String, String> sample) {
    _numberController.text = sample['number']!;
    _messageController.text = sample['message']!;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('🔍 문자 분석'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 안내 카드
                  _buildInfoCard(),
                  const SizedBox(height: 20),

                  // 입력 폼
                  _buildInputForm(),
                  const SizedBox(height: 16),

                  // 샘플 버튼들
                  _buildSampleButtons(),
                  const SizedBox(height: 20),

                  // 분석 버튼
                  ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _runAnalysis,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.search, size: 28),
                    label: Text(_isAnalyzing ? '분석 중...' : '지금 분석하기'),
                  ),
                  const SizedBox(height: 24),

                  // 실시간 단계 표시
                  if (_liveSteps.isNotEmpty) ...[
                    const Text(
                      '📊 분석 진행',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMD,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_liveSteps.length, (i) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AnalysisStepCard(step: _liveSteps[i]),
                      ),
                    ),
                  ],

                  // 최종 결과
                  if (_result != null && !_isAnalyzing)
                    _buildFinalResult(_result!),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),

        // 위험 오버레이 (4단계 화면 차단)
        if (_showDangerOverlay)
          DangerOverlay(
            result: _result!,
            onDismiss: () => setState(() => _showDangerOverlay = false),
          ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: const Color(0xFFE3F2FD),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const [
            Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '의심스러운 문자를 받으셨나요?\n내용을 붙여넣고 분석해보세요.',
                style: TextStyle(fontSize: AppTheme.fontSizeSM),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '발신 번호',
          style: TextStyle(fontSize: AppTheme.fontSizeMD, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _numberController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: AppTheme.fontSizeMD),
          decoration: InputDecoration(
            hintText: '예: 01012345678',
            prefixIcon: const Icon(Icons.phone, size: 28),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
          validator: (v) => (v == null || v.isEmpty) ? '번호를 입력해주세요' : null,
        ),
        const SizedBox(height: 16),
        const Text(
          '문자 내용',
          style: TextStyle(fontSize: AppTheme.fontSizeMD, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 5,
          style: const TextStyle(fontSize: AppTheme.fontSizeMD),
          decoration: InputDecoration(
            hintText: '문자 내용을 여기에 붙여넣어 주세요...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (v) => (v == null || v.isEmpty) ? '문자 내용을 입력해주세요' : null,
        ),
      ],
    );
  }

  Widget _buildSampleButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 테스트 예시',
          style: TextStyle(fontSize: AppTheme.fontSizeSM, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _sampleChip('🚨 위험 예시 1', _samples[0], AppTheme.dangerColor),
            _sampleChip('🚨 위험 예시 2', _samples[1], AppTheme.dangerColor),
            _sampleChip('⚠️ 주의 예시', _samples[2], AppTheme.warningColor),
            _sampleChip('✅ 안전 예시', _samples[3], AppTheme.safeColor),
          ],
        ),
      ],
    );
  }

  Widget _sampleChip(String label, Map<String, String> sample, Color color) {
    return ActionChip(
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      side: BorderSide(color: color),
      onPressed: () => _loadSample(sample),
    );
  }

  Widget _buildFinalResult(AnalysisResult result) {
    final isdanger = result.riskLevel == RiskLevel.danger;
    final isWarning = result.riskLevel == RiskLevel.warning;
    final color = isdanger ? AppTheme.dangerColor : isWarning ? AppTheme.warningColor : AppTheme.safeColor;
    final bgColor = isdanger ? const Color(0xFFFFEBEE) : isWarning ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9);

    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              result.riskLevel.emoji,
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 12),
            Text(
              result.riskLevel.label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeXL,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.summary,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppTheme.fontSizeMD, color: color),
            ),
            if (result.detectedKeywords.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: result.detectedKeywords.map((k) => Chip(
                  label: Text(k, style: const TextStyle(fontSize: AppTheme.fontSizeXS)),
                  backgroundColor: color.withOpacity(0.15),
                  side: BorderSide(color: color),
                )).toList(),
              ),
            ],
            if (result.suspiciousUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.suspiciousUrl!,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeXS,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
