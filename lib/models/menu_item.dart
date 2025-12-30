import 'package:flutter/material.dart';

class MenuItemModel {
  MenuItemModel({
    this.id,
    this.title = "",
    required this.icon,
    this.color = Colors.white,
    this.screen,
    this.routeName,
    this.enabled = true,
  });

  UniqueKey? id = UniqueKey();
  String title;
  IconData icon;
  Color color;
  Widget? screen; // Deprecated - use routeName instead
  String? routeName;
  bool enabled;
}

