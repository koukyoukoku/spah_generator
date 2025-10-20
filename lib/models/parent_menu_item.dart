import 'package:flutter/material.dart';
import 'package:spah_generator/screens/parent_control/change_pin_screen.dart';

class ParentMenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget Function(BuildContext) screenBuilder;

  const ParentMenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.screenBuilder,
  });
}