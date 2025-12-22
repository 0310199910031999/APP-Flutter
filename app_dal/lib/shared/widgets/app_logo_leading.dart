import 'package:flutter/material.dart';

class AppLogoLeading extends StatelessWidget {
  const AppLogoLeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Image.asset(
        'assets/images/Logo_Icon_White.png',
        width: 32,
        height: 32,
        fit: BoxFit.contain,
      ),
    );
  }
}
