enum BudgetPeriodType { monthly, weekly, custom }

extension BudgetPeriodTypeX on BudgetPeriodType {
  String get apiValue {
    switch (this) {
      case BudgetPeriodType.monthly:
        return 'MONTHLY';
      case BudgetPeriodType.weekly:
        return 'WEEKLY';
      case BudgetPeriodType.custom:
        return 'CUSTOM';
    }
  }

  String get label {
    switch (this) {
      case BudgetPeriodType.monthly:
        return 'Mensuel';
      case BudgetPeriodType.weekly:
        return 'Hebdomadaire';
      case BudgetPeriodType.custom:
        return 'Personnalise';
    }
  }
}

BudgetPeriodType parseBudgetPeriodType(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'WEEKLY':
      return BudgetPeriodType.weekly;
    case 'CUSTOM':
      return BudgetPeriodType.custom;
    case 'MONTHLY':
    default:
      return BudgetPeriodType.monthly;
  }
}

class BudgetTip {
  final String tone;
  final String message;
  final String category;

  const BudgetTip({
    required this.tone,
    required this.message,
    required this.category,
  });

  bool get isWarning => tone.toLowerCase().contains('warn');

  factory BudgetTip.fromJson(Map<String, dynamic> json) {
    return BudgetTip(
      tone: json['tone'] as String? ?? 'info',
      message: json['message'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }
}

class BudgetCategory {
  final int? id;
  final String category;
  final double budgetAmount;
  final double spentAmount;
  final double remaining;
  final double usage;
  final BudgetPeriodType periodType;
  final int periodMonth;
  final int periodYear;
  final String periodLabel;
  final int? alertThreshold;
  final String? note;
  final DateTime? customStart;
  final DateTime? customEnd;

  const BudgetCategory({
    required this.id,
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
    required this.remaining,
    required this.usage,
    required this.periodType,
    required this.periodMonth,
    required this.periodYear,
    required this.periodLabel,
    this.alertThreshold,
    this.note,
    this.customStart,
    this.customEnd,
  });

  double get percent => budgetAmount <= 0 ? 0 : (spentAmount / budgetAmount).clamp(0, 1);

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      id: json['id'] as int?,
      category: json['category'] as String? ?? '',
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble() ?? 0,
      spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
      usage: (json['usage'] as num?)?.toDouble() ?? 0,
      periodType: parseBudgetPeriodType(json['periodType'] as String?),
      periodMonth: json['periodMonth'] as int? ?? 1,
      periodYear: json['periodYear'] as int? ?? DateTime.now().year,
      periodLabel: json['periodLabel'] as String? ?? '',
      alertThreshold: json['alertThreshold'] as int?,
      note: json['note'] as String?,
      customStart: _parseDate(json['customStart'] as String?),
      customEnd: _parseDate(json['customEnd'] as String?),
    );
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class BudgetSnapshot {
  final int month;
  final int year;
  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final List<BudgetCategory> categories;
  final BudgetTip? advice;

  const BudgetSnapshot({
    required this.month,
    required this.year,
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.categories,
    this.advice,
  });

  double get usage => totalBudget <= 0 ? 0 : (totalSpent / totalBudget).clamp(0, 1);

  factory BudgetSnapshot.fromJson(Map<String, dynamic> json) {
    final categories = (json['categories'] as List<dynamic>? ?? const [])
        .map((entry) => BudgetCategory.fromJson(entry as Map<String, dynamic>))
        .toList();
    final tipJson = json['advice'] as Map<String, dynamic>?;
    return BudgetSnapshot(
      month: json['month'] as int? ?? DateTime.now().month,
      year: json['year'] as int? ?? DateTime.now().year,
      totalBudget: (json['totalBudget'] as num?)?.toDouble() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
      categories: categories,
      advice: tipJson == null ? null : BudgetTip.fromJson(tipJson),
    );
  }
}
