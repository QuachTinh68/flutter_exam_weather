import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'side_menu.dart';
import '../theme/theme.dart';

class BaseScaffold extends StatefulWidget {
  final Widget body;
  final String? title;
  final bool showAppBar;
  final bool showDrawerButton;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;

  const BaseScaffold({
    Key? key,
    required this.body,
    this.title,
    this.showAppBar = true,
    this.showDrawerButton = true,
    this.appBar,
    this.backgroundColor,
  }) : super(key: key);

  static _BaseScaffoldState? of(BuildContext context) {
    return context.findAncestorStateOfType<_BaseScaffoldState>();
  }

  @override
  State<BaseScaffold> createState() => _BaseScaffoldState();
}

class _BaseScaffoldState extends State<BaseScaffold>
    with TickerProviderStateMixin {
  late AnimationController? _animationController;
  late Animation<double> _sidebarAnim;

  final springDesc = const SpringDescription(
    mass: 0.1,
    stiffness: 40,
    damping: 5,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      upperBound: 1,
      vsync: this,
    );

    _sidebarAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void onMenuPress() {
    if (_animationController!.value == 0) {
      final springAnim = SpringSimulation(springDesc, 0, 1, 0);
      _animationController?.animateWith(springAnim);
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    } else {
      _animationController?.reverse();
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    }
  }

  void openMenu() {
    if (_animationController!.value == 0) {
      final springAnim = SpringSimulation(springDesc, 0, 1, 0);
      _animationController?.animateWith(springAnim);
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    }
  }

  void closeMenu() {
    if (_animationController!.value != 0) {
      _animationController?.reverse();
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: widget.backgroundColor ?? AppTheme.background,
      appBar: widget.showAppBar
          ? (widget.appBar ??
              AppBar(
                title: Text(
                  widget.title ?? 'Weather Calendar',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                backgroundColor: AppTheme.background2,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: widget.showDrawerButton
                    ? IconButton(
                        icon: const Icon(Icons.menu, size: 22),
                        onPressed: onMenuPress,
                        padding: const EdgeInsets.all(12),
                      )
                    : null,
              ))
          : null,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(color: widget.backgroundColor ?? AppTheme.background),
          ),
          // Side Menu
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _sidebarAnim,
              builder: (BuildContext context, Widget? child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(((1 - _sidebarAnim.value) * -30) * math.pi / 180)
                    ..translate((1 - _sidebarAnim.value) * -300),
                  child: child,
                );
              },
              child: FadeTransition(
                opacity: _sidebarAnim,
                child: const SideMenu(),
              ),
            ),
          ),
          // Main Content
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _sidebarAnim,
              builder: (context, child) {
                return GestureDetector(
                  onTap: () {
                    if (_sidebarAnim.value > 0) {
                      closeMenu();
                    }
                  },
                  child: Transform.scale(
                    scale: 1 - (_sidebarAnim.value * 0.1),
                    child: Transform.translate(
                      offset: Offset(_sidebarAnim.value * 265, 0),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY((_sidebarAnim.value * 30) * math.pi / 180),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
              child: widget.body,
            ),
          ),
        ],
      ),
    );
  }
}

