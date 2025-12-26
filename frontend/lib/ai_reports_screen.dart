import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/analysis_models.dart';
import 'services/backend_api.dart';
import 'services/backend_factory.dart';

class AIReportsScreen extends StatefulWidget {
  const AIReportsScreen({super.key});

  @override
  State<AIReportsScreen> createState() => _AIReportsScreenState();
}

class _AIReportsScreenState extends State<AIReportsScreen> {
  final BackendApi _api = BackendFactory.create();
  final NumberFormat _amountFormat = NumberFormat.decimalPattern('fr_FR');

  PeriodAnalysis? _monthStats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final analysis = await _api.fetchFinancialAnalysis();
      final stats = analysis.periods[AnalysisPeriod.month] ??
          analysis.periods.values.firstOrNull ??
          (analysis.periods.isNotEmpty ? analysis.periods.values.first : null);
      if (!mounted) return;
      setState(() {
        _monthStats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _score(PeriodAnalysis stats) {
    final base = 80;
    final delta = stats.revenueChange - (stats.expenseChange / 2);
    return (base + delta).clamp(0, 100).round();
  }

  double _savingRate(PeriodAnalysis stats) {
    final revenue = stats.revenue;
    if (revenue <= 0) return 0;
    final rate = (revenue - stats.expense) / revenue;
    return (rate * 100).clamp(0, 100);
  }

  Future<void> _downloadPdf() async {
    try {
      await _api.downloadAnalysisPdf();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement du rapport en cours...')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de télécharger le PDF : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2C3A4B),
        titleSpacing: 0,
        title: const Text(
          'Rapports IA',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFE53935)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    final stats = _monthStats;
    if (stats == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aucune donnée disponible pour le rapport.'),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Recharger')),
          ],
        ),
      );
    }

    final score = _score(stats);
    final savingRate = _savingRate(stats);
    final remainingDays = 15; // placeholder UI metric
    final remainingAmount = (stats.expense > 0 ? stats.expense * 0.85 : 0).round();

    final recommendations = stats.recommendations
        .map((r) => _Reco(
              title: r,
              category: 'Recommandation IA',
              body: stats.insightTitle.isNotEmpty ? stats.insightTitle : stats.insightBody,
              savings: '',
              level: '—',
              color: const Color(0xFF4DA1F0),
              icon: Icons.lightbulb_outline,
            ))
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _HeroHeader(onDownload: _downloadPdf),
            const SizedBox(height: 14),
            _ScoreCard(
              score: score,
              delta: stats.revenueChange,
              monthLabel: DateFormat.yMMMM('fr_FR').format(DateTime.now()),
            ),
            const SizedBox(height: 12),
            _AnalysisCard(
              summary: stats.insightBody,
              bullets: stats.recommendations,
            ),
            const SizedBox(height: 12),
            _MetricsRow(
              savingRate: savingRate,
              remainingDays: remainingDays,
              remainingAmount: remainingAmount,
              amountFormat: _amountFormat,
            ),
            const SizedBox(height: 12),
            ...recommendations.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: _RecoCard(reco: r),
                )),
            const SizedBox(height: 12),
            _DownloadBanner(onDownload: _downloadPdf),
            const SizedBox(height: 10),
            const _InfoBanner(),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final VoidCallback onDownload;
  const _HeroHeader({required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4DA1F0), Color(0xFF00BFA5)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Rapport Financier IA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: onDownload,
            icon: const Icon(Icons.cloud_download_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final double delta;
  final String monthLabel;

  const _ScoreCard({
    required this.score,
    required this.delta,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF9BA7B3)),
                const SizedBox(width: 8),
                const Text(
                  "Période d'analyse",
                  style: TextStyle(color: Color(0xFF7A8794), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              monthLabel,
              style: const TextStyle(
                color: Color(0xFF2C3A4B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Score Financier IA',
                  style: TextStyle(
                    color: Color(0xFF2C3A4B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: delta >= 0 ? const Color(0xFF00BFA5) : const Color(0xFFE53935),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _CircularScore(score: score),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Excellente gestion',
                        style: TextStyle(
                          color: Color(0xFF00BFA5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Votre score a augmenté grâce à un meilleur contrôle des dépenses.',
                        style: TextStyle(
                          color: Color(0xFF5B6772),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularScore extends StatelessWidget {
  final int score;

  const _CircularScore({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 8,
              backgroundColor: const Color(0xFFE9EEF3),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00BFA5)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: Color(0xFF2C3A4B),
                ),
              ),
              const Text(
                '/ 100',
                style: TextStyle(color: Color(0xFF7A8794), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String summary;
  final List<String> bullets;

  const _AnalysisCard({required this.summary, required this.bullets});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFE8F4FF),
                  child: Icon(Icons.analytics_outlined, color: Color(0xFF00BFA5)),
                ),
                SizedBox(width: 10),
                Text(
                  'Analyse IA du mois',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3A4B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              summary,
              style: const TextStyle(
                color: Color(0xFF2C3A4B),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            if (bullets.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: bullets
                      .map(
                        (b) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• $b',
                            style: const TextStyle(color: Color(0xFF2C3A4B), height: 1.3),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final double savingRate;
  final int remainingDays;
  final int remainingAmount;
  final NumberFormat amountFormat;

  const _MetricsRow({
    required this.savingRate,
    required this.remainingDays,
    required this.remainingAmount,
    required this.amountFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _MetricBadge(
            label: "Taux d'épargne",
            value: '${savingRate.toStringAsFixed(0)}%',
            color: const Color(0xFF00BFA5),
          ),
          const SizedBox(width: 8),
          _MetricBadge(
            label: 'Jours restants',
            value: '$remainingDays',
            color: const Color(0xFF00A4E1),
          ),
          const SizedBox(width: 8),
          _MetricBadge(
            label: 'Reste MAD',
            value: amountFormat.format(remainingAmount),
            color: const Color(0xFF007AFF),
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF5B6772), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reco {
  final String title;
  final String category;
  final String body;
  final String savings;
  final String level;
  final Color color;
  final IconData icon;

  const _Reco({
    required this.title,
    required this.category,
    required this.body,
    required this.savings,
    required this.level,
    required this.color,
    required this.icon,
  });
}

class _RecoCard extends StatelessWidget {
  final _Reco reco;

  const _RecoCard({required this.reco});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBadge(color: reco.color, icon: reco.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            reco.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C3A4B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: reco.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reco.level,
                            style: TextStyle(
                              color: reco.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reco.category,
                      style: const TextStyle(
                        color: Color(0xFF7A8794),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reco.body,
                      style: const TextStyle(
                        color: Color(0xFF5B6772),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (reco.savings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Économie: ${reco.savings}',
              style: TextStyle(
                color: reco.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _IconBadge({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _DownloadBanner extends StatelessWidget {
  final VoidCallback onDownload;

  const _DownloadBanner({required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF00BFA5)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: onDownload,
            child: const Text(
              'Télécharger le rapport PDF',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: const [
            Icon(Icons.info_outline, color: Color(0xFF4DA1F0)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ce rapport est généré automatiquement à partir de vos données et recommandations IA.',
                style: TextStyle(
                  color: Color(0xFF5B6772),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
