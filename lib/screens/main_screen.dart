import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/base_scaffold.dart';
import 'calendar_screen.dart';
import 'today_detail_screen.dart';
import 'notes_screen_new.dart' as notes;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static _MainScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainScreenState>();
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void changeTab(int index) {
    // Kiểm tra đăng nhập khi chuyển sang tab Notes (index 2)
    if (index == 2) {
      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isLoggedIn) {
        // Chưa đăng nhập, chuyển sang màn hình đăng nhập
        Navigator.of(context).pushNamed('/login').then((result) {
          // Sau khi đăng nhập xong, quay lại và chuyển sang tab Notes
          if (mounted && result == true && context.read<AuthProvider>().isLoggedIn) {
            setState(() => _currentIndex = index);
          }
        });
        return;
      }
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeatherProvider>();

    // Đảm bảo dữ liệu được load khi mở app
    if (vm.place == null && !vm.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vm.bootstrap();
      });
    }

    return BaseScaffold(
      showAppBar: false,
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TodayDetailScreen(),
          CalendarScreen(),
          notes.NotesScreenNew(),
        ],
      ),
    );
  }
}


