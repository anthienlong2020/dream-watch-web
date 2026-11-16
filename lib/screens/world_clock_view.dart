import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../utils/vn_format.dart';
import '../utils/world_time.dart';
import '../widgets/tick_builder.dart';

/// Giờ thế giới: giờ hiện tại ở các thành phố đã chọn, có đổi giờ mùa hè.
class WorldClockView extends StatelessWidget {
  const WorldClockView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pick(context),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Thêm thành phố'),
      ),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) => TickBuilder(
          interval: const Duration(seconds: 1),
          builder: (context) {
            final now = DateTime.now();
            final localOffset = now.timeZoneOffset.inMinutes;
            final cities = app.worldCities.map(cityById).whereType<City>().toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.my_location),
                    title: const Text('Giờ của bạn'),
                    subtitle: Text(formatDateVn(now)),
                    trailing: Text('${two(now.hour)}:${two(now.minute)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300)),
                  ),
                ),
                if (cities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Bấm "Thêm thành phố" để xem giờ ở nơi người thân đang sống.',
                        textAlign: TextAlign.center),
                  ),
                for (final c in cities) _CityTile(city: c, now: now, localOffset: localOffset),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CityTile extends StatelessWidget {
  final City city;
  final DateTime now;
  final int localOffset;
  const _CityTile({required this.city, required this.now, required this.localOffset});

  @override
  Widget build(BuildContext context) {
    final t = city.localTime(now);
    final off = city.offsetAt(now.toUtc());
    final myDay = DateTime.utc(now.year, now.month, now.day);
    final theirDay = DateTime.utc(t.year, t.month, t.day);
    final dd = theirDay.difference(myDay).inDays;
    final dayText = dd == 0 ? 'Hôm nay' : (dd > 0 ? 'Ngày mai' : 'Hôm qua');
    final night = t.hour < 6 || t.hour >= 18;
    return Card(
      child: ListTile(
        leading: Text(city.flag, style: const TextStyle(fontSize: 30)),
        title: Text(city.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$dayText · ${diffText(off - localOffset)}'
            '${city.isDst(now.toUtc()) ? ' · giờ mùa hè' : ''}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(night ? '🌙' : '☀️', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text('${two(t.hour)}:${two(t.minute)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300,
                    fontFeatures: [FontFeature.tabularFigures()])),
            IconButton(
              tooltip: 'Bỏ',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => app.removeWorldCity(city.id),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pick(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Chọn thành phố', style: TextStyle(fontSize: 20)),
          ),
          for (final c in kCities)
            ListTile(
              leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
              title: Text(c.name),
              subtitle: Text(c.country),
              trailing: app.worldCities.contains(c.id) ? const Icon(Icons.check) : null,
              onTap: () {
                app.addWorldCity(c.id);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    ),
  );
}
