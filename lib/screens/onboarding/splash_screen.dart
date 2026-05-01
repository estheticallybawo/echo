import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  
    precacheImage(const AssetImage('assets/splash/echosplashicon.png'), context);
    precacheImage(const AssetImage('assets/onboarding/Echosoundwave.png'), context);
  }

  @override
  void initState() {
    super.initState();
    
   
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          
          gradient: RadialGradient(
            center: Alignment(0.0, 0.0),
            radius: 1.2,
            colors: [
              Color(0xFF0F3169), 
              Color(0xFF02091A), 
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/splash/echosplashicon.png',
            width: 200, 
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
