// lib/data/models/balance_sheet.dart

class BalanceSheet {
  final double totalAssets;      // 총자산
  final double totalLiabilities; // 총부채
  final double totalEquity;      // 총자본

  const BalanceSheet({
    this.totalAssets = 0,
    this.totalLiabilities = 0,
    this.totalEquity = 0,
  });
}
