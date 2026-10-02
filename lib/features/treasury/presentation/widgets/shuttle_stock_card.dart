import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../models/treasury_model.dart';

class ShuttleStockCard extends StatelessWidget {
  const ShuttleStockCard(
      {super.key,
      required this.stock,
      required this.manage,
      required this.onOpen,
      required this.onLog});
  final ShuttleStock stock;
  final bool manage;
  final VoidCallback onOpen, onLog;
  @override
  Widget build(BuildContext context) => GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${stock.brand} ${stock.model}', style: AppTheme.headlineMd),
        const SizedBox(height: 16),
        Wrap(spacing: 24, runSpacing: 12, children: [
          for (final value in [
            ('FULL TUBES', stock.fullTubes),
            ('OPEN TUBES', stock.openTubes),
            ('LOOSE', stock.loose),
            ('TOTAL', stock.remaining)
          ])
            Column(children: [
              Text('${value.$2}',
                  style:
                      AppTheme.headlineLg.copyWith(color: AppTheme.limeNeon)),
              Text(value.$1, style: AppTheme.labelCaps.copyWith(fontSize: 8))
            ])
        ]),
        if (manage) ...[
          const SizedBox(height: 16),
          Wrap(spacing: 10, children: [
            OutlinedButton.icon(
                onPressed: stock.fullTubes > 0 ? onOpen : null,
                icon: const Icon(Icons.add_box_outlined, size: 16),
                label: const Text('Open a tube')),
            TextButton(
                onPressed: stock.loose > 0 ? onLog : null,
                child: const Text('Log session use'))
          ])
        ],
      ]));
}
