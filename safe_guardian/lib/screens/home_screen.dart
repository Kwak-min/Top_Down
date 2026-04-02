import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/analysis_result.dart';
import '../services/analysis_pipeline_service.dart';
import 'analysis_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isProtectionOn = true;
  int _scannedCount = 0;
  int _blockedCount = 0;
  int _currentIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadStats();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = await AnalysisPipelineService.instance.getStats();
    setState(() {
      _scannedCount = stats['scanned'] ?? 0;
      _blockedCount = stats['blocked'] ?? 0;
    });
  }

  final List<Widget> _screens = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0
          ? _buildHome()
          : _currentIndex == 1
              ? const AnalysisScreen()
              : _currentIndex == 2
                  ? const HistoryScreen()
                  : const SettingsScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          if (i == 0) _loadStats();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shield), label: '홈'),
          NavigationDestination(icon: Icon(Icons.search), label: '문자분석'),
          NavigationDestination(icon: Icon(Icons.history), label: '기록'),
          NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('🛡️ 안심지킴이'),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 보호 상태 카드
              _buildProtectionCard(),
              const SizedBox(height: 20),
              // 통계 카드
              _buildStatsRow(),
              const SizedBox(height: 20),
              // 빠른 분석 버튼
              _buildQuickAnalysisButton(),
              const SizedBox(height: 20),
              // 4단계 방어 시스템 설명
              _buildPipelineCard(),
              const SizedBox(height: 20),
              // 긴급 도움 카드
              _buildEmergencyCard(),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildProtectionCard() {
    return Card(
      color: _isProtectionOn ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ScaleTransition(
              scale: _isProtectionOn ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: Icon(
                _isProtectionOn ? Icons.shield : Icons.shield_outlined,
                size: 80,
                color: _isProtectionOn ? AppTheme.safeColor : AppTheme.dangerColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isProtectionOn ? '보호 중입니다 ✅' : '보호가 꺼져 있습니다 ⚠️',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLG,
                fontWeight: FontWeight.bold,
                color: _isProtectionOn ? AppTheme.safeColor : AppTheme.dangerColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isProtectionOn
                  ? '스미싱 방어가 활성화되어 있습니다'
                  : '보호를 켜주세요',
              style: const TextStyle(fontSize: AppTheme.fontSizeSM, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            Switch.adaptive(
              value: _isProtectionOn,
              onChanged: (val) => setState(() => _isProtectionOn = val),
              activeColor: AppTheme.safeColor,
              inactiveThumbColor: AppTheme.dangerColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.search,
            label: '오늘 분석',
            value: '$_scannedCount건',
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.block,
            label: '차단됨',
            value: '$_blockedCount건',
            color: AppTheme.dangerColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            label: '안전',
            value: '${_scannedCount - _blockedCount}건',
            color: AppTheme.safeColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: AppTheme.fontSizeLG,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeXS,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAnalysisButton() {
    return ElevatedButton.icon(
      onPressed: () => setState(() => _currentIndex = 1),
      icon: const Icon(Icons.search, size: 28),
      label: const Text('문자 바로 분석하기'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        minimumSize: const Size(double.infinity, 72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildPipelineCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔒 4단계 방어 시스템',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMD,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPipelineStep('1', '경찰청 신고번호 조회', Icons.local_police, AppTheme.primaryColor),
            _buildPipelineArrow(),
            _buildPipelineStep('2', 'AI 문맥 분석', Icons.psychology, Colors.purple),
            _buildPipelineArrow(),
            _buildPipelineStep('3', 'AWS 가상환경 링크 검증', Icons.cloud, Colors.orange),
            _buildPipelineArrow(),
            _buildPipelineStep('4', '화면 강제 차단', Icons.block, AppTheme.dangerColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineStep(String number, String label, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: AppTheme.fontSizeSM, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildPipelineArrow() {
    return const Padding(
      padding: EdgeInsets.only(left: 17),
      child: Icon(Icons.arrow_downward, color: Colors.grey, size: 20),
    );
  }

  Widget _buildEmergencyCard() {
    return Card(
      color: const Color(0xFFFFF3E0),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emergency, color: AppTheme.warningColor, size: 28),
                SizedBox(width: 8),
                Text(
                  '피해 발생 시 즉시 신고',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMD,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildEmergencyContact('경찰청 (스미싱 신고)', '112'),
            _buildEmergencyContact('금융감독원', '1332'),
            _buildEmergencyContact('한국인터넷진흥원', '118'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContact(String label, String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: AppTheme.fontSizeSM)),
          Text(
            number,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeMD,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
