import 'package:flutter/material.dart';

import 'screens/alarms_screen.dart';
import 'screens/clock_screen.dart';
import 'screens/ring_overlay.dart';
import 'screens/settings_screen.dart';
import 'screens/timer_screen.dart';
import 'models/clock_theme.dart';
import 'services/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadDinoAssets();
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
    AlarmsScreen(),
    TimerScreen(),
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
                      isLabelVisible: app.alarms.any((a) => a.enabled),
                      smallSize: 8,
                      child: const Icon(Icons.alarm),
                    ),
                    label: 'Báo thức',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: app.timerRunning || app.stopwatch.isRunning,
                      smallSize: 8,
                      child: const Icon(Icons.timer_outlined),
                    ),
                    label: 'Đếm giờ',
                  ),
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
