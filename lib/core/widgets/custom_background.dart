import 'package:flutter/material.dart';

class CustomBackground extends StatelessWidget {
  final Widget child;
  final String imagePath;

  const CustomBackground({
    super.key,
    required this.child,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Overlay removed
        // Content
        SafeArea(child: child),
      ],
    );
  }
}
