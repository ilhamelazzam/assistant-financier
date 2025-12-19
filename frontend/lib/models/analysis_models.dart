import 'package:flutter/material.dart';

enum AnalysisPeriod { week, month, year }

AnalysisPeriod parseAnalysisPeriod(String raw) {
  switch (raw.toUpperCase()) {
    case 'WEEK':
      return AnalysisPeriod.week;
    case 'YEAR':
      return AnalysisPeriod.year;
    case 'MONTH':
    default:
      return AnalysisPeriod.month;
  }
}

class FinancialAnalysis {
  final Map<AnalysisPeriod, PeriodAnalysis> periods;

  const FinancialAnalysis({required this.periods});

  factory FinancialAnalysis.fromJson(Map<String, dynamic> json) {
    final data = <AnalysisPeriod, PeriodAnalysis>{};
    final periodsJson = json['periods'] as List<dynamic>? ?? const [];
    for (final entry in periodsJson) {
      final map = entry as Map<String, dynamic>;
      final period = parseAnalysisPeriod((map['period'] as String?) ?? 'MONTH');
      data[period] = PeriodAnalysis.fromJson(map);
    }
    return FinancialAnalysis(periods: data);
  }
}

class PeriodAnalysis {
  final double revenue;
  final double revenueChange;
  final double expense;
  final double expenseChange;
  final List<double> revenueTrend;
  final List<double> expenseTrend;
  final List<CategoryShare> distribution;
  final String insightTitle;
  final String insightBody;
  final List<String> recommendations;

  const PeriodAnalysis({
    required this.revenue,
    required this.revenueChange,
    required this.expense,
    required this.expenseChange,
    required this.revenueTrend,
    required this.expenseTrend,
    required this.distribution,
    required this.insightTitle,
    required this.insightBody,
    required this.recommendations,
  });

  factory PeriodAnalysis.fromJson(Map<String, dynamic> json) {
    return PeriodAnalysis(
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      revenueChange: (json['revenueChange'] as num?)?.toDouble() ?? 0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0,
      expenseChange: (json['expenseChange'] as num?)?.toDouble() ?? 0,
      revenueTrend: _parseList(json['revenueTrend']),
      expenseTrend: _parseList(json['expenseTrend']),
      distribution: (json['distribution'] as List<dynamic>? ?? const [])
          .map((entry) => CategoryShare.fromJson(entry as Map<String, dynamic>))
          .toList(),
      insightTitle: json['insightTitle'] as String? ?? '',
      insightBody: json['insightBody'] as String? ?? '',
      recommendations: (json['recommendations'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  static List<double> _parseList(dynamic raw) {
    final source = raw as List<dynamic>? ?? const [];
    return source.map((value) => (value as num).toDouble()).toList();
  }
}

class CategoryShare {
  final String label;
  final double value;
  final String colorHex;

  const CategoryShare({
    required this.label,
    required this.value,
    required this.colorHex,
  });

  factory CategoryShare.fromJson(Map<String, dynamic> json) {
    return CategoryShare(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      colorHex: json['color'] as String? ?? '#1E88E5',
    );
  }

  Color get color {
    final buffer = StringBuffer();
    var hex = colorHex.replaceFirst('#', '');
    if (hex.length == 6) {
      buffer.write('FF');
    }
    buffer.write(hex);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
