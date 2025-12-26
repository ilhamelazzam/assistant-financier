import 'package:coaching_financier/models/budget_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Budget models', () {
    test('parseBudgetPeriodType retourne la bonne enum', () {
      expect(parseBudgetPeriodType('WEEKLY'), BudgetPeriodType.weekly);
      expect(parseBudgetPeriodType('custom'), BudgetPeriodType.custom);
      expect(parseBudgetPeriodType(null), BudgetPeriodType.monthly);
      expect(parseBudgetPeriodType('other'), BudgetPeriodType.monthly);
    });

    test('BudgetTip expose isWarning si le ton contient warn', () {
      const tip = BudgetTip(tone: 'warning', message: 'Attention', category: 'budget');
      expect(tip.isWarning, isTrue);
      final info = BudgetTip.fromJson({'tone': 'info', 'message': 'ok', 'category': 'general'});
      expect(info.isWarning, isFalse);
    });

    test('BudgetCategory calcule percent et parsing JSON', () {
      final category = BudgetCategory.fromJson({
        'category': 'Logement',
        'budgetAmount': 1000,
        'spentAmount': 400,
        'remaining': 600,
        'usage': 0.4,
        'periodType': 'MONTHLY',
        'periodMonth': 12,
        'periodYear': 2025,
        'periodLabel': 'Décembre 2025',
        'alertThreshold': 80,
      });

      expect(category.category, 'Logement');
      expect(category.percent, closeTo(0.4, 1e-6));
      expect(category.periodType, BudgetPeriodType.monthly);
      expect(category.alertThreshold, 80);
    });

    test('BudgetSnapshot agrège les catégories et conseils', () {
      final snapshot = BudgetSnapshot.fromJson({
        'month': 1,
        'year': 2025,
        'totalBudget': 2000,
        'totalSpent': 500,
        'remaining': 1500,
        'categories': [
          {
            'category': 'Courses',
            'budgetAmount': 500,
            'spentAmount': 200,
            'remaining': 300,
            'usage': 0.4,
            'periodType': 'WEEKLY',
            'periodMonth': 1,
            'periodYear': 2025,
            'periodLabel': 'Semaine 1',
          }
        ],
        'advice': {'tone': 'info', 'message': 'Continuez ainsi', 'category': 'general'}
      });

      expect(snapshot.categories, hasLength(1));
      expect(snapshot.categories.first.periodType, BudgetPeriodType.weekly);
      expect(snapshot.advice?.message, 'Continuez ainsi');
      expect(snapshot.usage, closeTo(0.25, 1e-6));
    });
  });
}
