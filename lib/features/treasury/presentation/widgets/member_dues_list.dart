import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/treasury_model.dart';

class MemberDuesList extends StatelessWidget {
  const MemberDuesList(
      {super.key,
      required this.fees,
      required this.currency,
      required this.manage,
      required this.onEdit});
  final List<MembershipFee> fees;
  final String currency;
  final bool manage;
  final ValueChanged<MembershipFee> onEdit;
  @override
  Widget build(BuildContext context) => Column(children: [
        for (final fee in fees)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
                fee.status == 'paid'
                    ? Icons.check_circle_outline
                    : fee.status == 'waived'
                        ? Icons.shield_outlined
                        : Icons.schedule,
                color: fee.status == 'paid'
                    ? AppTheme.mintTeal
                    : AppTheme.textMuted),
            title: Text(fee.name, style: AppTheme.bodyLg),
            subtitle: Text(
                '${fee.status.toUpperCase()} · $currency ${(fee.amountMinor / 100).toStringAsFixed(2)}'),
            onTap: manage ? () => onEdit(fee) : null,
            trailing: fee.status == 'pending' && manage
                ? IconButton(
                    tooltip: 'Copy WhatsApp reminder',
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(
                          text:
                              'Hi ${fee.name.split(' ').first}! A friendly SmashDeck reminder: your ${fee.month} club contribution of $currency ${(fee.amountMinor / 100).toStringAsFixed(2)} is pending. Please share your payment reference with the captain when paid. Thank you for keeping our club playing! 🏸'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Reminder copied. Paste it into WhatsApp.')));
                      }
                    })
                : manage
                    ? const Icon(Icons.chevron_right)
                    : null,
          )
      ]);
}
