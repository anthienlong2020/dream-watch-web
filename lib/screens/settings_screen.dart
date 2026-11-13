import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/clock_theme.dart';
import '../services/app_state.dart';
import '../effects/element_effect.dart';
import '../three_d/body_type.dart';
import '../services/file_saver.dart';
import '../utils/image_utils.dart';
import '../widgets/slot_image_view.dart';
import 'chibi_maker_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      // Mỗi phần tự lắng nghe [app] để cập nhật khi cài đặt thay đổi.
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
        children: const [
          _Header('Bộ cấu hình của tôi'),
          _PresetSettings(),
          _Header('Chủ đề hình ảnh'),
          _ThemePicker(),
          SizedBox(height: 8),
          _CustomImagesEditor(),
          _Header('Kiểu, dáng & hệ từng hình'),
          _StyleSettings(),
          _Header('Âm báo mỗi giờ'),
          _ChimeSettings(),
          _Header('Tốc độ chuyển động'),
          _SpeedSettings(),
          _Header('Hình nền'),
          _BackgroundSettings(),
          _Header('Hiển thị'),
          _DisplaySettings(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}

// =====================================================================
// Chọn chủ đề
// =====================================================================

class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final themes = [
      buildDinoTheme(),
      buildZodiacTheme(),
      buildCustomTheme(app.customImages, app.customChibi),
    ];
    return Column(
      children: [
        for (final t in themes)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: app.themeId == t.id
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => app.update(() => app.themeId = t.id),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(app.themeId == t.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 92,
                      child: Text(t.name, style: const TextStyle(fontSize: 15)),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 1; i <= 6; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: SlotImageView(image: t.slot(i), size: 34),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// =====================================================================
// Ảnh của tôi: 12 ô ảnh
// =====================================================================

class _CustomImagesEditor extends StatefulWidget {
  const _CustomImagesEditor();

  @override
  State<_CustomImagesEditor> createState() => _CustomImagesEditorState();
}

class _CustomImagesEditorState extends State<_CustomImagesEditor> {
  bool _busy = false;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<List<PlatformFile>> _pick({required bool many}) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: many,
      withData: true,
    );
    return res?.files ?? const [];
  }

  Future<void> _pickOne(int index) async {
    final files = await _pick(many: false);
    if (files.isEmpty || files.first.bytes == null) return;
    setState(() => _busy = true);
    try {
      final small = await shrinkImage(files.first.bytes!);
      final ok = await app.setCustomImage(index, small);
      if (!ok) _toast('Không lưu được ảnh (bộ nhớ đầy?). Hãy thử ảnh nhỏ hơn.');
    } catch (_) {
      _toast('Không đọc được ảnh này. Hãy thử file PNG hoặc JPG khác.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Chạm vào một ô: chọn ảnh thường hoặc tạo Chibi từ ảnh người.
  Future<void> _slotMenu(int index) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Vị trí ${kRoman[index].toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Chọn ảnh'),
              subtitle: const Text('Con vật, đồ vật... (PNG nền trong suốt đẹp nhất)'),
              onTap: () => Navigator.pop(ctx, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.face_retouching_natural),
              title: const Text('Tạo Chibi từ ảnh người'),
              subtitle: const Text('Ghép khuôn mặt vào nhân vật đầu to thân nhỏ'),
              onTap: () => Navigator.pop(ctx, 'chibi'),
            ),
            if (app.customImages[index] != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Xoá ảnh ở vị trí này'),
                onTap: () => Navigator.pop(ctx, 'clear'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'image':
        await _pickOne(index);
        break;
      case 'clear':
        await app.setCustomImage(index, null);
        break;
      case 'chibi':
        final res = await Navigator.push<ChibiResult>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChibiMakerScreen(slotLabel: kRoman[index].toUpperCase()),
          ),
        );
        if (res != null) {
          final ok = await app.setCustomImage(index, res.png, chibi: res.spec);
          if (!ok) _toast('Không lưu được (bộ nhớ đầy?).');
        }
        break;
    }
  }

  /// Chọn nhiều ảnh: ảnh có số 1..12 trong tên sẽ vào đúng vị trí đó,
  /// các ảnh còn lại lấp vào ô trống theo thứ tự I, II, ... XII.
  Future<void> _pickMany() async {
    final files = await _pick(many: true);
    if (files.isEmpty) return;
    setState(() => _busy = true);
    try {
      final result = <int, Uint8List>{};
      final leftovers = <PlatformFile>[];
      for (final f in files) {
        if (f.bytes == null) continue;
        final n = numberFromFileName(f.name);
        if (n != null && !result.containsKey(n % 12)) {
          result[n % 12] = await shrinkImage(f.bytes!);
        } else {
          leftovers.add(f);
        }
      }
      leftovers.sort((x, y) => x.name.compareTo(y.name));
      const order = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0];
      var k = 0;
      for (final slot in order) {
        if (k >= leftovers.length) break;
        if (result.containsKey(slot)) continue;
        result[slot] = await shrinkImage(leftovers[k].bytes!);
        k++;
      }
      final ok = await app.setManyCustomImages(result);
      _toast(ok
          ? 'Đã thêm ${result.length} ảnh.'
          : 'Không lưu được hết ảnh (bộ nhớ đầy?). Hãy dùng ảnh nhỏ hơn.');
    } catch (_) {
      _toast('Có ảnh không đọc được. Hãy dùng PNG hoặc JPG.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final theme = buildCustomTheme(app.customImages, app.customChibi);
    const order = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ảnh của tôi', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            const Text(
              'Chạm vào một ô để chọn ảnh hoặc tạo Chibi từ ảnh người, giữ lâu để xoá. '
              'Mẹo: đặt tên file 1.png ... 12.png rồi bấm "Chọn nhiều ảnh" để '
              'tự xếp đúng vị trí. Ảnh PNG nền trong suốt nhìn đẹp nhất.',
              style: TextStyle(fontSize: 12.5, color: Colors.white60),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.8,
              children: [
                for (final i in order)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _busy ? null : () => _slotMenu(i),
                    onLongPress: app.customImages[i] == null
                        ? null
                        : () => app.setCustomImage(i, null),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: app.customImages[i] != null
                              ? Colors.tealAccent.withAlpha(140)
                              : Colors.white24,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: LayoutBuilder(
                                builder: (_, c) => SlotImageView(
                                  image: theme.slot(i),
                                  size: c.biggest.shortestSide,
                                ),
                              ),
                            ),
                          ),
                          Text(kRoman[i].toUpperCase(),
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _pickMany,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.photo_library_outlined),
                  label: const Text('Chọn nhiều ảnh'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || app.customImages.every((b) => b == null)
                      ? null
                      : () async {
                          final yes = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Xoá hết ảnh của tôi?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Không')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Xoá')),
                              ],
                            ),
                          );
                          if (yes == true) await app.clearCustomImages();
                        },
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Xoá hết'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Âm báo mỗi giờ
// =====================================================================

class _ChimeSettings extends StatelessWidget {
  const _ChimeSettings();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final on = app.chimeEnabled;
    final hours = List<int>.generate(24, (i) => i);
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Báo giờ'),
            subtitle: const Text('Phát âm thanh khi tròn giờ'),
            value: on,
            onChanged: (v) => app.update(() => app.chimeEnabled = v),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'dem', label: Text('Đánh số tiếng')),
                ButtonSegment(value: 'chuong', label: Text('Giai điệu')),
                ButtonSegment(value: 'ca_hai', label: Text('Cả hai')),
              ],
              selected: {app.chimeMode},
              onSelectionChanged: on
                  ? (v) => app.update(() => app.chimeMode = v.first)
                  : null,
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              '"Đánh số tiếng": 3 giờ đánh 3 tiếng, 12 giờ đánh 12 tiếng, như đồng hồ quả lắc.',
              style: TextStyle(fontSize: 12.5, color: Colors.white60),
            ),
          ),
          SwitchListTile(
            title: const Text('Báo cả nửa giờ'),
            subtitle: const Text('Đánh 1 tiếng lúc :30'),
            value: app.chimeHalfHour,
            onChanged: on ? (v) => app.update(() => app.chimeHalfHour = v) : null,
          ),
          SwitchListTile(
            title: const Text('Giờ yên lặng'),
            subtitle: Text('Không báo giờ từ ${app.quietStart}h đến ${app.quietEnd}h'),
            value: app.quietEnabled,
            onChanged: on ? (v) => app.update(() => app.quietEnabled = v) : null,
          ),
          if (app.quietEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Từ'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: app.quietStart,
                    items: [
                      for (final h in hours)
                        DropdownMenuItem(value: h, child: Text('$h giờ')),
                    ],
                    onChanged: on
                        ? (v) => app.update(() => app.quietStart = v ?? app.quietStart)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  const Text('đến'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: app.quietEnd,
                    items: [
                      for (final h in hours)
                        DropdownMenuItem(value: h, child: Text('$h giờ')),
                    ],
                    onChanged: on
                        ? (v) => app.update(() => app.quietEnd = v ?? app.quietEnd)
                        : null,
                  ),
                ],
              ),
            ),
          ListTile(
            leading: const Icon(Icons.volume_up_outlined),
            title: Slider(
              value: app.volume,
              onChanged: (v) => app.update(() => app.volume = v),
            ),
            trailing: TextButton(
              onPressed: () => app.playHourChime(DateTime.now().hour),
              child: const Text('Nghe thử'),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Hiển thị
// =====================================================================

class _DisplaySettings extends StatelessWidget {
  const _DisplaySettings();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Hiện giờ dạng số'),
            value: app.showTime,
            onChanged: (v) => app.update(() => app.showTime = v),
          ),
          SwitchListTile(
            title: const Text('Hiện ngày tháng'),
            value: app.showDate,
            onChanged: (v) => app.update(() => app.showDate = v),
          ),
          SwitchListTile(
            title: const Text('Hiện số La Mã'),
            value: app.showRoman,
            onChanged: (v) => app.update(() => app.showRoman = v),
          ),
          SwitchListTile(
            title: const Text('Ảnh 3D quay tròn 360°'),
            subtitle: const Text(
                'Ảnh giờ và ảnh giữa (Chibi 3D, ảnh thổi phồng) quay hết vòng. '
                'Tắt thì chỉ đung đưa trái - phải.'),
            value: app.spin360,
            onChanged: (v) => app.update(() => app.spin360 = v),
          ),
          SwitchListTile(
            title: const Text('Hiện ngôi sao'),
            value: app.showStars,
            onChanged: (v) => app.update(() => app.showStars = v),
          ),
          SwitchListTile(
            title: const Text('Giữ màn hình luôn sáng'),
            subtitle: const Text('Để báo thức và báo giờ hoạt động ổn định'),
            value: app.keepAwake,
            onChanged: app.setKeepAwake,
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Tốc độ chuyển động
// =====================================================================

const List<double> _speedSteps = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0];

String _speedLabel(double v) {
  if (v <= 0.25) return 'Rất chậm';
  if (v <= 0.5) return 'Chậm';
  if (v <= 0.75) return 'Hơi chậm';
  if (v <= 1.0) return 'Vừa';
  if (v <= 1.5) return 'Hơi nhanh';
  return 'Nhanh';
}

class _SpeedSettings extends StatelessWidget {
  const _SpeedSettings();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              _speedRow('Giờ', 'Ảnh giờ và ảnh giữa đung đưa', app.hourSpeed,
                  (v) => app.update(() => app.hourSpeed = v)),
              _speedRow('Phút', 'Ảnh phút nhảy bậc thang', app.minuteSpeed,
                  (v) => app.update(() => app.minuteSpeed = v)),
              _speedRow('Giây', 'Kim giây lướt vòng (vẫn đúng 1 bước/giây)',
                  app.secondSpeed, (v) => app.update(() => app.secondSpeed = v)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => app.update(() {
                    app.hourSpeed = 1.0;
                    app.minuteSpeed = 1.0;
                    app.secondSpeed = 1.0;
                  }),
                  child: const Text('Về mặc định'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _speedRow(String title, String hint, double value,
      ValueChanged<double> onChanged) {
    var idx = _speedSteps.indexWhere((x) => (x - value).abs() < 0.01);
    if (idx < 0) idx = 3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 15)),
              const Spacer(),
              Text(_speedLabel(_speedSteps[idx]),
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Text(hint, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          Slider(
            value: idx.toDouble(),
            min: 0,
            max: (_speedSteps.length - 1).toDouble(),
            divisions: _speedSteps.length - 1,
            label: _speedLabel(_speedSteps[idx]),
            onChanged: (v) => onChanged(_speedSteps[v.round()]),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Hình nền
// =====================================================================

class _BackgroundSettings extends StatefulWidget {
  const _BackgroundSettings();

  @override
  State<_BackgroundSettings> createState() => _BackgroundSettingsState();
}

class _BackgroundSettingsState extends State<_BackgroundSettings> {
  bool _busy = false;
  static const _intervals = [1, 2, 5, 10, 15, 30, 60];

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _add() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    final files = res?.files ?? const <PlatformFile>[];
    if (files.isEmpty) return;
    setState(() => _busy = true);
    try {
      final out = <Uint8List>[];
      for (final f in files) {
        final b = f.bytes;
        if (b == null) continue;
        out.add(await shrinkToJpeg(b));
      }
      final added = await app.addBackgrounds(out);
      if (added < out.length) {
        _toast('Đã thêm $added/${out.length} ảnh. Bộ nhớ trình duyệt đã đầy, '
            'hãy xoá bớt ảnh nền cũ nếu muốn thêm nữa.');
      } else {
        _toast('Đã thêm $added hình nền (tổng ${app.backgrounds.length}).');
      }
    } catch (_) {
      _toast('Có ảnh không đọc được. Hãy dùng PNG hoặc JPG.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Chọn bao nhiêu ảnh cũng được, ảnh tự đổi lần lượt theo thời gian '
                'bên dưới. Dùng ảnh 1080p trở xuống để ít dung lượng nhất. '
                'Giữ lâu vào ảnh để xoá. Chưa có ảnh nào thì nền màu đen.',
                style: TextStyle(fontSize: 12.5, color: Colors.white60),
              ),
              const SizedBox(height: 10),
              if (app.backgrounds.isNotEmpty)
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: app.backgrounds.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => GestureDetector(
                      onLongPress: () => app.removeBackground(i),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(app.backgrounds[i],
                            width: 60, height: 84, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _busy ||
                          app.backgrounds.length >= AppState.maxBackgrounds
                      ? null
                      : _add,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wallpaper),
                  label: const Text('Thêm hình nền'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: Text('Đổi hình nền mỗi')),
                  DropdownButton<int>(
                    value: _intervals.contains(app.bgIntervalMin)
                        ? app.bgIntervalMin
                        : 5,
                    items: [
                      for (final m in _intervals)
                        DropdownMenuItem(
                            value: m,
                            child: Text(m == 60 ? '1 giờ' : '$m phút')),
                    ],
                    onChanged: (v) =>
                        app.update(() => app.bgIntervalMin = v ?? 5),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Độ tối nền'),
                  Expanded(
                    child: Slider(
                      value: app.bgDim.clamp(0.0, 0.8),
                      max: 0.8,
                      onChanged: (v) => app.update(() => app.bgDim = v),
                    ),
                  ),
                  Text('${(app.bgDim * 100).round()}%'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Lưu / mở bộ cấu hình ra file trên thiết bị
// =====================================================================

class _PresetSettings extends StatefulWidget {
  const _PresetSettings();

  @override
  State<_PresetSettings> createState() => _PresetSettingsState();
}

class _PresetSettingsState extends State<_PresetSettings> {
  bool _busy = false;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 5)));
  }

  static String _safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
    return cleaned.isEmpty ? 'bo_dong_ho' : cleaned;
  }

  Future<void> _save() async {
    final nameCtrl = TextEditingController(text: app.presetName ?? '');
    var withAlarms = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Lưu bộ cấu hình'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tên bộ (vd: Gia đình, Khủng long xanh)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: withAlarms,
                onChanged: (v) => setD(() => withAlarms = v ?? false),
                title: const Text('Kèm danh sách báo thức'),
              ),
              const Text(
                'Gồm: 12 ảnh giờ, ảnh nền, chủ đề, tốc độ, báo giờ, hiển thị. '
                'Hãy nhớ nơi lưu file để lần sau mở lại.',
                style: TextStyle(fontSize: 12.5, color: Colors.white60),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim().isEmpty ? 'Bộ đồng hồ' : nameCtrl.text.trim();
    setState(() => _busy = true);
    try {
      final bytes = app.exportPreset(name, withAlarms: withAlarms);
      final fileName = '${_safeFileName(name)}.${AppState.presetExt}';
      final saved = await saveBytesToDevice(bytes, fileName);
      if (saved) {
        _toast('Đã lưu "$fileName" (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB). '
            'Bản web: file nằm trong thư mục Tải xuống / Downloads.');
      }
    } catch (e) {
      _toast('Không lưu được file: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    final file = res?.files.first;
    final bytes = file?.bytes;
    if (bytes == null || !mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mở bộ cấu hình?'),
        content: Text('Ảnh giờ, ảnh nền và cài đặt hiện tại sẽ được thay bằng nội dung '
            'của "${file!.name}".\nNếu chưa lưu bộ hiện tại, hãy bấm Huỷ và lưu trước.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mở')),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => _busy = true);
    try {
      final missing = await app.importPreset(bytes);
      _toast(missing == 0
          ? 'Đã mở bộ "${app.presetName ?? file!.name}".'
          : 'Đã mở bộ, nhưng $missing ảnh nền không vừa bộ nhớ trình duyệt.');
    } on FormatException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('File bị lỗi hoặc không đúng định dạng.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                app.presetName == null
                    ? 'Chưa đặt tên bộ cấu hình'
                    : 'Đang dùng: ${app.presetName}',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lưu toàn bộ ảnh + cài đặt thành 1 file trên máy để giữ lâu dài, '
                'chuyển sang máy khác hoặc gửi cho bạn bè. Khi cần thì mở lại.',
                style: TextStyle(fontSize: 12.5, color: Colors.white60),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_alt),
                    label: const Text('Lưu thành file'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _open,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Mở file'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Kiểu, dáng & hệ: mặc định + riêng từng vị trí (danh sách thả xuống)
// =====================================================================

class _StyleSettings extends StatelessWidget {
  const _StyleSettings();

  static Widget _drop<T>(T value, List<T> values, String Function(T) label,
      ValueChanged<T> onChanged) {
    return DropdownButton<T>(
      isExpanded: true,
      value: value,
      items: [
        for (final v in values) DropdownMenuItem<T>(value: v, child: Text(label(v))),
      ],
      onChanged: (v) => onChanged(v as T),
    );
  }

  /// Một khối gồm: hình + tên vị trí + Kiểu (dòng 1), Dáng + Hệ (dòng 2).
  Widget _block({
    required Widget leading,
    required Widget style,
    required Widget body,
    required Widget element,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(children: [leading, Expanded(child: style)]),
          Row(
            children: [
              const SizedBox(width: 92),
              Expanded(child: body),
              const SizedBox(width: 8),
              Expanded(child: element),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final theme = app.theme;
        const order = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0];
        final stylesN = <ImageStyle?>[null, ...ImageStyle.values];
        final bodiesN = <BodyType?>[null, ...BodyType.values];
        final elemsN = <ElementType?>[null, ...ElementType.values];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Kiểu – Standard: ảnh phẳng. 3D thổi phồng: khối tròn như thú bông. '
                  'Chibi 3D: ảnh làm mặt trên thân chibi (con vật thành "thú chibi"). '
                  'Người que: ảnh làm đầu trên thân người que.\n'
                  'Hệ – Lửa, Nước, Điện: đổi chất liệu và thêm hiệu ứng động quanh hình.',
                  style: TextStyle(fontSize: 12.5, color: Colors.white60),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bật hiệu ứng hệ'),
                  subtitle: const Text('Tắt nếu máy chạy chậm'),
                  value: app.effectsOn,
                  onChanged: (v) => app.update(() => app.effectsOn = v),
                ),
                _block(
                  leading: const SizedBox(
                    width: 92,
                    child: Text('Mặc định', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  style: _drop<ImageStyle>(app.defaultStyle, ImageStyle.values,
                      (v) => kImageStyleNames[v]!, (v) => app.update(() => app.defaultStyle = v)),
                  body: _drop<BodyType>(app.defaultBody, BodyType.values,
                      (v) => 'Dáng: ${kBodyTypeNames[v]!}', (v) => app.update(() => app.defaultBody = v)),
                  element: _drop<ElementType>(app.defaultElement, ElementType.values,
                      (v) => 'Hệ: ${kElementNames[v]!}',
                      (v) => app.update(() => app.defaultElement = v)),
                ),
                const Divider(),
                for (final i in order)
                  _block(
                    leading: SizedBox(
                      width: 92,
                      child: Row(
                        children: [
                          SlotImageView(image: theme.slot(i), size: 34),
                          const SizedBox(width: 8),
                          Text(kRoman[i].toUpperCase()),
                        ],
                      ),
                    ),
                    style: _drop<ImageStyle?>(app.slotStyle[i], stylesN,
                        (v) => v == null ? 'Kiểu: mặc định' : kImageStyleNames[v]!,
                        (v) => app.update(() => app.slotStyle[i] = v)),
                    body: _drop<BodyType?>(app.slotBody[i], bodiesN,
                        (v) => v == null ? 'Dáng: mặc định' : 'Dáng: ${kBodyTypeNames[v]!}',
                        (v) => app.update(() => app.slotBody[i] = v)),
                    element: _drop<ElementType?>(app.slotElement[i], elemsN,
                        (v) => v == null ? 'Hệ: mặc định' : 'Hệ: ${kElementNames[v]!}',
                        (v) => app.update(() => app.slotElement[i] = v)),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => app.update(() {
                      app.slotStyle = List<ImageStyle?>.filled(12, null);
                      app.slotBody = List<BodyType?>.filled(12, null);
                      app.slotElement = List<ElementType?>.filled(12, null);
                    }),
                    child: const Text('Đưa tất cả về mặc định'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
