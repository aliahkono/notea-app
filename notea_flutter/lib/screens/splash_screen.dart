import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'home_screen.dart';

/// Port of ContentView + SplashScreenController.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int currentFrame = 0;
  double logoScale = 0.7;
  double logoOpacity = 0;
  double backgroundOpacity = 0;
  double secondLogoOpacity = 0;
  double secondLogoScale = 0.8;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  void _after(int ms, VoidCallback fn) {
    _timers.add(Timer(Duration(milliseconds: ms), () {
      if (mounted) fn();
    }));
  }

  void _startAnimationSequence() {
    _after(500, () {
      setState(() {
        logoOpacity = 1;
        logoScale = 1;
      });
      _after(1500, () {
        setState(() {
          currentFrame = 1;
          logoOpacity = 0;
          backgroundOpacity = 0.5;
        });
        _after(1000, () {
          setState(() {
            currentFrame = 2;
            secondLogoOpacity = 1;
            secondLogoScale = 1;
          });
          _after(1500, () {
            Navigator.of(context).pushReplacement(PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            ));
          });
        });
      });
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  Widget _logo(String asset, double scale, double opacity) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(seconds: 1),
      curve: Curves.easeIn,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(seconds: 1),
        curve: Curves.easeIn,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Image.asset(asset, width: 160, height: 160, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      // SizedBox.expand makes the Stack fill the whole screen, so the logos
      // are centred instead of sitting in the top-left corner.
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (currentFrame >= 1)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: backgroundOpacity,
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOut,
                  child: ImageFiltered(
                    // This is where dart:ui is used (blurred logo glow).
                    imageFilter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: Transform.scale(
                      scale: 1.2,
                      child: OverflowBox(
                        maxWidth: size.width * 2,
                        maxHeight: size.height * 2,
                        child: Image.asset('assets/images/notea_logo.png',
                            width: size.width * 2, height: size.height * 2, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ),
            if (currentFrame == 0 || currentFrame == 1)
              _logo('assets/images/notea_logo.png', logoScale, logoOpacity),
            // Mounted from frame 1 (invisible) so the fade/scale-in animates.
            if (currentFrame >= 1)
              _logo('assets/images/notea_logo2.png', secondLogoScale, secondLogoOpacity),
          ],
        ),
      ),
    );
  }
}