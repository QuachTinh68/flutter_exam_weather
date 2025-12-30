import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../theme/theme.dart';

class MenuRow extends StatelessWidget {
  const MenuRow({
    Key? key,
    required this.menu,
    this.selectedMenu = "",
    this.onMenuPress,
  }) : super(key: key);

  final MenuItemModel menu;
  final String selectedMenu;
  final Function? onMenuPress;

  void onMenuPressed() {
    if (selectedMenu != menu.title && menu.enabled) {
      onMenuPress!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedMenu == menu.title;
    final isEnabled = menu.enabled;

    return Stack(
      children: [
        // The menu button background that animates as we click on it
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isSelected ? 264 : 0,
          height: 48,
          curve: const Cubic(0.2, 0.8, 0.2, 1),
          decoration: BoxDecoration(
            color: AppTheme.accentColor,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          pressedOpacity: 1,
          onPressed: isEnabled ? onMenuPressed : null,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  menu.icon,
                  size: 16,
                  color: isEnabled
                      ? (isSelected ? Colors.white : Colors.white.withOpacity(0.75))
                      : Colors.white.withOpacity(0.35),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  menu.title,
                  style: TextStyle(
                    color: isEnabled
                        ? (isSelected ? Colors.white : Colors.white.withOpacity(0.85))
                        : Colors.white.withOpacity(0.4),
                    fontFamily: "Inter",
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (!isEnabled)
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: Colors.white.withOpacity(0.3),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

