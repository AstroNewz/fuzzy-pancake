import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/court_panel.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/module_widgets.dart';
import '../../../core/widgets/stitch_background.dart';
import '../../../core/services/file_export_service.dart';
import '../../auth/current_user_notifier.dart';
import '../../tournament/models/tournament_model.dart';
import '../../trump_card/trump_card_model.dart';
import '../models/treasury_model.dart';
import '../providers/treasury_state.dart';
import 'widgets/shuttle_stock_card.dart';
import 'widgets/member_dues_list.dart';

class TreasuryDashboardScreen extends ConsumerStatefulWidget {
  const TreasuryDashboardScreen({super.key});
  @override
  ConsumerState<TreasuryDashboardScreen> createState() =>
      _TreasuryDashboardScreenState();
}

class _TreasuryDashboardScreenState
    extends ConsumerState<TreasuryDashboardScreen> {
  int _tab = 0;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String get month => DateFormat('yyyy-MM').format(_month);
  bool get manage => ref.read(currentUserProvider)?.isCaptain ?? false;
  @override
  Widget build(BuildContext context) {
    final value = ref.watch(treasuryProvider),
        store = ref.read(treasuryProvider.notifier);
    return StitchAppBackground(
        child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
                title: const Text('Club treasury'),
                backgroundColor: Colors.transparent),
            body: ListView(padding: const EdgeInsets.all(20), children: [
              Text('KEEP THE CLUB PLAYING',
                  style: AppTheme.labelCaps.copyWith(color: AppTheme.mintTeal)),
              const SizedBox(height: 10),
              Text('Every shuttle counts.', style: AppTheme.headlineXl),
              ModuleSyncBar(store: store),
              Row(children: [
                IconButton(
                    tooltip: 'Previous month',
                    onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1)),
                    icon: const Icon(Icons.chevron_left)),
                Expanded(
                    child: Text(DateFormat('MMMM yyyy').format(_month),
                        textAlign: TextAlign.center,
                        style: AppTheme.headlineMd)),
                IconButton(
                    tooltip: 'Next month',
                    onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1)),
                    icon: const Icon(Icons.chevron_right))
              ]),
              value.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('$e'),
                  data: (data) {
                    final balance = data.balance(month);
                    String money(int amount) =>
                        '${data.currency == 'INR' ? '₹' : '\$'}${(amount / 100).toStringAsFixed(2)}';
                    final use = data.logs
                        .where((l) =>
                            l.type == 'usage' &&
                            l.date.toIso8601String().startsWith(month))
                        .toList();
                    final broken = use.fold<int>(0, (n, l) => n + l.shuttles),
                        matches = use.fold<int>(0, (n, l) => n + l.matches),
                        usageCost =
                            use.fold<int>(0, (n, l) => n + l.amountMinor);
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CourtPanel(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('CLUB BALANCE', style: AppTheme.labelCaps),
                                const SizedBox(height: 8),
                                Text(money(balance.remainingMinor),
                                    style: AppTheme.headlineXl
                                        .copyWith(color: AppTheme.limeNeon)),
                                const SizedBox(height: 16),
                                Wrap(spacing: 24, runSpacing: 12, children: [
                                  for (final item in [
                                    ('COLLECTED', balance.collectedMinor),
                                    ('SPENT', balance.spentMinor),
                                    ('CARRIED FORWARD', balance.openingMinor)
                                  ])
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item.$1,
                                              style: AppTheme.labelCaps
                                                  .copyWith(
                                                      fontSize: 8,
                                                      color:
                                                          AppTheme.textMuted)),
                                          const SizedBox(height: 4),
                                          Text(money(item.$2),
                                              style: AppTheme.bodyLg)
                                        ])
                                ]),
                              ])),
                          const SizedBox(height: 20),
                          GlassTabs(
                              labels: const [
                                'Shuttle stock',
                                'Member dues',
                                'Ledger'
                              ],
                              selected: _tab,
                              onSelected: (i) => setState(() => _tab = i)),
                          const SizedBox(height: 18),
                          if (_tab == 0) ...[
                            Text(
                                '$broken shuttles used · ${matches == 0 ? 'No match usage logged' : '${(broken / matches).toStringAsFixed(2)} per logged match'}',
                                style: AppTheme.bodyMd),
                            Text(
                                'Usage value ${money(usageCost)} · ${use.isEmpty ? '0 sessions' : '${money((usageCost / use.length).round())} per logged session'}',
                                style: AppTheme.bodySm
                                    .copyWith(color: AppTheme.textMuted)),
                            if (manage)
                              TextButton.icon(
                                  onPressed: () => _form(
                                      'Add shuttle stock',
                                      {
                                        'Brand': 'Yonex',
                                        'Model': 'Aerosensa 30',
                                        'Full tubes': '1',
                                        'Cost per tube': '',
                                        'Shuttles per tube': '12'
                                      },
                                      (v) => store.purchase(
                                          v['Brand']!,
                                          v['Model']!,
                                          int.tryParse(v['Full tubes']!) ?? 0,
                                          parseMoney(v['Cost per tube']!),
                                          int.tryParse(
                                                  v['Shuttles per tube']!) ??
                                              0)),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Record purchase')),
                            if (data.stocks.isEmpty)
                              const Padding(
                                  padding: EdgeInsets.all(30),
                                  child: Text(
                                      'Add your first shuttle purchase to start tracking stock.',
                                      textAlign: TextAlign.center)),
                            for (final stock in data.stocks)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: ShuttleStockCard(
                                      stock: stock,
                                      manage: manage,
                                      onOpen: () => runClubAction(context,
                                          () => store.openTube(stock.id)),
                                      onLog: () => _form(
                                          'Log practice consumption',
                                          {
                                            'Shuttles used': '1',
                                            'Matches played': '1'
                                          },
                                          (v) => store.consume(
                                              stock.id,
                                              int.tryParse(
                                                      v['Shuttles used']!) ??
                                                  0,
                                              int.tryParse(
                                                      v['Matches played']!) ??
                                                  0)))),
                          ],
                          if (_tab == 1) ...[
                            if (manage)
                              TextButton.icon(
                                  onPressed: () =>
                                      _form('Create monthly dues', {
                                        'Fee per member':
                                            (data.monthlyFeeMinor / 100)
                                                .toStringAsFixed(2),
                                        'Currency (INR / USD)': data.currency
                                      }, (v) async {
                                        final players = await ref.read(
                                            squadTrumpCardsProvider.future);
                                        if (players.isEmpty) {
                                          throw StateError(
                                              'No members are available.');
                                        }
                                        await store.createDues(
                                            month,
                                            players
                                                .map(ClubPlayer.fromCard)
                                                .toList(),
                                            parseMoney(v['Fee per member']!),
                                            v['Currency (INR / USD)']!
                                                .trim()
                                                .toUpperCase());
                                      }),
                                  icon: const Icon(Icons.person_add_alt),
                                  label: const Text('Prepare member dues')),
                            if (!data.fees.any((f) => f.month == month))
                              const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                      'No dues have been prepared for this month.')),
                            MemberDuesList(
                                fees: data.fees
                                    .where((f) => f.month == month)
                                    .toList(),
                                currency: data.currency,
                                manage: manage,
                                onEdit: (fee) => showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    builder: (_) => _PaymentSheet(
                                        fee: fee,
                                        onSave: (status, mode, note, date) =>
                                            store.payment(fee.playerId, month,
                                                status, mode, note, date)))),
                          ],
                          if (_tab == 2) ...[
                            if (manage)
                              TextButton.icon(
                                  onPressed: () => _form(
                                      'Record club expense',
                                      {
                                        'Description': 'Court booking',
                                        'Amount': ''
                                      },
                                      (v) => store.expense(v['Description']!,
                                          parseMoney(v['Amount']!))),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add expense')),
                            for (final log in data.logs.reversed.where((l) =>
                                l.date.toIso8601String().startsWith(month)))
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(log.note),
                                  subtitle: Text(
                                      '${log.type.toUpperCase()} · ${DateFormat('d MMM, h:mm a').format(log.date)}'),
                                  trailing: log.amountMinor > 0
                                      ? Text(money(log.amountMinor),
                                          style: AppTheme.bodySm)
                                      : null),
                          ],
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                              onPressed: () => runClubAction(
                                  context,
                                  () => FileExportService.share(
                                      Uint8List.fromList(
                                          utf8.encode(data.csv(month))),
                                      'SmashDeck-$month.csv',
                                      'text/csv')),
                              icon: const Icon(Icons.ios_share),
                              label: const Text('EXPORT MONTHLY CSV')),
                        ]);
                  }),
            ])));
  }

  Future<void> _form(String title, Map<String, String> initial,
          Future<void> Function(Map<String, String>) onSave) =>
      showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) =>
              _TreasuryForm(title: title, initial: initial, onSave: onSave));
}

class _TreasuryForm extends StatefulWidget {
  const _TreasuryForm(
      {required this.title, required this.initial, required this.onSave});
  final String title;
  final Map<String, String> initial;
  final Future<void> Function(Map<String, String>) onSave;
  @override
  State<_TreasuryForm> createState() => _TreasuryFormState();
}

class _TreasuryFormState extends State<_TreasuryForm> {
  late final fields = {
    for (final e in widget.initial.entries)
      e.key: TextEditingController(text: e.value)
  };
  bool saving = false;
  String? error;
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: AppTheme.headlineLg),
            const SizedBox(height: 20),
            for (final e in fields.entries)
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                      controller: e.value,
                      decoration: InputDecoration(labelText: e.key))),
            if (error != null)
              Text(error!, style: const TextStyle(color: AppTheme.errorRed)),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setState(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          await widget.onSave({
                            for (final e in fields.entries) e.key: e.value.text
                          });
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (mounted) setState(() => error = e.toString());
                        } finally {
                          if (mounted) setState(() => saving = false);
                        }
                      },
                child: Text(saving ? 'SAVING…' : 'SAVE RECORD')),
          ]));
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.fee, required this.onSave});
  final MembershipFee fee;
  final Future<void> Function(String, String, String, DateTime) onSave;
  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  late String status = widget.fee.status, mode = widget.fee.mode;
  late DateTime date = widget.fee.paidAt ?? DateTime.now();
  late final note = TextEditingController(text: widget.fee.reference);
  bool saving = false;
  String? error;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.fee.name, style: AppTheme.headlineLg),
            const SizedBox(height: 16),
            Wrap(spacing: 8, children: [
              for (final s in ['paid', 'pending', 'waived'])
                ChoiceChip(
                    label: Text(s.toUpperCase()),
                    selected: status == s,
                    onSelected: (_) => setState(() => status = s))
            ]),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
                initialValue: mode,
                items: ['UPI', 'Cash', 'Bank transfer']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => mode = v!)),
            TextButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now());
                  if (d != null) setState(() => date = d);
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat('d MMM yyyy').format(date))),
            TextField(
                controller: note,
                maxLength: 180,
                decoration: const InputDecoration(
                    labelText: 'Payment reference / waiver note')),
            if (error != null)
              Text(error!, style: const TextStyle(color: AppTheme.errorRed)),
            FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setState(() => saving = true);
                        try {
                          await widget.onSave(status, mode, note.text, date);
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (mounted) setState(() => error = e.toString());
                        } finally {
                          if (mounted) setState(() => saving = false);
                        }
                      },
                child: const Text('SAVE PAYMENT STATUS')),
          ]));
}
