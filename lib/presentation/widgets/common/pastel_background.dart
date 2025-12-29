/// Pastel Background Widget
/// 
/// DACN-style pastel purple gradient background with optional geometric decorations.
/// Used as scaffold background across all Employee screens.

import 'package:flutter/material.dart';

class PastelBackground extends StatelessWidget {
  final Widget child;
  final bool showDecorations;

  const PastelBackground({
    super.key,
    required this.child,
    this.showDecorations = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5F0FF), // Very light purple-white
            Color(0xFFE8DAEF), // Light lavender
            Color(0xFFD7BDE2), // Pastel purple
            Color(0xFFD4E6F1), // Light blue-purple
            Color(0xFFAED6F1), // Pastel blue
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
      child: showDecorations
          ? Stack(
              children: [
                // Geometric decoration - top right
                Positioned(
                  top: 80,
                  right: -40,
                  child: Transform.rotate(
                    angle: 0.5,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF8E44AD).withValues(alpha: 0.08),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                // Geometric decoration - bottom left
                Positioned(
                  bottom: 200,
                  left: -60,
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF8E44AD).withValues(alpha: 0.06),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                // Main content
                child,
              ],
            )
          : child,
    );
  }
}

/// Scaffold with Pastel Background
class PastelScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showDecorations;

  const PastelScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showDecorations = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: PastelBackground(
        showDecorations: showDecorations,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
