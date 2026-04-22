import 'package:flutter/material.dart';

class AppClickableWrapper extends StatelessWidget {
  final Widget child;           // What is inside?
  final VoidCallback onTap;     // What happens on click?
  final Color? backgroundColor; // Optional color
  final double borderRadius;    // Defaulting to our 12px standard

  const AppClickableWrapper({
    super.key,
    required this.child,
    required this.onTap,
    this.backgroundColor,
    this.borderRadius = 12.0, // Default value
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.transparent, // If no color, be see-through
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: child, // This is where your custom UI goes
      ),
    );
  }
}