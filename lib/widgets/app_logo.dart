import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Reusable app logo widget with customizable size and glow effect
class AppLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showGlow = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: showShadow
            ? [
                if (showGlow)
                  BoxShadow(
                    color: AppColors.accentGreen.withValues(alpha: 0.4),
                    blurRadius: size * 0.2,
                    spreadRadius: size * 0.02,
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: size * 0.1,
                  offset: Offset(0, size * 0.04),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/Shuttle_Smashers_Logo_Optimized.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to a text-based logo if image fails to load
            return _buildFallbackLogo();
          },
        ),
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accentGreen,
          width: size * 0.03,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_tennis,
              color: AppColors.accentGreen,
              size: size * 0.35,
            ),
            SizedBox(height: size * 0.02),
            Text(
              'SS',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.2,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated logo widget with pulsing glow effect
class AnimatedAppLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const AnimatedAppLogo({
    super.key,
    this.size = 100,
    this.animate = true,
  });

  @override
  State<AnimatedAppLogo> createState() => _AnimatedAppLogoState();
}

class _AnimatedAppLogoState extends State<AnimatedAppLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGreen.withValues(alpha: _glowAnimation.value),
                blurRadius: widget.size * 0.25,
                spreadRadius: widget.size * 0.05,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/Shuttle_Smashers_Logo_Optimized.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackLogo();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accentGreen,
          width: widget.size * 0.03,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_tennis,
          color: AppColors.accentGreen,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}
