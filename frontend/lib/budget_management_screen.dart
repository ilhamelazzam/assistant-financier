import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/budget_models.dart';
import 'services/backend_api.dart';
import 'services/backend_factory.dart';

class BudgetScreenArgs {
  final String? highlightCategory;
  final bool openEdit;

  BudgetScreenArgs({
    this.highlightCategory,
    this.openEdit = false,
  });
}

class BudgetManagementScreen extends StatefulWidget {
  const BudgetManagementScreen({super.key});

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> {
  final BackendApi _api = BackendFactory.create();
  final NumberFormat _amountFormat = NumberFormat.decimalPattern('fr_FR');
  final List<String> _categorySuggestions = const [
    'Alimentation',
    'Transport',
    'Logement',
    'Shopping',
    'Sante',
    'Loisirs',
    'Education',
    'Voyage',
    'Abonnements',
    'Investissements',
  ];

  BudgetSnapshot? _snapshot;
  bool _loading = true;
  String? _error;
  bool _handledArgs = false;
  String? _targetCategory;
  bool _targetOpenEdit = false;

  @override
  void initState() {
    super.initState();
    _refreshSnapshot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is BudgetScreenArgs) {
      _targetCategory = args.highlightCategory;
      _targetOpenEdit = args.openEdit;
    }
    _handledArgs = true;
  }

  Future<void> _refreshSnapshot() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchBudgetSnapshot();
      if (!mounted) return;
      setState(() => _snapshot = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
    if (!mounted) return;
    setState(() => _loading = false);
    _applyPendingBudgetAction();
  }

  void _applyPendingBudgetAction() {
    if (_snapshot == null || _targetCategory == null) {
      return;
    }
    final target = _targetCategory!.toLowerCase();
    BudgetCategory? match;
    for (final category in _snapshot!.categories) {
      if (category.category.toLowerCase() == target) {
        match = category;
        break;
      }
    }
    _targetCategory = null;
    final shouldEdit = _targetOpenEdit;
    _targetOpenEdit = false;
    if (match == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (shouldEdit) {
        _openBudgetSheet(existing: match!);
      } else {
        _showBudgetDetails(match!);
      }
    });
  }

  String _formatAmount(double value) => '${_amountFormat.format(value)} MAD';

  Future<void> _openBudgetSheet({BudgetCategory? existing}) async {
    final monthlyNames = (_snapshot?.categories ?? const [])
        .where((c) => c.periodType == BudgetPeriodType.monthly)
        .map((c) => c.category.toLowerCase())
        .toSet();
    if (existing != null && existing.periodType == BudgetPeriodType.monthly) {
      monthlyNames.remove(existing.category.toLowerCase());
    }

    final shouldReload = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BudgetFormSheet(
        api: _api,
        suggestions: _categorySuggestions,
        existingMonthlyCategories: monthlyNames,
        initialBudget: existing,
      ),
    );
    if (shouldReload == true) {
      _refreshSnapshot();
    }
  }

  Future<void> _showBudgetDetails(BudgetCategory category) async {
    if (category.id == null) return;
    try {
      final latest = await _api.fetchBudget(category.id!.toInt());
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _BudgetDetailsSheet(
          budget: latest,
          formatAmount: _formatAmount,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger les details : $error')),
      );
    }
  }

  Future<void> _deleteBudget(BudgetCategory category) async {
    if (category.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le budget'),
        content: Text(
          'Etes-vous sur de vouloir supprimer le budget ${category.category} ? Cette action est irreversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteBudget(category.id!.toInt());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budget ${category.category} supprime.')),
      );
      _refreshSnapshot();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression impossible : $error')),
      );
    }
  }

  Future<void> _showAllBudgetsSheet() async {
    final snapshot = _snapshot;
    if (snapshot == null || snapshot.categories.isEmpty) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _AllBudgetsSheet(
        categories: snapshot.categories,
        formatAmount: _formatAmount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2C3A4B),
        titleSpacing: 0,
        title: Text(
          'Gestion du budget',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
      return _ErrorState(message: _error!, onRetry: _refreshSnapshot);
    }
    final snapshot = _snapshot;
    if (snapshot == null) {
      return _ErrorState(
        message: 'Impossible de recuperer les donnees budgets.',
        onRetry: _refreshSnapshot,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshSnapshot,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _BudgetHeader(
            totalBudget: snapshot.totalBudget,
            spent: snapshot.totalSpent,
            usage: snapshot.usage,
            onAdd: () => _openBudgetSheet(),
            formatAmount: _formatAmount,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3A4B),
                  ),
                ),
                TextButton(
                  onPressed: snapshot.categories.isEmpty ? null : _showAllBudgetsSheet,
                  child: const Text(
                    'Tout voir',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF00A4E1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (snapshot.categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _EmptyBudgetState(onAdd: () => _openBudgetSheet()),
            )
          else
            ...snapshot.categories.map(
              (category) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: _CategoryCard(
                  category: category,
                  formatAmount: _formatAmount,
                  onView: () => _showBudgetDetails(category),
                  onEdit: () => _openBudgetSheet(existing: category),
                  onDelete: () => _deleteBudget(category),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _AddBudgetButton(onPressed: () => _openBudgetSheet()),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _AdviceCard(
              advice: snapshot.advice,
              fallback: snapshot.remaining <= 0
                  ? 'Vous avez atteint votre budget global ce mois-ci.'
                  : 'Votre budget est bien gere, continuez ainsi !',
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetHeader extends StatelessWidget {
  final double totalBudget;
  final double spent;
  final double usage;
  final VoidCallback onAdd;
  final String Function(double) formatAmount;

  const _BudgetHeader({
    required this.totalBudget,
    required this.spent,
    required this.usage,
    required this.onAdd,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4DA1F0), Color(0xFF01BFA4)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
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
                  SizedBox(width: 8),
                  Text(
                    'Gestion du Budget',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Budget mensuel',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatAmount(totalBudget),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Depense',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatAmount(spent),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 8,
                    color: Colors.white.withValues(alpha: 0.25),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: usage.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFE0F7FA)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${(usage * 100).round()}% utilise',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _BudgetCardAction { view, edit, delete }

class _CategoryCard extends StatelessWidget {
  final BudgetCategory category;
  final String Function(double) formatAmount;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const List<Color> _palette = [
    Color(0xFF00BFA5),
    Color(0xFF4A90E2),
    Color(0xFF00A4E1),
    Color(0xFF1E88E5),
    Color(0xFF26C6DA),
    Color(0xFF00796B),
    Color(0xFF8E44AD),
    Color(0xFFFF7043),
  ];

  const _CategoryCard({
    required this.category,
    required this.formatAmount,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _accentColor {
    final idx = category.category.hashCode % _palette.length;
    return _palette[idx.abs()];
  }

  @override
  Widget build(BuildContext context) {
    final percent = category.percent;
    final color = _accentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconForCategory(category.category), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3A4B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatAmount(category.spentAmount)} / ${formatAmount(category.budgetAmount)}',
                      style: const TextStyle(
                        color: Color(0xFF5B6772),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_BudgetCardAction>(
                onSelected: (action) {
                  switch (action) {
                    case _BudgetCardAction.view:
                      onView();
                      break;
                    case _BudgetCardAction.edit:
                      onEdit();
                      break;
                    case _BudgetCardAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _BudgetCardAction.view,
                    child: ListTile(
                      leading: Icon(Icons.visibility_outlined),
                      title: Text('Voir les details'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _BudgetCardAction.edit,
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Modifier le budget'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _BudgetCardAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Supprimer le budget'),
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_horiz, color: Color(0xFF9BA7B3)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 8,
              color: const Color(0xFFEFF3F7),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(percent * 100).round()}% utilise',
                style: const TextStyle(
                  color: Color(0xFF5B6772),
                  fontSize: 12,
                ),
              ),
              Text(
                'Reste ${formatAmount(max(category.remaining, 0))}',
                style: const TextStyle(
                  color: Color(0xFF00A4E1),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (category.note?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              category.note ?? '',
              style: const TextStyle(
                color: Color(0xFF8D96A3),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForCategory(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('aliment')) return Icons.restaurant_menu;
    if (normalized.contains('transport') || normalized.contains('trajet')) return Icons.directions_bus;
    if (normalized.contains('logement') || normalized.contains('loyer') || normalized.contains('maison')) {
      return Icons.home_outlined;
    }
    if (normalized.contains('sant')) return Icons.favorite_border;
    if (normalized.contains('loisir') || normalized.contains('vacance')) return Icons.celebration_outlined;
    if (normalized.contains('shopping') || normalized.contains('cadeau')) return Icons.shopping_bag;
    if (normalized.contains('abonnement') || normalized.contains('facture')) return Icons.receipt_long;
    if (normalized.contains('education')) return Icons.school;
    return Icons.savings_outlined;
  }
}

class _AdviceCard extends StatelessWidget {
  final BudgetTip? advice;
  final String fallback;

  const _AdviceCard({required this.advice, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final tone = advice?.tone ?? 'info';
    final isWarning = tone.toLowerCase().contains('warn');
    final color = isWarning ? const Color(0xFFFFD54F) : const Color(0xFF80CBC4);

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isWarning ? Icons.warning_amber_rounded : Icons.lightbulb_outline, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advice?.category.isNotEmpty == true ? 'Conseil IA - ${advice!.category}' : 'Conseil IA',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3A4B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  advice?.message ?? fallback,
                  style: const TextStyle(
                    color: Color(0xFF5B6772),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBudgetButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddBudgetButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          onPressed: onPressed,
          child: const Text(
            'Ajouter un budget',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _EmptyBudgetState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyBudgetState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.category_outlined, size: 48, color: Color(0xFF00A4E1)),
          const SizedBox(height: 12),
          const Text(
            'Aucun budget defini',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2C3A4B)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez votre premier budget pour suivre vos depenses categorie par categorie.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF5B6772)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onAdd,
            child: const Text('Creer un budget'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: Color(0xFF9BA7B3)),
            const SizedBox(height: 12),
            Text(
              'Oups...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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

class _BudgetFormSheet extends StatefulWidget {
  final BackendApi api;
  final Set<String> existingMonthlyCategories;
  final List<String> suggestions;
  final BudgetCategory? initialBudget;

  const _BudgetFormSheet({
    required this.api,
    required this.existingMonthlyCategories,
    required this.suggestions,
    this.initialBudget,
  });

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  late BudgetPeriodType _periodType;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _alertThreshold;
  late int _periodMonth;
  late int _periodYear;
  bool _saving = false;

  static const List<String> _monthLabels = [
    'Janvier',
    'Fevrier',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Aout',
    'Septembre',
    'Octobre',
    'Novembre',
    'Decembre',
  ];

  bool get _isEditing => widget.initialBudget != null && widget.initialBudget!.id != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialBudget;
    if (initial != null) {
      _categoryController.text = initial.category;
      _amountController.text = initial.budgetAmount.toStringAsFixed(0);
      _noteController.text = initial.note ?? '';
      _periodType = initial.periodType;
      _startDate = initial.customStart;
      _endDate = initial.customEnd;
      _alertThreshold = initial.alertThreshold;
      _periodMonth = initial.periodMonth;
      _periodYear = initial.periodYear;
    } else {
      _periodType = BudgetPeriodType.monthly;
      final now = DateTime.now();
      _periodMonth = now.month;
      _periodYear = now.year;
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final years = List<int>.generate(4, (index) => DateTime.now().year - 1 + index);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isEditing ? 'Modifier un budget' : 'Ajouter un budget',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFF2C3A4B),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Categorie',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _categoryController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ex: Alimentation',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    validator: _validateCategory,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.suggestions
                        .map(
                          (suggestion) => ChoiceChip(
                            label: Text(suggestion),
                            selected: _categoryController.text.trim().toLowerCase() == suggestion.toLowerCase(),
                            onSelected: (_) {
                              _categoryController.text = suggestion;
                              setState(() {});
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Montant du budget',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixText: 'MAD',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    validator: _validateAmount,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<BudgetPeriodType>(
                    key: ValueKey('period-type-$_periodType'),
                    initialValue: _periodType,
                    decoration: InputDecoration(
                      labelText: 'Periode',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    items: BudgetPeriodType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _periodType = value;
                        if (value == BudgetPeriodType.monthly) {
                          _startDate = null;
                          _endDate = null;
                        }
                      });
                    },
                  ),
                  if (_periodType == BudgetPeriodType.monthly) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('period-month-$_periodMonth'),
                            initialValue: _periodMonth,
                            decoration: InputDecoration(
                              labelText: 'Mois',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            items: List.generate(
                              12,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text(_monthLabels[index]),
                              ),
                            ),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _periodMonth = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('period-year-$_periodYear'),
                            initialValue: _periodYear,
                            decoration: InputDecoration(
                              labelText: 'Annee',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            items: years
                                .map(
                                  (year) => DropdownMenuItem(
                                    value: year,
                                    child: Text(year.toString()),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _periodYear = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DatePickerField(
                            label: 'Date debut',
                            placeholder: 'Choisir',
                            value: _startDate,
                            onTap: _pickStartDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DatePickerField(
                            label: 'Date fin',
                            placeholder: 'Choisir',
                            value: _endDate,
                            onTap: _pickEndDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _periodType == BudgetPeriodType.weekly
                          ? 'La semaine couvre 7 jours a partir de la date de debut.'
                          : 'Choisissez une periode personnalisee pour ce budget.',
                      style: const TextStyle(color: Color(0xFF5B6772), fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Me prevenir a',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildAlertChip(label: 'Jamais', value: null),
                      _buildAlertChip(label: '70%', value: 70),
                      _buildAlertChip(label: '90%', value: 90),
                      _buildAlertChip(label: '100%', value: 100),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description / note',
                      hintText: 'Ex: Budget repas + cafes',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _saving ? null : () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(_saving ? 'En cours...' : 'Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertChip({required String label, int? value}) {
    final selected = _alertThreshold == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _alertThreshold = value),
    );
  }

  String? _validateCategory(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'La categorie est obligatoire';
    }
    if (_periodType == BudgetPeriodType.monthly &&
        widget.existingMonthlyCategories.contains(text.toLowerCase())) {
      return 'Cette categorie dispose deja dun budget ce mois-ci';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    final cleaned = value?.replaceAll(',', '.') ?? '';
    final amount = double.tryParse(cleaned);
    if (amount == null || amount <= 0) {
      return 'Saisissez un montant valide';
    }
    return null;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _startDate ?? now;
    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
    );
    if (result == null) return;
    setState(() {
      _startDate = result;
      if (_periodType == BudgetPeriodType.weekly && (_endDate == null || _endDate!.isBefore(result))) {
        _endDate = result.add(const Duration(days: 6));
      }
    });
  }

  Future<void> _pickEndDate() async {
    final baseDate = _startDate ?? DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _endDate ?? baseDate,
      firstDate: baseDate,
      lastDate: DateTime(baseDate.year + 3),
    );
    if (result == null) return;
    setState(() => _endDate = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    if (_periodType != BudgetPeriodType.monthly) {
      if (_startDate == null) {
        _showToast('Choisissez une date de debut');
        return;
      }
      _endDate ??= _periodType == BudgetPeriodType.weekly ? _startDate!.add(const Duration(days: 6)) : null;
      if (_periodType == BudgetPeriodType.custom && _endDate == null) {
        _showToast('Choisissez une date de fin');
        return;
      }
      if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
        _showToast('La date de fin doit etre posterieure a la date de debut');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await widget.api.updateBudget(
          id: widget.initialBudget!.id!.toInt(),
          category: _categoryController.text.trim(),
          amount: amount,
          periodType: _periodType,
          periodMonth: _periodMonth,
          periodYear: _periodYear,
          startDate: _periodType == BudgetPeriodType.monthly ? null : _startDate,
          endDate: _periodType == BudgetPeriodType.monthly ? null : _endDate,
          alertThreshold: _alertThreshold,
          note: _noteController.text,
        );
      } else {
        await widget.api.createBudget(
          category: _categoryController.text.trim(),
          amount: amount,
          periodType: _periodType,
          periodMonth: _periodMonth,
          periodYear: _periodYear,
          startDate: _periodType == BudgetPeriodType.monthly ? null : _startDate,
          endDate: _periodType == BudgetPeriodType.monthly ? null : _endDate,
          alertThreshold: _alertThreshold,
          note: _noteController.text,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Budget mis a jour' : 'Budget ajoute'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showToast('Impossible denregistrer: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BudgetDetailsSheet extends StatelessWidget {
  final BudgetCategory budget;
  final String Function(double) formatAmount;

  const _BudgetDetailsSheet({
    required this.budget,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD4E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                budget.category,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                budget.periodLabel,
                style: const TextStyle(color: Color(0xFF5B6772)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    _detailsTile('Montant defini', formatAmount(budget.budgetAmount)),
                    _detailsTile('Depenses', formatAmount(budget.spentAmount)),
                    _detailsTile('Reste', formatAmount(budget.remaining)),
                    _detailsTile('Taux utilise', '${(budget.percent * 100).round()}%'),
                    if (budget.alertThreshold != null)
                      _detailsTile('Alerte', '${budget.alertThreshold}%'),
                    if (budget.customStart != null)
                      _detailsTile('Debut', dateFormat.format(budget.customStart!)),
                    if (budget.customEnd != null)
                      _detailsTile('Fin', dateFormat.format(budget.customEnd!)),
                    const Divider(height: 32),
                    if (budget.note?.isNotEmpty == true)
                      Text(
                        budget.note!,
                        style: const TextStyle(color: Color(0xFF2C3A4B)),
                      )
                    else
                      const Text(
                        'Aucune note associee a ce budget.',
                        style: TextStyle(color: Color(0xFF9BA7B3)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailsTile(String label, String value) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: Color(0xFF5B6772), fontSize: 13)),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2C3A4B)),
      ),
    );
  }
}

class _AllBudgetsSheet extends StatelessWidget {
  final List<BudgetCategory> categories;
  final String Function(double) formatAmount;

  const _AllBudgetsSheet({
    required this.categories,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD4E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Budgets du mois',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ListTile(
                      title: Text(category.category),
                      subtitle: LinearProgressIndicator(
                        value: category.percent,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFEFF3F7),
                        color: const Color(0xFF4A90E2),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${formatAmount(category.spentAmount)} / ${formatAmount(category.budgetAmount)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          Text(
                            'Reste ${formatAmount(category.remaining)}',
                            style: const TextStyle(color: Color(0xFF5B6772), fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(),
                  itemCount: categories.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String placeholder;
  final DateTime? value;
  final VoidCallback? onTap;

  const _DatePickerField({
    required this.label,
    required this.placeholder,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    final display = value == null ? placeholder : formatter.format(value!);
    final enabled = onTap != null;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          enabled: enabled,
        ),
        child: Text(
          display,
          style: TextStyle(
            color: value == null ? const Color(0xFF9BA7B3) : const Color(0xFF2C3A4B),
          ),
        ),
      ),
    );
  }
}
