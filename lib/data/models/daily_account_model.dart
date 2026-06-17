class DailyAccountModel {
  final int? id;
  final String date; // YYYY-MM-DD, unique
  final double openingBalance;
  final double? closingBalance;
  final bool isDayClosed;

  DailyAccountModel({
    this.id,
    required this.date,
    required this.openingBalance,
    this.closingBalance,
    this.isDayClosed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'opening_balance': openingBalance,
      'closing_balance': closingBalance,
      'is_day_closed': isDayClosed ? 1 : 0,
    };
  }

  factory DailyAccountModel.fromMap(Map<String, dynamic> map) {
    return DailyAccountModel(
      id: map['id'],
      date: map['date'],
      openingBalance: (map['opening_balance'] as num).toDouble(),
      closingBalance: map['closing_balance'] != null
          ? (map['closing_balance'] as num).toDouble()
          : null,
      isDayClosed: map['is_day_closed'] == 1,
    );
  }

  DailyAccountModel copyWith({
    int? id,
    String? date,
    double? openingBalance,
    double? closingBalance,
    bool? isDayClosed,
  }) {
    return DailyAccountModel(
      id: id ?? this.id,
      date: date ?? this.date,
      openingBalance: openingBalance ?? this.openingBalance,
      closingBalance: closingBalance ?? this.closingBalance,
      isDayClosed: isDayClosed ?? this.isDayClosed,
    );
  }
}
