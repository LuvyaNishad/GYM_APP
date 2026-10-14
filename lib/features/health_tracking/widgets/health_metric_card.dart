import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// An individual health metric display card for the Health Tracking screen.
///
/// Uses glassmorphism styling consistent with LEON's design system.
class HealthMetricCard extends StatelessWidget {
  const HealthMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accentColor,
  });

  final String label;

  /// The metric value to display — pass `'--'` when data is unavailable.
  final String value;

  final String unit;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Icon(icon,
                      size: 14, color: accentColor.withValues(alpha: 0.7)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
