// lib/data/models/income_statement.dart

class IncomeStatement {
  final double totalRevenue;  // 총수익
  final double totalExpenses; // 총비용

  // 순이익 계산
  double get netIncome => totalRevenue - totalExpenses;

  const IncomeStatement({
    this.totalRevenue = 0,
    this.totalExpenses = 0,
  });
}
