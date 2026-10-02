class ShuttleStock {
  ShuttleStock(
      {required this.id,
      required this.brand,
      required this.model,
      required this.tubeCostMinor,
      this.perTube = 12,
      this.fullTubes = 0,
      this.loose = 0});
  final String id, brand, model;
  final int tubeCostMinor, perTube;
  int fullTubes, loose;
  int get openTubes => (loose / perTube).ceil();
  int get remaining => fullTubes * perTube + loose;
  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'tubeCostMinor': tubeCostMinor,
        'perTube': perTube,
        'fullTubes': fullTubes,
        'loose': loose
      };
  factory ShuttleStock.fromJson(Map<String, dynamic> j) => ShuttleStock(
      id: j['id'],
      brand: j['brand'],
      model: j['model'],
      tubeCostMinor: j['tubeCostMinor'],
      perTube: j['perTube'],
      fullTubes: j['fullTubes'],
      loose: j['loose']);
}

class InventoryLog {
  InventoryLog(
      {required this.id,
      required this.type,
      required this.date,
      required this.note,
      this.stockId,
      this.amountMinor = 0,
      this.shuttles = 0,
      this.matches = 0});
  final String id, type, note;
  final String? stockId;
  final DateTime date;
  final int amountMinor, shuttles, matches;
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'date': date.toIso8601String(),
        'note': note,
        'stockId': stockId,
        'amountMinor': amountMinor,
        'shuttles': shuttles,
        'matches': matches
      };
  factory InventoryLog.fromJson(Map<String, dynamic> j) => InventoryLog(
      id: j['id'],
      type: j['type'],
      date: DateTime.parse(j['date']),
      note: j['note'],
      stockId: j['stockId'],
      amountMinor: j['amountMinor'],
      shuttles: j['shuttles'],
      matches: j['matches']);
}

class MembershipFee {
  MembershipFee(
      {required this.playerId,
      required this.name,
      required this.month,
      required this.amountMinor,
      this.status = 'pending',
      this.paidAt,
      this.mode = 'UPI',
      this.reference = ''});
  final String playerId, name, month;
  final int amountMinor;
  String status, mode, reference;
  DateTime? paidAt;
  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'name': name,
        'month': month,
        'amountMinor': amountMinor,
        'status': status,
        'paidAt': paidAt?.toIso8601String(),
        'mode': mode,
        'reference': reference
      };
  factory MembershipFee.fromJson(Map<String, dynamic> j) => MembershipFee(
      playerId: j['playerId'],
      name: j['name'],
      month: j['month'],
      amountMinor: j['amountMinor'],
      status: j['status'],
      paidAt: j['paidAt'] == null ? null : DateTime.parse(j['paidAt']),
      mode: j['mode'],
      reference: j['reference']);
}

class MonthlyBalance {
  const MonthlyBalance(
      {required this.collectedMinor,
      required this.spentMinor,
      required this.openingMinor});
  final int collectedMinor, spentMinor, openingMinor;
  int get remainingMinor => openingMinor + collectedMinor - spentMinor;
}

class TreasuryData {
  TreasuryData(
      {this.currency = 'INR',
      this.monthlyFeeMinor = 50000,
      List<ShuttleStock>? stocks,
      List<MembershipFee>? fees,
      List<InventoryLog>? logs})
      : stocks = stocks ?? [],
        fees = fees ?? [],
        logs = logs ?? [];
  String currency;
  int monthlyFeeMinor;
  final List<ShuttleStock> stocks;
  final List<MembershipFee> fees;
  final List<InventoryLog> logs;
  MonthlyBalance balance(String month) {
    int collected = 0, spent = 0, opening = 0;
    for (final fee
        in fees.where((f) => f.status == 'paid' && f.paidAt != null)) {
      final paidMonth = fee.paidAt!.toIso8601String().substring(0, 7);
      if (paidMonth == month) collected += fee.amountMinor;
      if (paidMonth.compareTo(month) < 0) opening += fee.amountMinor;
    }
    for (final log
        in logs.where((l) => l.type == 'purchase' || l.type == 'expense')) {
      final logMonth = log.date.toIso8601String().substring(0, 7);
      if (logMonth == month) spent += log.amountMinor;
      if (logMonth.compareTo(month) < 0) opening -= log.amountMinor;
    }
    return MonthlyBalance(
        collectedMinor: collected, spentMinor: spent, openingMinor: opening);
  }

  String csv(String month) {
    String cell(Object? value) {
      var text = value?.toString() ?? '';
      if (RegExp(r'^[=+@\-\t\r]').hasMatch(text)) text = "'$text";
      return '"${text.replaceAll('"', '""')}"';
    }

    final rows = <List<Object?>>[
      ['SmashDeck monthly report', month, currency],
      [
        'Type',
        'Member / item',
        'Status / category',
        'Amount',
        'Date',
        'Mode',
        'Reference'
      ],
      for (final fee in fees.where((f) => f.month == month))
        [
          'Dues',
          fee.name,
          fee.status,
          (fee.amountMinor / 100).toStringAsFixed(2),
          fee.paidAt?.toIso8601String() ?? '',
          fee.mode,
          fee.reference
        ],
      for (final log
          in logs.where((l) => l.date.toIso8601String().startsWith(month)))
        [
          'Inventory / expense',
          log.note,
          log.type,
          (log.amountMinor / 100).toStringAsFixed(2),
          log.date.toIso8601String(),
          '',
          log.shuttles
        ],
      [
        'Opening balance',
        (balance(month).openingMinor / 100).toStringAsFixed(2)
      ],
      ['Collected', (balance(month).collectedMinor / 100).toStringAsFixed(2)],
      ['Spent', (balance(month).spentMinor / 100).toStringAsFixed(2)],
      ['Remaining', (balance(month).remainingMinor / 100).toStringAsFixed(2)],
    ];
    return rows.map((r) => r.map(cell).join(',')).join('\r\n');
  }

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'monthlyFeeMinor': monthlyFeeMinor,
        'stocks': stocks.map((s) => s.toJson()).toList(),
        'fees': fees.map((f) => f.toJson()).toList(),
        'logs': logs.map((l) => l.toJson()).toList()
      };
  factory TreasuryData.fromJson(Map<String, dynamic> j) => TreasuryData(
      currency: j['currency'],
      monthlyFeeMinor: j['monthlyFeeMinor'],
      stocks: (j['stocks'] as List)
          .map((s) => ShuttleStock.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      fees: (j['fees'] as List)
          .map((f) => MembershipFee.fromJson(Map<String, dynamic>.from(f)))
          .toList(),
      logs: (j['logs'] as List)
          .map((l) => InventoryLog.fromJson(Map<String, dynamic>.from(l)))
          .toList());
}

int parseMoney(String text) {
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text.trim())) {
    throw ArgumentError(
        'Enter a positive amount with up to two decimal places.');
  }
  final parts = text.trim().split('.');
  final amount = int.parse(parts[0]) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  if (amount <= 0 || amount > 100000000) {
    throw ArgumentError('Amount is out of range.');
  }
  return amount;
}
