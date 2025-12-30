import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../theme/theme.dart';
import '../widgets/menu_row.dart';
import '../providers/auth_provider.dart';
import '../screens/main_screen.dart';
import '../widgets/base_scaffold.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  final List<MenuItemModel> _mainMenuItems = [
    MenuItemModel(
      title: "Hôm nay",
      icon: Icons.today_rounded,
      routeName: null, // Will be handled by tab change
      enabled: true,
    ),
    MenuItemModel(
      title: "Lịch",
      icon: Icons.calendar_month_rounded,
      routeName: null, // Will be handled by tab change
      enabled: true,
    ),
    MenuItemModel(
      title: "Ghi chú",
      icon: Icons.note_rounded,
      routeName: null, // Will be handled by tab change
      enabled: true,
    ),
  ];

  List<MenuItemModel> _getAccountMenuItems(bool isLoggedIn) {
    if (isLoggedIn) {
      return [
        MenuItemModel(
          title: "Đăng xuất",
          icon: Icons.logout,
          routeName: null,
          enabled: true,
        ),
      ];
    } else {
      return [
        MenuItemModel(
          title: "Đăng nhập",
          icon: Icons.login,
          routeName: '/login',
          enabled: true,
        ),
      ];
    }
  }

  String _selectedMenu = "";

  void onMenuPress(MenuItemModel menu) {
    setState(() {
      _selectedMenu = menu.title;
    });
    
    // Close menu first
    final baseScaffold = BaseScaffold.of(context);
    baseScaffold?.closeMenu();
    
    if (menu.title == "Đăng xuất") {
      // Handle logout
      Future.delayed(const Duration(milliseconds: 200), () {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.logout();
        // Không cần chuyển sang login, vẫn ở MainScreen
        setState(() {}); // Refresh UI
      });
      return;
    }
    
    if (menu.title == "Đăng nhập") {
      // Handle login navigation
      Future.delayed(const Duration(milliseconds: 200), () {
        Navigator.of(context).pushNamed('/login').then((result) {
          if (result == true && mounted) {
            setState(() {}); // Refresh UI after login
          }
        });
      });
      return;
    }
    
    // Handle tab navigation for main menu items
    final mainScreen = MainScreen.of(context);
    if (mainScreen != null) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (menu.title == "Hôm nay") {
          mainScreen.changeTab(0);
        } else if (menu.title == "Lịch") {
          mainScreen.changeTab(1);
        } else if (menu.title == "Ghi chú") {
          // Kiểm tra đăng nhập trước khi chuyển sang tab Notes
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.isLoggedIn) {
            // Chưa đăng nhập, chuyển sang màn hình đăng nhập
            Navigator.of(context).pushNamed('/login').then((_) {
              // Sau khi đăng nhập xong, quay lại và chuyển sang tab Notes
              if (context.mounted && authProvider.isLoggedIn) {
                mainScreen.changeTab(2);
              }
            });
          } else {
            mainScreen.changeTab(2);
          }
        }
      });
      return;
    }
    
    // Handle route navigation for other items
    if (menu.routeName != null && menu.enabled) {
      Future.delayed(const Duration(milliseconds: 200), () {
        Navigator.pushReplacementNamed(context, menu.routeName!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isLoggedIn = authProvider.isLoggedIn;
    final accountMenuItems = _getAccountMenuItems(isLoggedIn);

    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: (MediaQuery.of(context).padding.bottom - 40).clamp(0.0, double.infinity)),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: AppTheme.background2,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  foregroundColor: Colors.white,
                  radius: 24,
                  child: Icon(
                    Icons.person_outline,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.username ?? "Người dùng",
                        style: const TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 16,
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Weather Calendar",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 13,
                            fontFamily: "Inter",
                            letterSpacing: -0.2),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  MenuButtonSection(
                      title: "MENU CHÍNH",
                      selectedMenu: _selectedMenu,
                      menuItems: _mainMenuItems,
                      onMenuPress: onMenuPress),
                  MenuButtonSection(
                      title: "TÀI KHOẢN",
                      selectedMenu: _selectedMenu,
                      menuItems: accountMenuItems,
                      onMenuPress: onMenuPress),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MenuButtonSection extends StatelessWidget {
  const MenuButtonSection({
    Key? key,
    required this.title,
    required this.menuItems,
    this.selectedMenu = "",
    this.onMenuPress,
  }) : super(key: key);

  final String title;
  final String selectedMenu;
  final List<MenuItemModel> menuItems;
  final Function(MenuItemModel menu)? onMenuPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 32, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
                fontFamily: "Inter",
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              for (var menu in menuItems) ...[
                Divider(
                    color: Colors.white.withOpacity(0.08),
                    thickness: 0.5,
                    height: 0.5,
                    indent: 12,
                    endIndent: 12),
                MenuRow(
                  menu: menu,
                  selectedMenu: selectedMenu,
                  onMenuPress: () => onMenuPress!(menu),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }
}

