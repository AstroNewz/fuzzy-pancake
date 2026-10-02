import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Head-to-Head Rivalry Screen
/// Shows an empty state until players sign up and matches are recorded.
class HeadToHeadScreen extends StatelessWidget {
  const HeadToHeadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'H2H Rivalry Matrix',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline,
                  size: 64, color: AppTheme.primaryBright),
              SizedBox(height: 16),
              Text(
                'No Match Data Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textWhite,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Head-to-head stats will appear here once\nclub members have signed up and played matches.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textMuted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
