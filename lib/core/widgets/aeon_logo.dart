import 'package:flutter/material.dart';

/// Production AEON Acrylic Brand Mark.
///
/// Implements the physical acrylic solid aesthetic in the Noguchi / Cyber-Slate
/// luxury palette:
/// - Smoked obsidian / deep slate translucent core matching AppColors.onyx (#0F131B)
/// - Frosted platinum letterforms with pure white specular catch-lights
/// - Refined diamond glass bevel reflections without loud, toy-like blue saturation
///
/// Designed to render crisply at any size from compact 28dp app bar badges
/// to prominent 140dp onboarding / login displays.
class AeonLogo extends StatelessWidget {
  const AeonLogo({
    super.key,
    this.size = 96.0,
    this.showGlow = true,
    this.heroTag,
    this.semanticLabel = 'AEON logo',
  });

  /// Size of the square bounding box in logical pixels.
  final double size;

  /// Whether to render the ambient specular reflection glow.
  final bool showGlow;

  /// Optional Hero tag for seamless screen transitions.
  final String? heroTag;

  /// Semantic accessibility description.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget content = Semantics(
      label: semanticLabel,
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.22),
          boxShadow: showGlow
              ? [
                  // Soft platinum / diamond specular reflection
                  BoxShadow(
                    color: const Color(0xFFB8BCC3).withValues(alpha: 0.16),
                    blurRadius: size * 0.35,
                    spreadRadius: size * 0.01,
                  ),
                  // Faint cool steel rim dispersal hint
                  BoxShadow(
                    color: const Color(0xFF64748B).withValues(alpha: 0.10),
                    blurRadius: size * 0.20,
                  ),
                  // Deep obsidian contact shadow for surface separation
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: size * 0.25,
                    offset: Offset(0, size * 0.08),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: Image.asset(
            'assets/images/aeon_logo_static.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/aeon_master.png',
                width: size,
                height: size,
                fit: BoxFit.contain,
              );
            },
          ),
        ),
      ),
    );

    if (heroTag != null) {
      content = Hero(
        tag: heroTag!,
        child: content,
      );
    }

    return content;
  }
}
