// lib/core/enums.dart

enum AccountType {
  asset, // 자산
  liability, // 부채
  equity, // 자본
  revenue, // 수익
  expense // 비용
}

enum EntryType {
  debit, // 차변
  credit // 대변
}

// 거래 기록 화면의 유형을 나타내는 Enum 추가
enum EntryScreenType {
  expense, // 지출
  income, // 수입
  transfer, // 이체
}

// 반복 주기를 나타내는 Enum 추가
enum Frequency {
  daily,
  weekly,
  monthly,
  yearly,
}