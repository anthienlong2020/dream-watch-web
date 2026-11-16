import 'package:flutter/material.dart';

import 'screens/calendar_screen.dart';
import 'screens/clock_screen.dart';
import 'screens/ring_overlay.dart';
import 'screens/settings_screen.dart';
import 'screens/timer_screen.dart';
import 'models/clock_theme.dart';
import 'themes/event_background.dart';
import 'services/app_state.dart';
import 'widgets/touch_dot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([loadDinoAssets(), loadEventImages()]);
  await app.init();
  runApp(const DreamWatchApp());
}

class DreamWatchApp extends StatelessWidget {
  const DreamWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đồng hồ mộng mơ',
      debugShowCheckedModeBanner: false,
      // kéo bằng chuột cũng cuộn được như vuốt trên điện thoại
      scrollBehavior: const DragAllScrollBehavior(),
      builder: (context, child) => TouchDot.enabled ? TouchDot(child: child!) : child!,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF4FF3F0),
        scaffoldBackgroundColor: const Color(0xFF0B1020),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  static const _pages = [
    ClockScreen(),
    TimerScreen(), // Báo thức + Hẹn giờ + Bấm giờ
    CalendarScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final ring = app.ringing;
        return Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.black,
              body: IndexedStack(index: _tab, children: _pages),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                height: 64,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  const NavigationDestination(
                      icon: Icon(Icons.access_time), label: 'Đồng hồ'),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: app.alarms.any((a) => a.enabled) ||
                          app.timerRunning ||
                          app.stopwatch.isRunning,
                      smallSize: 8,
                      child: const Icon(Icons.timer_outlined),
                    ),
                    label: 'Đếm giờ',
                  ),
                  const NavigationDestination(
                      icon: Icon(Icons.calendar_month_outlined), label: 'Lịch'),
                  const NavigationDestination(
                      icon: Icon(Icons.settings_outlined), label: 'Cài đặt'),
                ],
              ),
            ),
            if (ring != null) Positioned.fill(child: RingOverlay(info: ring)),
            if (!app.started) const Positioned.fill(child: StartOverlay()),
          ],
        );
      },
    );
  }
}
