import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/analysis_models.dart';
import 'models/goal_chat_conversation.dart';
import 'models/goal_chat_history.dart';
import 'goal_selection_screen.dart';
import 'services/backend_api.dart';
import 'services/app_session.dart';

class AnalysisScreenArgs {
  final AnalysisPeriod? initialPeriod;
  final bool focusRecommendations;

  AnalysisScreenArgs({
    this.initialPeriod,
    this.focusRecommendations = false,
  });
}

class FinancialAnalysisScreen extends StatefulWidget {
  const FinancialAnalysisScreen({super.key});

  @override
  State<FinancialAnalysisScreen> createState() => _FinancialAnalysisScreenState();
}

class _FinancialAnalysisScreenState extends State<FinancialAnalysisScreen> {
  final BackendApi _api = BackendApi();
  final NumberFormat _amountFormat = NumberFormat.decimalPattern('fr_FR');
  final ScrollController _scrollController = ScrollController();

  AnalysisPeriod _selectedPeriod = AnalysisPeriod.month;
  bool _loading = true;
  String? _error;
  Map<AnalysisPeriod, PeriodAnalysis> _periods = {};
  bool _handledArgs = false;
  bool _shouldScrollToRecommendations = false;
  bool _planLoading = false;
  String? _planError;
  String? _planText;
  List<_ChatbotReco> _chatbotRecos = const [];

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
    _loadVoicePlan();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AnalysisScreenArgs) {
      if (args.initialPeriod != null) {
        _selectedPeriod = args.initialPeriod!;
      }
      _shouldScrollToRecommendations = args.focusRecommendations;
    }
    _handledArgs = true;
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.fetchFinancialAnalysis();
      if (!mounted) return;
      setState(() {
        _periods = response.periods;
        if (_periods.isNotEmpty && !_periods.containsKey(_selectedPeriod)) {
          _selectedPeriod = _periods.keys.first;
        }
        _loading = false;
      });
      _maybeScrollToRecommendations();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  String _compareLabel() {
    switch (_selectedPeriod) {
      case AnalysisPeriod.week:
        return 'vs semaine derniere';
      case AnalysisPeriod.month:
        return 'vs mois dernier';
      case AnalysisPeriod.year:
        return 'vs annee derniere';
    }
  }

  void _maybeScrollToRecommendations() {
    if (!_shouldScrollToRecommendations) return;
    if (!_scrollController.hasClients) return;
    _shouldScrollToRecommendations = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadVoicePlan() async {
    final user = AppSession.instance.currentUser;
    if (user == null) return;
    setState(() {
      _planLoading = true;
      _planError = null;
    });
    try {
      final history = await _api.fetchGoalChatHistory(userId: user.userId, limit: 8);
      if (!mounted) return;
      if (history.isEmpty) {
        setState(() {
          _planText = null;
          _planLoading = false;
          _chatbotRecos = const [];
        });
        return;
      }
      GoalChatHistoryItem? candidate;
      for (final item in history) {
        if (item.starred) {
          candidate = item;
          break;
        }
      }
      candidate ??= history.first;
      final recos = <_ChatbotReco>[];
      for (final item in history.where((it) => it.starred)) {
        if (item.recommendations.isNotEmpty) {
          for (final reco in item.recommendations) {
            if (reco.trim().isEmpty) continue;
            recos.add(_ChatbotReco(item: item, text: reco));
          }
        } else if (item.assistantReply.trim().isNotEmpty) {
          recos.add(_ChatbotReco(item: item, text: item.assistantReply));
        }
      }
      setState(() {
        _planText = candidate?.assistantReply.trim();
        _planLoading = false;
        _chatbotRecos = recos;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _planError = error.toString();
        _planLoading = false;
        _chatbotRecos = const [];
      });
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
          'Analyse Financiere',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _AnalysisError(message: _error!, onRetry: _loadAnalysis);
    }
    if (_periods.isEmpty) {
      return _AnalysisError(
        message: 'Aucune donnee disponible pour cette periode.',
        onRetry: _loadAnalysis,
      );
    }
    final stats = _periods[_selectedPeriod] ?? _periods.values.first;

    return RefreshIndicator(
      onRefresh: _loadAnalysis,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _HeroHeader(
            selected: _selectedPeriod,
            onSelected: (period) {
              if (_periods.containsKey(period)) {
                setState(() => _selectedPeriod = period);
              }
            },
          ),
          _KpiRow(
            stats: stats,
            formatter: _amountFormat,
            referenceLabel: _compareLabel(),
          ),
          _TrendCard(stats: stats),
          _PieCard(
            stats.distribution,
            formatter: _amountFormat,
            totalAmount: stats.expense,
          ),
          _InsightCard(snapshot: stats),
          if (_planLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_planError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AnalysisError(message: _planError!, onRetry: _loadVoicePlan),
            )
          else if (_planText != null && _planText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _PlanCard(planText: _planText!),
            ),
          if (_chatbotRecos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _ChatbotRecoList(
                recos: _chatbotRecos,
                onOpen: _openConversation,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openConversation(GoalChatHistoryItem item) async {
    final userId = AppSession.instance.currentUser?.userId;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour ouvrir cette session.')),
      );
      return;
    }
    try {
      final conversation =
          await _api.fetchGoalChatConversation(userId: userId, sessionId: item.sessionId);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/voice',
        arguments: VoiceScreenArgs(
          goalId: conversation.goalId,
          goalLabel: conversation.goalLabel,
          sessionId: conversation.sessionId,
          initialMessages: conversation.messages,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger la session : $error')),
      );
    }
  }
}

class _PlanCard extends StatelessWidget {
  final String planText;

  const _PlanCard({required this.planText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
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
                child: Icon(Icons.task_alt_outlined, color: Color(0xFF00BFA5)),
              ),
              SizedBox(width: 10),
              Text(
                'Plan IA (chatbot)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3A4B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            planText,
            style: const TextStyle(
              color: Color(0xFF5B6772),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatbotRecoList extends StatelessWidget {
  final List<_ChatbotReco> recos;
  final void Function(GoalChatHistoryItem) onOpen;

  const _ChatbotRecoList({required this.recos, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.recommend_outlined, color: Color(0xFF00BFA5)),
            SizedBox(width: 8),
            Text(
              'Recommandations (chatbot)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3A4B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...recos.map(
          (r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _RecoCard(
              text: r.text,
              subtitle: r.item.goalLabel,
              onTap: () => onOpen(r.item),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecoCard extends StatelessWidget {
  final String text;
  final String subtitle;
  final VoidCallback onTap;

  const _RecoCard({
    required this.text,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF4DA1F0), Color(0xFF00BFA5)],
                  ),
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3A4B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7A8794),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF9BA7B3), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatbotReco {
  final GoalChatHistoryItem item;
  final String text;

  const _ChatbotReco({required this.item, required this.text});
}

class _HeroHeader extends StatelessWidget {
  final AnalysisPeriod selected;
  final ValueChanged<AnalysisPeriod> onSelected;

  const _HeroHeader({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.arrow_back_ios, color: Colors.white70, size: 16),
                  SizedBox(width: 10),
                  Text(
                    'Analyse Financiere',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SegmentChip(
                label: 'Semaine',
                active: selected == AnalysisPeriod.week,
                onTap: () => onSelected(AnalysisPeriod.week),
              ),
              _SegmentChip(
                label: 'Mois',
                active: selected == AnalysisPeriod.month,
                onTap: () => onSelected(AnalysisPeriod.month),
              ),
              _SegmentChip(
                label: 'Annee',
                active: selected == AnalysisPeriod.year,
                onTap: () => onSelected(AnalysisPeriod.year),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFF2C3A4B) : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final PeriodAnalysis stats;
  final NumberFormat formatter;
  final String referenceLabel;

  const _KpiRow({
    required this.stats,
    required this.formatter,
    required this.referenceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _KpiCard(
              title: 'Revenus',
              amount: '${formatter.format(stats.revenue)} MAD',
              delta: stats.revenueChange,
              positive: true,
              referenceLabel: referenceLabel,
              icon: Icons.trending_up,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KpiCard(
              title: 'Depenses',
              amount: '${formatter.format(stats.expense)} MAD',
              delta: stats.expenseChange,
              positive: false,
              referenceLabel: referenceLabel,
              icon: Icons.trending_down,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String amount;
  final double delta;
  final bool positive;
  final String referenceLabel;
  final IconData icon;

  const _KpiCard({
    required this.title,
    required this.amount,
    required this.delta,
    required this.positive,
    required this.referenceLabel,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final deltaText = '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}% $referenceLabel';
    final deltaColor = positive ? const Color(0xFF00BFA5) : const Color(0xFFE53935);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: deltaColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: deltaColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3A4B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF2C3A4B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            deltaText,
            style: TextStyle(
              color: positive ? const Color(0xFF00BFA5) : const Color(0xFFE53935),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final PeriodAnalysis stats;

  const _TrendCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tendances sur 5 periodes',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3A4B),
              ),
            ),
            const SizedBox(height: 12),
            _TrendChart(
              revenues: stats.revenueTrend,
              expenses: stats.expenseTrend,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _LegendDot(color: Color(0xFF00BFA5), label: 'Revenus'),
                SizedBox(width: 18),
                _LegendDot(color: Color(0xFF1E88E5), label: 'Depenses'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<double> revenues;
  final List<double> expenses;

  const _TrendChart({required this.revenues, required this.expenses});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _TrendPainter(revenues: revenues, expenses: expenses),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> revenues;
  final List<double> expenses;

  _TrendPainter({required this.revenues, required this.expenses});

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 12.0;
    final maxValue = ([
      ...revenues,
      ...expenses,
    ].reduce((a, b) => a > b ? a : b)) *
        1.1;

    Offset pointFor(int index, double value) {
      final x = padding + (index / (revenues.length - 1)) * (size.width - padding * 2);
      final y = size.height - padding - (value / maxValue) * (size.height - padding * 2);
      return Offset(x, y);
    }

    Path buildPath(List<double> values) {
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final point = pointFor(i, values[i]);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      return path;
    }

    final revenuePaint = Paint()
      ..color = const Color(0xFF00BFA5)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final expensePaint = Paint()
      ..color = const Color(0xFF1E88E5)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(buildPath(revenues), revenuePaint);
    canvas.drawPath(buildPath(expenses), expensePaint);

    final revenueDot = Paint()..color = const Color(0xFF00BFA5);
    final expenseDot = Paint()..color = const Color(0xFF1E88E5);
    for (var i = 0; i < revenues.length; i++) {
      canvas.drawCircle(pointFor(i, revenues[i]), 4, revenueDot);
      canvas.drawCircle(pointFor(i, expenses[i]), 4, expenseDot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF5B6772), fontSize: 12),
        ),
      ],
    );
  }
}

class _PieCard extends StatelessWidget {
  final List<CategoryShare> slices;
  final NumberFormat formatter;
  final double totalAmount;

  const _PieCard(this.slices, {required this.formatter, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Repartition des depenses',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3A4B),
              ),
            ),
            const SizedBox(height: 12),
            if (slices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Pas suffisamment de donnees pour tracer cette periode.',
                    style: TextStyle(color: Color(0xFF5B6772)),
                  ),
                ),
              )
            else
              SizedBox(
                height: 220,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _DonutPainter(slices),
                        );
                      },
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatter.format(totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xFF2C3A4B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Total depenses',
                          style: TextStyle(color: Color(0xFF5B6772), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              children: slices
                  .map((slice) => _LegendDot(color: slice.color, label: slice.label))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<CategoryShare> slices;

  _DonutPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.butt;

    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    double startAngle = -1.57;

    for (final slice in slices) {
      if (total <= 0) continue;
      final sweep = (slice.value / total) * 6.28318;
      paint.color = slice.color;
      canvas.drawArc(rect.deflate(16), startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InsightCard extends StatelessWidget {
  final PeriodAnalysis snapshot;

  const _InsightCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFE8F4FF),
                  child: Icon(Icons.lightbulb_outline, color: Color(0xFF03A9F4)),
                ),
                const SizedBox(width: 10),
                Text(
                  snapshot.insightTitle.isEmpty ? 'Analyse IA' : snapshot.insightTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3A4B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              snapshot.insightBody.isEmpty
                  ? 'Pas encore de recommandations pour cette periode.'
                  : snapshot.insightBody,
              style: const TextStyle(
                color: Color(0xFF5B6772),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            if (snapshot.recommendations.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F4FF), Color(0xFFDDF7F5)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LegendDot(color: Color(0xFFFFC107), label: 'Recommandations'),
                    const SizedBox(height: 8),
                    ...snapshot.recommendations.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '- $tip',
                          style: const TextStyle(color: Color(0xFF2C3A4B), height: 1.35),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _AnalysisError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Color(0xFF9BA7B3)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF5B6772)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
