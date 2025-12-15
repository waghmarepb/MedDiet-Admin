import 'package:flutter/material.dart';

class ResponsiveScaler extends StatelessWidget {
  final Widget child;
  const ResponsiveScaler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double baseWidth = 1440; // your dashboard design width  
        double scale = constraints.maxWidth / baseWidth;

        return Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: child,
        );
      },
    );
  }
}
