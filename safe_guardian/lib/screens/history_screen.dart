import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/analysis_result.dart';
import '../models/message_record.dart';
import '../services/analysis_pipeline_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<MessageRecord> _records = [];
  bool _isLoading = true;
  RiskLevel? _filterLevel;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final records = await AnalysisPipelineService.instance.getHistory();
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('모든 분석 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AnalysisPipelineService.instance.clearHistory();
      _loadHistory();
    }
  }

  List<MessageRecord> get _filteredRecords {
    if (_filterLevel == null) return _records;
    return _records.where((r) => r.riskLevel == _filterLevel).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 분석 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _records.isEmpty ? null : _clearHistory,
            tooltip: '기록 삭제',
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 탭
          _buildFilterRow(),
          // 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRecords.length,
                          itemBuilder: (ctx, i) => _buildRecordCard(_filteredRecords[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(null, '전체'),
            const SizedBox(width: 8),
            _filterChip(RiskLevel.danger, '🚨 위험'),
            const SizedBox(width: 8),
            _filterChip(RiskLevel.warning, '⚠️ 주의'),
            const SizedBox(width: 8),
            _filterChip(RiskLevel.safe, '✅ 안전'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(RiskLevel? level, String label) {
    final selected = _filterLevel == level;
    return FilterChip(
      label: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      selected: selected,
      onSelected: (_) => setState(() => _filterLevel = level),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _filterLevel == null ? '분석 기록이 없습니다' : '해당 기록이 없습니다',
            style: const TextStyle(fontSize: AppTheme.fontSizeMD, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '문자를 분석하면 여기에 기록됩니다',
            style: TextStyle(fontSize: AppTheme.fontSizeSM, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(MessageRecord record) {
    final isDanger = record.riskLevel == RiskLevel.danger;
    final isWarning = record.riskLevel == RiskLevel.warning;
    final color = isDanger ? AppTheme.dangerColor : isWarning ? AppTheme.warningColor : AppTheme.safeColor;
    final bgColor = isDanger
        ? const Color(0xFFFFEBEE)
        : isWarning
            ? const Color(0xFFFFF8E1)
            : const Color(0xFFE8F5E9);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  record.riskLevel.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.senderNumber,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMD,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        DateFormat('M월 d일 HH:mm').format(record.receivedAt),
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeXS,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    record.riskLevel.label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              record.messageText.length > 80
                  ? '${record.messageText.substring(0, 80)}...'
                  : record.messageText,
              style: const TextStyle(fontSize: AppTheme.fontSizeSM),
            ),
            const SizedBox(height: 8),
            Text(
              record.summary,
              style: TextStyle(
                fontSize: AppTheme.fontSizeXS,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
