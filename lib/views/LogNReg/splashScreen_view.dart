import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<Offset> _waveSlideAnimation;
  late Animation<Offset> _banyuSlideAnimation; 
  late Animation<double> _banyuFadeAnimation;
  late Animation<double> _amertaFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Total duration of 5 seconds
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    // --- THE TWEEN SEQUENCE FOR THE WAVE ---
    _waveSlideAnimation = TweenSequence<Offset>([
      // 1. Slide up halfway (Takes 20% of the time)
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -0.35))
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 20.0,
      ),

      // 2. Slide slightly more (Takes 20% of the time)
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0,-0.35), end: const Offset(0, -0.425))
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 20.0,
      ),
      // 3. Pause exactly where it is (Takes 10% of the time: 40% to 50%)
      TweenSequenceItem(
        tween: ConstantTween<Offset>(const Offset(0, -0.425)),
        weight: 10.0,
      ),
      // 4. Slide up the rest of the way to clear the screen (Takes 30% of the time: 50% to 80%)
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, -0.425), end: const Offset(0, -1.2))
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 30.0,
      ),
      // 5. Stay hidden at the top (Takes 20% of the time: 80% to 100%)
      TweenSequenceItem(
        tween: ConstantTween<Offset>(const Offset(0, -1.2)),
        weight: 20.0,
      ),
    ]).animate(_controller);

    // --- THE BANYU SLIDE ---
    // Now synchronized EXACTLY with the wave's final upward sweep (0.50 to 0.80)
    // using the exact same easeInCubic curve.
    _banyuSlideAnimation = Tween<Offset>(
      begin: Offset(0,-1),
      end: Offset.zero
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.40, curve: Curves.easeInOutCubic),
    ));

    // --- THE DROPLET CROSSFADE ---
    _banyuFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    ));

    _amertaFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
    ));

    // Start animation and navigate to Role Selector ('/') when done
    _controller.forward().whenComplete(() {
      Navigator.pushReplacementNamed(context, '/');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF729AC4),
              Color(0xFF031B46),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- BOTTOM LAYER: White Droplet and AMERTA Text ---
            FadeTransition(
              opacity: _amertaFadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/Vector.png', 
                    height: 160,
                    width: 160,
                    fit: BoxFit.contain,
                    color: Colors.white,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.water_drop,
                      color: Colors.white,
                      size: 120,
                    ),
                  ),
                  const SizedBox(height: 16)
                ],
              ),
            ),

            // --- MIDDLE LAYER: Blue Droplet (banyu.png) ---
            SlideTransition(
              position: _banyuSlideAnimation,
              child: FadeTransition(
                opacity: _banyuFadeAnimation,
                child: Image.asset(
                  'assets/banyu.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.water_drop,
                      color: Color(0xFF729AC4),
                      size: 120,
                    );
                  },
                ),
              ),
            ),

            // --- TOP LAYER: The Wave (ombak1.png or ombak.png) ---
            Positioned(
              bottom: -150, // Starts below the screen
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 1.5,              
              child: SlideTransition(
                position: _waveSlideAnimation,
                child: Image.asset(
                  'assets/ombak.png', // Ensure this matches your file name
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}