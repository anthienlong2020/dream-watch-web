import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../three_d/body_type.dart';
import 'chibi_painter.dart' show ChibiOutfit;

// =====================================================================
// Chibi 3D: nhân vật dựng từ các khối 3D (cầu, ống, nón) vẽ bằng tam giác,
// có ánh sáng và quay được mọi góc. Khuôn mặt người dùng được "dán" lên
// mặt trước của cái đầu. Không cần thư viện 3D ngoài, chạy được cả web.
// =====================================================================

/// Thông tin để dựng một nhân vật Chibi 3D.
class ChibiSpec {
  /// Ảnh khuôn mặt đã khoanh tròn (PNG vuông, mặt nằm trong hình tròn nội tiếp).
  final Uint8List face;
  final ChibiOutfit outfit;
  final Color outfitColor;
  final Color skin;
  final Color hair;

  const ChibiSpec({
    required this.face,
    required this.outfit,
    required this.outfitColor,
    required this.skin,
    required this.hair,
  });

  Map<String, dynamic> toJson() => {
        'face': _b64(face),
        'outfit': outfit.name,
        'outfitColor': outfitColor.toARGB32(),
        'skin': skin.toARGB32(),
        'hair': hair.toARGB32(),
      };

  static ChibiSpec? fromJson(Object? j) {
    if (j is! Map) return null;
    try {
      return ChibiSpec(
        face: _unb64(j['face'] as String),
        outfit: ChibiOutfit.values.firstWhere((o) => o.name == j['outfit'],
            orElse: () => ChibiOutfit.aoThun),
        outfitColor: Color((j['outfitColor'] as num).toInt()),
        skin: Color((j['skin'] as num).toInt()),
        hair: Color((j['hair'] as num).toInt()),
      );
    } catch (_) {
      return null;
    }
  }
}

String _b64(Uint8List b) => base64Encode(b);
Uint8List _unb64(String s) => base64Decode(s);

// ---------------------------------------------------------------------
// Toán vector nhỏ gọn
// ---------------------------------------------------------------------

class V3 {
  final double x, y, z;
  const V3(this.x, this.y, this.z);
  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator -(V3 o) => V3(x - o.x, y - o.y, z - o.z);
  V3 operator *(double k) => V3(x * k, y * k, z * k);
  double dot(V3 o) => x * o.x + y * o.y + z * o.z;
  V3 cross(V3 o) => V3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => math.sqrt(x * x + y * y + z * z);
  V3 get unit {
    final l = length;
    return l == 0 ? this : this * (1 / l);
  }
}

// ---------------------------------------------------------------------
// Lưới tam giác
// ---------------------------------------------------------------------

/// Vật liệu = một ô màu trong ảnh "atlas" (trừ mặt dùng ảnh khuôn mặt).
enum Mat { face, skin, hair, outfit, outfitDark, outfitLight, pants, shoe, white, spike }

class MeshVert {
  final V3 p;
  final V3 n;
  final Offset uv; // chỉ dùng cho mặt
  const MeshVert(this.p, this.n, this.uv);
}

class MeshTri {
  final int a, b, c;
  final Mat mat;
  final int part; // mỗi khối (đầu, tay, chân...) là một "phần"
  const MeshTri(this.a, this.b, this.c, this.mat, this.part);
}

class ChibiMesh {
  final List<MeshVert> verts = [];
  final List<MeshTri> tris = [];

  /// Độ ưu tiên vẽ của từng phần (cộng vào độ sâu khi sắp xếp).
  final List<double> partBias = [];
  int _part = -1;

  /// Bắt đầu một phần mới. Các khối gắn với đầu dùng [bias] lớn để luôn
  /// vẽ đè lên thân khi nhìn từ phía trước.
  void part([double bias = 0]) {
    partBias.add(bias);
    _part = partBias.length - 1;
  }

  int _add(V3 p, V3 n, [Offset uv = Offset.zero]) {
    verts.add(MeshVert(p, n, uv));
    return verts.length - 1;
  }

  /// Khối elip. [phiFrom]/[phiTo]: dải góc quanh trục đứng (0 = hướng ra trước).
  /// [faceFront]: dán khuôn mặt lên nửa trước (dùng cho đầu).
  void ellipsoid(V3 c, V3 r, Mat mat,
      {int seg = 16, int rings = 10, double phiFrom = -math.pi, double phiTo = math.pi,
      bool faceFront = false, Mat backMat = Mat.hair}) {
    final base = verts.length;
    for (var i = 0; i <= rings; i++) {
      final th = math.pi * i / rings;
      for (var j = 0; j <= seg; j++) {
        final ph = phiFrom + (phiTo - phiFrom) * j / seg;
        final ux = math.sin(th) * math.sin(ph);
        final uy = math.cos(th);
        final uz = math.sin(th) * math.cos(ph);
        final p = V3(c.x + r.x * ux, c.y + r.y * uy, c.z + r.z * uz);
        final n = V3(ux / r.x, uy / r.y, uz / r.z).unit;
        // Chiếu thẳng từ phía trước để lấy toạ độ trên ảnh khuôn mặt (0..256)
        // Ảnh mặt chiếm khoảng 85% phần nhìn thấy phía trước; phần ngoài vòng
        // tròn của ảnh là màu tóc, nên mép mặt - tóc luôn tròn mượt.
        final uv = Offset(160 + ux * 128 * 1.18, 160 - uy * 128 * 1.18);
        _add(p, n, uv);
      }
    }
    final row = seg + 1;
    for (var i = 0; i < rings; i++) {
      for (var j = 0; j < seg; j++) {
        final a = base + i * row + j;
        final b = a + 1;
        final c2 = a + row;
        final d = c2 + 1;
        Mat m1 = mat, m2 = mat;
        if (faceFront) {
          bool front(int k) => _localZ(verts[k].p, c, r) > -0.02;
          m1 = (front(a) && front(c2) && front(b)) ? Mat.face : backMat;
          m2 = (front(b) && front(c2) && front(d)) ? Mat.face : backMat;
        }
        tris.add(MeshTri(a, c2, b, m1, _part));
        tris.add(MeshTri(b, c2, d, m2, _part));
      }
    }
  }

  static double _localZ(V3 p, V3 c, V3 r) => (p.z - c.z) / r.z;

  /// Ống tròn từ [a] tới [b], bán kính [ra] ở đầu a và [rb] ở đầu b (nón khi rb = 0).
  void tube(V3 a, V3 b, double ra, double rb, Mat mat, {int seg = 12, bool capA = true, bool capB = true}) {
    final w = (b - a).unit;
    final helper = w.y.abs() < 0.9 ? const V3(0, 1, 0) : const V3(1, 0, 0);
    final u = w.cross(helper).unit;
    final v = w.cross(u).unit;
    final len = (b - a).length;
    final slope = (ra - rb) / (len == 0 ? 1 : len);
    final base = verts.length;
    for (var j = 0; j <= seg; j++) {
      final t = 2 * math.pi * j / seg;
      final dir = u * math.cos(t) + v * math.sin(t);
      final n = (dir + w * slope).unit;
      _add(a + dir * ra, n);
      _add(b + dir * rb, n);
    }
    for (var j = 0; j < seg; j++) {
      final i0 = base + j * 2;
      tris.add(MeshTri(i0, i0 + 2, i0 + 1, mat, _part));
      tris.add(MeshTri(i0 + 1, i0 + 2, i0 + 3, mat, _part));
    }
    if (capA && ra > 0) ellipsoid(a, V3(ra, ra, ra), mat, seg: seg, rings: 6);
    if (capB && rb > 0) ellipsoid(b, V3(rb, rb, rb), mat, seg: seg, rings: 6);
  }
}

/// Dựng nhân vật. [lod]: 1 = mịn (ảnh to ở giữa), 0 = gọn (ảnh nhỏ quanh vòng).
/// [body]: dáng ốm / cân đối / mập.
ChibiMesh buildChibiMesh(ChibiOutfit outfit, {int lod = 1, BodyType body = BodyType.canDoi}) {
  final m = ChibiMesh();
  final hs = lod == 1 ? 28 : 18; // độ mịn của đầu
  final hr = lod == 1 ? 18 : 12;
  final ps = lod == 1 ? 14 : 10; // độ mịn các phần khác
  const pr = 8;
  const headBias = 0.8;

  final sh = kChibiShapes[body]!;
  final t = sh.torso, l = sh.limb;
  final dy = 0.26 * (sh.legLen - 1); // chân dài/ngắn hơn thì đẩy phần trên lên/xuống
  V3 up(double x, double y, double z) => V3(x, y + dy, z);
  final legX = 0.17 * math.min(t, 1.25);

  // Chân + giày
  for (final s in [-1.0, 1.0]) {
    m.part();
    m.tube(up(legX * s, 0.4, 0), V3(legX * s, 0.14, 0.02), 0.13 * l, 0.12 * l,
        outfit == ChibiOutfit.vay ? Mat.skin : (outfit == ChibiOutfit.khungLong ? Mat.outfit : Mat.pants),
        seg: ps, capA: false, capB: false);
    m.part();
    final shoe = 0.8 + 0.2 * l;
    m.ellipsoid(V3((legX + 0.01) * s, 0.08, 0.07), V3(0.15 * shoe, 0.09, 0.21 * shoe),
        outfit == ChibiOutfit.khungLong ? Mat.outfitDark : Mat.shoe,
        seg: ps, rings: pr);
  }

  // Thân
  switch (outfit) {
    case ChibiOutfit.vay:
      m.part();
      m.tube(up(0, 0.95, 0), up(0, 0.3, 0), 0.3 * t, 0.52 * t, Mat.outfit, seg: ps + 4, capA: true, capB: false);
      m.part();
      m.ellipsoid(up(0, 0.3, 0), V3(0.52 * t, 0.04, 0.52 * t), Mat.outfitDark, seg: ps + 4, rings: 4);
      break;
    case ChibiOutfit.vest:
      m.part();
      m.ellipsoid(up(0, 0.42, 0), V3(0.36 * t, 0.14, 0.31 * t), Mat.pants, seg: ps, rings: pr);
      m.part();
      m.tube(up(0, 0.55, 0), up(0, 0.88, 0), 0.37 * t, 0.32 * t, Mat.outfit, seg: ps);
      m.part(0.05);
      m.ellipsoid(up(0, 0.86, 0.2 * t), const V3(0.17, 0.2, 0.15), Mat.white, seg: ps, rings: pr);
      m.part(0.1);
      m.ellipsoid(up(0, 0.76, 0.33 * t), const V3(0.05, 0.16, 0.04), Mat.outfitLight, seg: 8, rings: 6);
      break;
    case ChibiOutfit.khungLong:
      m.part();
      m.tube(up(0, 0.48, 0), up(0, 0.88, 0), 0.38 * t, 0.33 * t, Mat.outfit, seg: ps);
      m.part(0.05);
      m.ellipsoid(up(0, 0.66, 0.24 * t), V3(0.25 * t, 0.28, 0.15), Mat.outfitLight, seg: ps, rings: pr);
      m.part();
      m.tube(up(0, 0.48, -0.25 * t), up(0, 0.12, -0.95 * t), 0.24 * t, 0.0, Mat.outfit, seg: ps, capB: false);
      break;
    case ChibiOutfit.aoThun:
      m.part();
      m.ellipsoid(up(0, 0.42, 0), V3(0.36 * t, 0.14, 0.31 * t), Mat.pants, seg: ps, rings: pr);
      m.part();
      m.tube(up(0, 0.55, 0), up(0, 0.88, 0), 0.37 * t, 0.32 * t, Mat.outfit, seg: ps);
      m.part(0.05);
      m.ellipsoid(up(0, 0.7, 0.3 * t), const V3(0.11, 0.11, 0.07), Mat.outfitLight, seg: 10, rings: 6);
      break;
  }

  // Tay
  final sleeve = outfit == ChibiOutfit.vay ? Mat.skin : Mat.outfit;
  final shoulderX = 0.32 * t;
  for (final s in [-1.0, 1.0]) {
    m.part();
    m.tube(up(shoulderX * s, 0.86, 0), up((shoulderX + 0.28) * s, 0.55, 0.1), 0.11 * l, 0.1 * l,
        sleeve, seg: ps, capB: false);
    m.part();
    m.ellipsoid(up((shoulderX + 0.3) * s, 0.52, 0.11), V3(0.13 * l, 0.13 * l, 0.13 * l), Mat.skin,
        seg: ps, rings: pr);
  }

  // Cổ
  m.part();
  m.tube(up(0, 0.84, 0), up(0, 1.0, 0), 0.13 * l, 0.13 * l, Mat.skin, seg: ps, capA: false, capB: false);

  // Đầu (mặt trước dán ảnh khuôn mặt, phần còn lại màu tóc)
  final headC = up(0, 1.66, 0);
  const headR = V3(0.9, 0.84, 0.84);
  m.part(headBias);
  m.ellipsoid(headC, headR, Mat.hair, seg: hs, rings: hr, faceFront: true);

  // Mũ trùm khủng long: chỉ nửa sau đầu (để lộ mặt) + gai
  if (outfit == ChibiOutfit.khungLong) {
    m.part(headBias);
    m.ellipsoid(headC + const V3(0, 0.03, -0.07), headR * 1.06, Mat.outfit,
        seg: hs, rings: hr, phiFrom: math.pi * 0.5, phiTo: math.pi * 1.5);
    for (var k = 0; k < 6; k++) {
      final th = 0.1 + k * 0.3; // từ đỉnh đầu ra sau gáy
      final dir = V3(0, math.cos(th), -math.sin(th));
      final basePt = headC + V3(0, dir.y * headR.y * 1.04, dir.z * headR.z * 1.04 - 0.07);
      m.part(headBias);
      m.tube(basePt, basePt + dir * 0.3, 0.13, 0.0, Mat.spike, seg: 8, capA: false, capB: false);
    }
  }
  return m;
}

// ---------------------------------------------------------------------
// Ảnh atlas: ô trái 320x320 (khuôn mặt 256 ở giữa, viền màu tóc),
// bên phải là các ô màu
// ---------------------------------------------------------------------

const double _sw = 64; // cạnh mỗi ô màu

Offset _swatchCenter(Mat m) {
  final i = m.index - 1; // Mat.face = 0 không có ô màu
  return Offset(320 + (i % 4) * _sw + _sw / 2, (i ~/ 4) * _sw + _sw / 2);
}

Future<ui.Image> buildAtlas(ChibiSpec spec) async {
  final codec = await ui.instantiateImageCodec(spec.face);
  final face = (await codec.getNextFrame()).image;

  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  // Nền ô mặt = màu tóc (viền ngoài vòng tròn của ảnh mặt)
  canvas.drawRect(const Rect.fromLTWH(0, 0, 320, 320), Paint()..color = spec.hair);
  canvas.save();
  canvas.clipPath(Path()..addOval(const Rect.fromLTWH(32, 32, 256, 256)));
  canvas.drawImageRect(
    face,
    Rect.fromLTWH(0, 0, face.width.toDouble(), face.height.toDouble()),
    const Rect.fromLTWH(32, 32, 256, 256),
    Paint()..filterQuality = FilterQuality.medium,
  );
  canvas.restore();
  face.dispose();

  final c = spec.outfitColor;
  final colors = <Mat, Color>{
    Mat.skin: spec.skin,
    Mat.hair: spec.hair,
    Mat.outfit: c,
    Mat.outfitDark: Color.lerp(c, Colors.black, 0.3)!,
    Mat.outfitLight: Color.lerp(c, Colors.white, 0.55)!,
    Mat.pants: const Color(0xFF3949AB),
    Mat.shoe: const Color(0xFF5D4037),
    Mat.white: const Color(0xFFF5F5F5),
    Mat.spike: Color.lerp(c, const Color(0xFFFFEB3B), 0.45)!,
  };
  if (spec.outfit == ChibiOutfit.vest) {
    colors[Mat.outfit] = const Color(0xFF263238);
    colors[Mat.pants] = const Color(0xFF263238);
    colors[Mat.outfitLight] = c; // cà vạt màu đã chọn
  }
  colors.forEach((m, col) {
    final ctr = _swatchCenter(m);
    canvas.drawRect(Rect.fromCenter(center: ctr, width: _sw, height: _sw), Paint()..color = col);
  });
  final pic = rec.endRecording();
  return pic.toImage(576, 320);
}

// ---------------------------------------------------------------------
// Vẽ: xoay, chiếu phối cảnh, chiếu sáng, sắp xếp xa -> gần
// ---------------------------------------------------------------------

const V3 _light = V3(-0.45, 0.65, 0.62);

void paintChibi3D(Canvas canvas, Size size, ChibiMesh mesh, ui.Image atlas,
    {double yaw = 0, double pitch = 0.12}) {
  final s = math.min(size.width, size.height);
  final scale = s / 2.75;
  final cx = size.width / 2;
  final cy = size.height / 2;
  const centerY = 1.25;
  const camDist = 7.0;
  final light = _light.unit;

  final cyw = math.cos(yaw), syw = math.sin(yaw);
  final cp = math.cos(pitch), sp = math.sin(pitch);
  V3 rot(V3 v) {
    // quay quanh trục Y (yaw) rồi trục X (pitch: nhìn hơi từ trên xuống)
    final x1 = v.x * cyw + v.z * syw;
    final z1 = -v.x * syw + v.z * cyw;
    final y2 = v.y * cp - z1 * sp;
    final z2 = v.y * sp + z1 * cp;
    return V3(x1, y2, z2);
  }

  final n = mesh.verts.length;
  final pos = List<V3>.filled(n, const V3(0, 0, 0));
  final nrm = List<V3>.filled(n, const V3(0, 0, 0));
  final scr = List<Offset>.filled(n, Offset.zero);
  for (var i = 0; i < n; i++) {
    final v = mesh.verts[i];
    final p = rot(v.p - const V3(0, centerY, 0));
    pos[i] = p;
    nrm[i] = rot(v.n);
    final k = camDist / (camDist - p.z);
    scr[i] = Offset(cx + p.x * scale * k, cy - p.y * scale * k);
  }

  // Độ sâu trung bình của từng phần (mỗi phần là một khối lồi, nên vẽ
  // cả phần theo thứ tự xa -> gần là đủ, không bị răng cưa ở chỗ giao nhau).
  final parts = mesh.partBias.length;
  final pz = List<double>.filled(parts, 0);
  final pc = List<int>.filled(parts, 0);
  for (final tr in mesh.tris) {
    pz[tr.part] += pos[tr.a].z;
    pc[tr.part]++;
  }
  for (var i = 0; i < parts; i++) {
    pz[i] = (pc[i] == 0 ? 0 : pz[i] / pc[i]) + mesh.partBias[i];
  }

  // Lọc mặt khuất (quay lưng lại người xem)
  final visible = <int>[];
  for (var t = 0; t < mesh.tris.length; t++) {
    final tr = mesh.tris[t];
    final a = scr[tr.a], b = scr[tr.b], c = scr[tr.c];
    final area = (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
    if (area >= 0) continue;
    visible.add(t);
  }
  visible.sort((p, q) => pz[mesh.tris[p].part].compareTo(pz[mesh.tris[q].part]));

  final count = visible.length * 3;
  final positions = Float32List(count * 2);
  final uvs = Float32List(count * 2);
  final colors = Int32List(count);
  var o = 0;
  for (final t in visible) {
    final tr = mesh.tris[t];
    for (final vi in [tr.a, tr.b, tr.c]) {
      final sp2 = scr[vi];
      positions[o * 2] = sp2.dx;
      positions[o * 2 + 1] = sp2.dy;
      final Offset uv = tr.mat == Mat.face ? mesh.verts[vi].uv : _swatchCenter(tr.mat);
      uvs[o * 2] = uv.dx;
      uvs[o * 2 + 1] = uv.dy;
      final diff = math.max(0.0, nrm[vi].dot(light));
      final rim = math.pow(1 - math.max(0.0, nrm[vi].z), 3).toDouble() * 0.18;
      final lit = tr.mat == Mat.face
          ? (0.78 + 0.25 * diff)
          : (0.42 + 0.62 * diff + rim);
      final g = (lit.clamp(0.0, 1.0) * 255).round();
      colors[o] = (0xFF << 24) | (g << 16) | (g << 8) | g;
      o++;
    }
  }

  final vertices = ui.Vertices.raw(
    ui.VertexMode.triangles,
    positions,
    textureCoordinates: uvs,
    colors: colors,
  );
  final paint = Paint()
    ..shader = ui.ImageShader(atlas, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage)
    ..filterQuality = FilterQuality.medium;

  // Bóng dưới chân
  canvas.drawOval(
    Rect.fromCenter(
        center: Offset(cx, cy + (centerY - 0.02) * scale * cp),
        width: s * 0.42,
        height: s * 0.07),
    Paint()..color = const Color(0x40000000),
  );
  canvas.drawVertices(vertices, BlendMode.modulate, paint);
}

// ---------------------------------------------------------------------
// Bộ nhớ đệm: mỗi nhân vật chỉ dựng lưới + atlas một lần
// ---------------------------------------------------------------------

class _Built {
  final ChibiMesh hi;
  final ChibiMesh lo;
  final ui.Image atlas;
  _Built(this.hi, this.lo, this.atlas);
}

final Map<(ChibiSpec, BodyType), Future<_Built>> _cache = {};

Future<_Built> _build(ChibiSpec spec, BodyType body) {
  final key = (spec, body);
  if (!_cache.containsKey(key) && _cache.length > 40) {
    _cache.remove(_cache.keys.first); // giới hạn bộ nhớ đệm
  }
  return _cache.putIfAbsent(key, () async {
    final atlas = await buildAtlas(spec);
    return _Built(buildChibiMesh(spec.outfit, lod: 1, body: body),
        buildChibiMesh(spec.outfit, lod: 0, body: body), atlas);
  });
}

/// Hiển thị Chibi 3D ở góc quay [yaw] (radian).
class Chibi3DView extends StatefulWidget {
  final ChibiSpec spec;
  final double yaw;
  final double size;
  final bool hiDetail;
  final BodyType body;

  const Chibi3DView({
    super.key,
    required this.spec,
    required this.size,
    this.yaw = 0,
    this.hiDetail = true,
    this.body = BodyType.canDoi,
  });

  @override
  State<Chibi3DView> createState() => _Chibi3DViewState();
}

class _Chibi3DViewState extends State<Chibi3DView> {
  _Built? _built;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant Chibi3DView old) {
    super.didUpdateWidget(old);
    if (!identical(old.spec, widget.spec) || old.body != widget.body) _load();
  }

  void _load() {
    final spec = widget.spec;
    final body = widget.body;
    _build(spec, body).then((b) {
      if (mounted && identical(spec, widget.spec) && body == widget.body) {
        setState(() => _built = b);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = _built;
    if (b == null) return SizedBox(width: widget.size, height: widget.size);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        child: CustomPaint(
        painter: _Chibi3DPainter(
          mesh: widget.hiDetail ? b.hi : b.lo,
          atlas: b.atlas,
          yaw: widget.yaw,
        ),
      ),
      ),
    );
  }
}

class _Chibi3DPainter extends CustomPainter {
  final ChibiMesh mesh;
  final ui.Image atlas;
  final double yaw;
  _Chibi3DPainter({required this.mesh, required this.atlas, required this.yaw});

  @override
  void paint(Canvas canvas, Size size) =>
      paintChibi3D(canvas, size, mesh, atlas, yaw: yaw);

  @override
  bool shouldRepaint(covariant _Chibi3DPainter o) =>
      o.yaw != yaw || o.mesh != mesh || o.atlas != atlas;
}
