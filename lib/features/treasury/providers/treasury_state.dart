import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/club_module_store.dart';
import '../../../core/network/supabase_service.dart';
import '../../tournament/models/tournament_model.dart';
import '../models/treasury_model.dart';

class TreasuryNotifier extends ClubModuleStore<TreasuryData> {
  TreasuryNotifier(SupabaseClient client)
      : super(client, 'treasury', () => TreasuryData());
  @override
  TreasuryData decode(Map<String, dynamic> json) =>
      json.isEmpty ? TreasuryData() : TreasuryData.fromJson(json);
  @override
  Map<String, dynamic> encode(TreasuryData data) => data.toJson();
  Future<void> createDues(
          String month, List<ClubPlayer> players, int fee, String currency) =>
      change((d) {
        if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(month) ||
            fee <= 0 ||
            !['INR', 'USD'].contains(currency)) {
          throw ArgumentError('Check month, fee and currency.');
        }
        if (d.currency != currency &&
            (d.logs.isNotEmpty || d.fees.isNotEmpty)) {
          throw StateError(
              'A ledger cannot mix currencies. Keep the existing currency.');
        }
        d.currency = currency;
        d.monthlyFeeMinor = fee;
        for (final player in players) {
          if (!d.fees.any((f) => f.playerId == player.id && f.month == month)) {
            d.fees.add(MembershipFee(
                playerId: player.id,
                name: player.name,
                month: month,
                amountMinor: fee));
          }
        }
      });
  Future<void> payment(String playerId, String month, String status,
          String mode, String reference, DateTime date) =>
      change((d) {
        if (!['paid', 'pending', 'waived'].contains(status) ||
            !['UPI', 'Cash', 'Bank transfer'].contains(mode) ||
            date.isAfter(DateTime.now())) {
          throw ArgumentError('Check payment status, mode and date.');
        }
        final fee = d.fees
            .firstWhere((f) => f.playerId == playerId && f.month == month);
        final old = fee.status;
        fee.status = status;
        fee.mode = mode;
        fee.reference = reference.trim();
        fee.paidAt = status == 'paid' ? date : null;
        d.logs.add(InventoryLog(
            id: const Uuid().v4(),
            type: 'dues_audit',
            date: DateTime.now(),
            note: '${fee.name}: $old → $status for $month · ${fee.reference}'));
      });
  Future<void> purchase(
          String brand, String model, int tubes, int cost, int perTube) =>
      change((d) {
        if (brand.trim().isEmpty ||
            model.trim().isEmpty ||
            tubes < 1 ||
            tubes > 1000 ||
            cost <= 0 ||
            perTube < 1 ||
            perTube > 100) {
          throw ArgumentError(
              'Enter brand, model, tube count, tube cost and capacity.');
        }
        final stock = ShuttleStock(
            id: const Uuid().v4(),
            brand: brand.trim(),
            model: model.trim(),
            tubeCostMinor: cost,
            perTube: perTube,
            fullTubes: tubes);
        d.stocks.add(stock);
        d.logs.add(InventoryLog(
            id: const Uuid().v4(),
            type: 'purchase',
            date: DateTime.now(),
            note: '$tubes × $brand $model',
            stockId: stock.id,
            amountMinor: tubes * cost));
      });
  Future<void> openTube(String id) => change((d) {
        final stock = d.stocks.firstWhere((s) => s.id == id);
        if (stock.fullTubes < 1) throw StateError('No full tubes remain.');
        stock.fullTubes--;
        stock.loose += stock.perTube;
        d.logs.add(InventoryLog(
            id: const Uuid().v4(),
            type: 'open',
            date: DateTime.now(),
            note: 'Opened ${stock.brand} ${stock.model}',
            stockId: id));
      });
  Future<void> consume(String id, int shuttles, int matches) => change((d) {
        final stock = d.stocks.firstWhere((s) => s.id == id);
        if (shuttles < 1 ||
            shuttles > stock.loose ||
            matches < 1 ||
            matches > 1000) {
          throw ArgumentError(
              'Enter available loose shuttles and at least one match.');
        }
        stock.loose -= shuttles;
        d.logs.add(InventoryLog(
            id: const Uuid().v4(),
            type: 'usage',
            date: DateTime.now(),
            note: 'Practice · ${stock.model}',
            stockId: id,
            shuttles: shuttles,
            matches: matches,
            amountMinor:
                (stock.tubeCostMinor * shuttles / stock.perTube).round()));
      });
  Future<void> expense(String note, int amount) => change((d) {
        if (note.trim().isEmpty || amount <= 0) {
          throw ArgumentError('Enter a description and positive amount.');
        }
        d.logs.add(InventoryLog(
            id: const Uuid().v4(),
            type: 'expense',
            date: DateTime.now(),
            note: note.trim(),
            amountMinor: amount));
      });
}

final treasuryProvider =
    StateNotifierProvider<TreasuryNotifier, AsyncValue<TreasuryData>>(
        (ref) => TreasuryNotifier(ref.watch(supabaseClientProvider)));
