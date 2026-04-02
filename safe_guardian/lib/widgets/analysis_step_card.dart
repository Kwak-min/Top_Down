import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../theme/app_theme.dart';

/// 4단계 분석 단계 카드 위젯
class AnalysisStepCard extends StatelessWidget {
  final AnalysisStep step;

  const AnalysisStepCard({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final color = _getColor(step.status);
    final bgColor = _getBgColor(step.status);
    final icon = _getIcon(step.status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // 단계 번호
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.stepNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSM,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (step.status == StepStatus.running)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: LinearProgressIndicator(),
                  )
                else if (step.detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      step.detail,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeXS,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 상태 아이콘
          step.status == StepStatus.running
              ? SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color),
                )
              : Icon(icon, color: color, size: 28),
        ],
      ),
    );
  }

  Color _getColor(StepStatus status) {
    switch (status) {
      case StepStatus.safe:    return AppTheme.safeColor;
      case StepStatus.warning: return AppTheme.warningColor;
      case StepStatus.danger:  return AppTheme.dangerColor;
      case StepStatus.running: return AppTheme.primaryColor;
      case StepStatus.skipped: return Colors.grey;
      case StepStatus.pending: return Colors.grey;
    }
  }

  Color _getBgColor(StepStatus status) {
    switch (status) {
      case StepStatus.safe:    return const Color(0xFFE8F5E9);
      case StepStatus.warning: return const Color(0xFFFFF8E1);
      case StepStatus.danger:  return const Color(0xFFFFEBEE);
      case StepStatus.running: return const Color(0xFFE3F2FD);
      case StepStatus.skipped: return const Color(0xFFF5F5F5);
      case StepStatus.pending: return const Color(0xFFF5F5F5);
    }
  }

  IconData _getIcon(StepStatus status) {
    switch (status) {
      case StepStatus.safe:    return Icons.check_circle;
      case StepStatus.warning: return Icons.warning_rounded;
      case StepStatus.danger:  return Icons.cancel;
      case StepStatus.running: return Icons.hourglass_empty;
      case StepStatus.skipped: return Icons.skip_next;
      case StepStatus.pending: return Icons.radio_button_unchecked;
    }
  }
}
