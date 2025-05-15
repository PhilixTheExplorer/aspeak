import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final EdgeInsets padding;
  final double fontSize;

  const AppButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.backgroundColor = const Color(0xFF64CCC5),
    this.textColor = Colors.black,
    this.borderRadius = 30.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Text(text, style: TextStyle(fontSize: fontSize)),
    );
  }
}
