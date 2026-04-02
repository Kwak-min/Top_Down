import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../theme/app_theme.dart';

/// 4단계 화면 강제 차단 오버레이 (물리적 터치 차단)
class DangerOverlay extends StatefulWidget {
  final AnalysisResult result;
  final VoidCallback onDismiss;

  const DangerOverlay({
    super.key,
    required this.result,
    required this.onDismiss,
  });

  @override
  State<DangerOverlay> createState() => _DangerOverlayState();
}

class _DangerOverlayState extends State<DangerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _shake;
  bool _showDismissConfirm = false;
  int _dismissTapCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _shake = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDismissTap() {
    _dismissTapCount++;
    if (_dismissTapCount >= 3) {
      widget.onDismiss();
    } else {
      setState(() => _showDismissConfirm = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: const Color(0xEECC0000),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 위험 아이콘 (진동 효과)
                  _buildPulsingIcon(),
                  const SizedBox(height: 32),

                  // 제목
                  const Text(
                    '🚨 위험!\n스미싱 문자 탐지',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 경고 내용
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '이 문자는 개인정보와 금융 정보를\n훔치려는 사기입니다!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '절대 링크를 누르거나\n개인정보를 입력하지 마세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            color: Color(0xFFFFD0D0),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 신고 전화 버튼
                  _buildEmergencyButton(),
                  const SizedBox(height: 16),

                  // 차단 해제 (3번 탭해야 해제)
                  if (_showDismissConfirm) ...[
                    Text(
                      '${3 - _dismissTapCount}번 더 누르면 해제됩니다',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextButton(
                    onPressed: _onDismissTap,
                    child: Text(
                      _showDismissConfirm ? '정말 해제하기 (${_dismissTapCount}/3)' : '안전함을 확인했습니다',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.1),
      duration: const Duration(milliseconds: 800),
      builder: (ctx, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      onEnd: () => setState(() {}),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Center(
          child: Text('🚨', style: TextStyle(fontSize: 60)),
        ),
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return ElevatedButton.icon(
      onPressed: () {
        // 경찰청 신고 전화
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('경찰청(112) 또는 금융감독원(1332)에 신고하세요')),
        );
      },
      icon: const Icon(Icons.phone, size: 28),
      label: const Text('지금 신고하기 (112)', style: TextStyle(fontSize: 20)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.dangerColor,
        minimumSize: const Size(double.infinity, 68),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
