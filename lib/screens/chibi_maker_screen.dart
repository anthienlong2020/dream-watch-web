import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../chibi/chibi3d.dart';
import '../chibi/chibi_painter.dart';
import '../services/app_state.dart';
import '../widgets/tick_builder.dart';

/// Kết quả tạo Chibi: ảnh phẳng (để làm hình thu nhỏ) + thông tin dựng 3D.
class ChibiResult {
  final Uint8List png;
  final ChibiSpec spec;
  const ChibiResult(this.png, this.spec);
}

/// Màn hình tạo nhân vật Chibi từ ảnh người:
/// 1) chọn ảnh, 2) kéo/phóng để khoanh khuôn mặt, 3) chọn trang phục + màu.
/// Kết quả trả về là [ChibiResult] (Navigator.pop).
class ChibiMakerScreen extends StatefulWidget {
  /// Tên vị trí sẽ gắn chibi (vd "VII"), chỉ để hiển thị.
  final String slotLabel;
  const ChibiMakerScreen({super.key, required this.slotLabel});

  @override
  State<ChibiMakerScreen> createState() => _ChibiMakerScreenState();
}

class _ChibiMakerScreenState extends State<ChibiMakerScreen> {
  static const double _viewport = 240;
  static const List<Color> _skinPresets = [
    Color(0xFFFFE0C4),
    Color(0xFFF1C27D),
    Color(0xFFE0AC69),
    Color(0xFFC68642),
    Color(0xFF8D5524),
  ];

  ui.Image? _photo;
  double _zoom = 1;
  Offset _offset = Offset.zero;
  double _startZoom = 1;

  ChibiOutfit _outfit = ChibiOutfit.aoThun;
  Color _color = kOutfitColors[4];
  Color _skin = _skinPresets[1];
  bool _autoSkin = true;
  bool _busy = false;

  static const List<Color> _hairPresets = [
    Color(0xFF1B1B1B), // đen
    Color(0xFF3E2723), // nâu đen
    Color(0xFF6D4C41), // nâu
    Color(0xFFC8A165), // vàng
    Color(0xFF9E9E9E), // bạc
    Color(0xFFE91E63), // hồng
  ];
  Color _hair = _hairPresets[1];
  bool _autoHair = true;

  Uint8List? _facePng; // ảnh mặt tròn để dán lên Chibi 3D
  ChibiSpec? _spec;
  double _dragYaw = 0;
  bool _dragging = false;

  void _rebuildSpec() {
    final f = _facePng;
    if (f == null) return;
    _spec = ChibiSpec(
        face: f, outfit: _outfit, outfitColor: _color, skin: _skin, hair: _hair);
  }

  /// Gọi khi khung mặt thay đổi xong: tạo lại ảnh mặt + màu da/tóc tự động.
  Future<void> _refreshFace() async {
    final p = _photo;
    if (p == null) return;
    final crop = _crop;
    final face = await renderFacePng(p, crop);
    final skin = _autoSkin ? await sampleSkinColor(p, crop) : _skin;
    final hair = _autoHair ? await sampleHairColor(p, crop) : _hair;
    if (!mounted) return;
    setState(() {
      _facePng = face;
      _skin = skin;
      _hair = hair;
      _rebuildSpec();
    });
  }

  FaceCrop get _crop => FaceCrop(zoom: _zoom, offset: _offset, viewport: _viewport);

  @override
  void dispose() {
    _photo?.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final bytes = res?.files.first.bytes;
    if (bytes == null) return;
    setState(() => _busy = true);
    try {
      final img = await decodePhoto(bytes);
      _photo?.dispose();
      setState(() {
        _photo = img;
        _zoom = 1.6; // mặt thường chiếm phần giữa ảnh
        _offset = Offset.zero;
      });
      await _refreshFace();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không đọc được ảnh này, hãy thử ảnh khác.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _done() async {
    final p = _photo;
    if (p == null) return;
    setState(() => _busy = true);
    final png = await renderChibiPng(
        photo: p, crop: _crop, outfit: _outfit, color: _color, skin: _skin);
    final face = _facePng ?? await renderFacePng(p, _crop);
    final spec = ChibiSpec(
        face: face, outfit: _outfit, outfitColor: _color, skin: _skin, hair: _hair);
    if (mounted) Navigator.pop<ChibiResult>(context, ChibiResult(png, spec));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tạo Chibi cho vị trí ${widget.slotLabel}')),
      body: _photo == null ? _pickPrompt() : _editor(),
      bottomNavigationBar: _photo == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _busy ? null : _done,
                  icon: const Icon(Icons.check),
                  label: const Text('Dùng Chibi này'),
                ),
              ),
            ),
    );
  }

  Widget _pickPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.face_retouching_natural, size: 72, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'Chọn một ảnh có khuôn mặt rõ, nhìn thẳng.\n'
              'Sau đó kéo và phóng to để khuôn mặt nằm gọn trong vòng tròn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _pickPhoto,
              icon: _busy
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.photo),
              label: const Text('Chọn ảnh người'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editor() {
    final photo = _photo!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('1. Khoanh khuôn mặt',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const Text('Kéo ảnh để di chuyển, chụm 2 ngón / lăn chuột / thanh trượt để phóng to.',
            style: TextStyle(fontSize: 12.5, color: Colors.white60)),
        const SizedBox(height: 10),
        Center(
          child: Listener(
            onPointerSignal: (e) {
              if (e is PointerScrollEvent) {
                setState(() => _zoom = (_zoom * (e.scrollDelta.dy > 0 ? 0.92 : 1.08))
                    .clamp(1.0, 8.0));
                _refreshFace();
              }
            },
            child: GestureDetector(
              onScaleStart: (_) => _startZoom = _zoom,
              onScaleUpdate: (d) => setState(() {
                _zoom = (_startZoom * d.scale).clamp(1.0, 8.0);
                _offset += d.focalPointDelta;
              }),
              onScaleEnd: (_) => _refreshFace(),
              child: SizedBox(
                width: _viewport,
                height: _viewport,
                child: CustomPaint(painter: _CropPainter(photo: photo, crop: _crop)),
              ),
            ),
          ),
        ),
        Row(
          children: [
            const Icon(Icons.zoom_out, size: 20),
            Expanded(
              child: Slider(
                value: _zoom.clamp(1.0, 8.0),
                min: 1,
                max: 8,
                onChanged: (v) => setState(() => _zoom = v),
                onChangeEnd: (_) => _refreshFace(),
              ),
            ),
            const Icon(Icons.zoom_in, size: 20),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _busy ? null : _pickPhoto,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Đổi ảnh khác'),
        ),
        const Divider(height: 28),
        const Text('2. Trang phục',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Center(child: _preview3d()),
        const Center(
          child: Text('Vuốt ngang để xoay xem các góc',
              style: TextStyle(fontSize: 12, color: Colors.white54)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in ChibiOutfit.values)
              ChoiceChip(
                label: Text(kOutfitNames[o]!),
                selected: _outfit == o,
                onSelected: (_) => setState(() {
                  _outfit = o;
                  _rebuildSpec();
                }),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Màu trang phục'),
        const SizedBox(height: 6),
        _colorRow(kOutfitColors, _color, (c) => setState(() {
              _color = c;
              _rebuildSpec();
            })),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text('Màu da (tay, chân)'),
            const Spacer(),
            FilterChip(
              label: const Text('Tự động'),
              selected: _autoSkin,
              onSelected: (v) {
                setState(() => _autoSkin = v);
                _refreshFace();
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        _colorRow(_skinPresets, _autoSkin ? null : _skin, (c) {
          setState(() {
            _autoSkin = false;
            _skin = c;
            _rebuildSpec();
          });
        }),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text('Màu tóc (sau đầu)'),
            const Spacer(),
            FilterChip(
              label: const Text('Tự động'),
              selected: _autoHair,
              onSelected: (v) {
                setState(() => _autoHair = v);
                _refreshFace();
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        _colorRow(_hairPresets, _autoHair ? null : _hair, (c) {
          setState(() {
            _autoHair = false;
            _hair = c;
            _rebuildSpec();
          });
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _preview3d() {
    final spec = _spec;
    if (spec == null) {
      return const SizedBox(
          width: 240, height: 240, child: Center(child: CircularProgressIndicator()));
    }
    return GestureDetector(
      onHorizontalDragStart: (_) => _dragging = true,
      onHorizontalDragUpdate: (d) => setState(() => _dragYaw += d.delta.dx / 60),
      onHorizontalDragEnd: (_) => _dragging = false,
      child: TickBuilder(
        interval: const Duration(milliseconds: 33),
        builder: (_) {
          final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
          final yaw = _dragging ? _dragYaw : _dragYaw + 0.6 * math.sin(t * 0.8);
          return Chibi3DView(
              spec: spec, size: 240, yaw: yaw, hiDetail: true, body: app.defaultBody);
        },
      ),
    );
  }

  Widget _colorRow(List<Color> colors, Color? selected, ValueChanged<Color> onPick) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in colors)
          GestureDetector(
            onTap: () => onPick(c),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == c ? Colors.tealAccent : Colors.white24,
                  width: selected == c ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Vẽ ảnh đầy đủ + phủ tối phần ngoài vòng tròn để người dùng khoanh mặt.
class _CropPainter extends CustomPainter {
  final ui.Image photo;
  final FaceCrop crop;
  _CropPainter({required this.photo, required this.crop});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    final w = photo.width.toDouble();
    final h = photo.height.toDouble();
    final base = crop.viewport / (w < h ? w : h);
    final k = s / crop.viewport;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(c.dx + crop.offset.dx * k, c.dy + crop.offset.dy * k);
    canvas.scale(base * crop.zoom * k);
    canvas.drawImage(photo, Offset(-w / 2, -h / 2), Paint()..filterQuality = FilterQuality.medium);
    canvas.restore();

    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: c, radius: s / 2 - 2));
    canvas.drawPath(mask, Paint()..color = const Color(0xAA000000));
    canvas.drawCircle(
        c,
        s / 2 - 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CropPainter o) => o.photo != photo || o.crop != crop;
}
