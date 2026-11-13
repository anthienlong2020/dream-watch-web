import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'body_type.dart';

// =====================================================================
// "Thổi phồng" ảnh phẳng thành khối 3D (kiểu thú bông nhồi bông).
//
// Dựa vào đường viền (phần không trong suốt) của ảnh: chỗ càng xa mép thì
// càng dày, mép mỏng dần về 0. Mặt trước là ảnh gốc, mặt sau là ảnh lật lại
// (tối hơn một chút). Vẽ bằng tam giác có ánh sáng, quay được mọi góc.
// Ảnh không có nền trong suốt sẽ thành một "tấm thiệp phồng".
// =====================================================================

class InflatedMesh {
  final Float32List pos; // x,y,z
  final Float32List nrm; // nx,ny,nz
  final Float32List uv; // u,v (pixel trên ảnh texture)
  final Uint32List tris; // a,b,c
  final Uint8List back; // 1 = tam giác mặt sau
  /// Kiểu phù điêu kim loại: có ánh loé (specular) khi xoay.
  final bool metallic;
  InflatedMesh(this.pos, this.nrm, this.uv, this.tris, this.back, {this.metallic = false});

  int get vertexCount => pos.length ~/ 3;
  int get triCount => tris.length ~/ 3;
}

class InflatedModel {
  final InflatedMesh mesh;
  final ui.Image texture;
  InflatedModel(this.mesh, this.texture);
}

/// Dựng lưới từ ảnh. [grid]: số ô theo cạnh dài (càng lớn càng mịn).
/// [relief]: kiểu phù điêu — khối mỏng hơn, chỗ sáng trên ảnh nổi cao lên,
/// hợp với biểu tượng / huy hiệu / tượng kim loại.
Future<InflatedModel> buildInflated(Uint8List bytes,
    {int grid = 40, BodyType body = BodyType.canDoi, bool relief = false}) async {
  final base = kInflateShapes[body]!;
  final shape = relief
      ? InflateShape(base.thick * 0.38, 0.6, base.scaleX, base.scaleY)
      : base;
  // Ảnh texture: thu nhỏ còn tối đa 512px cho nhẹ
  final probe = await ui.instantiateImageCodec(bytes);
  final first = (await probe.getNextFrame()).image;
  final w0 = first.width, h0 = first.height;
  ui.Image tex = first;
  if (math.max(w0, h0) > 512) {
    first.dispose();
    final k = 512 / math.max(w0, h0);
    final c2 = await ui.instantiateImageCodec(bytes,
        targetWidth: math.max(1, (w0 * k).round()),
        targetHeight: math.max(1, (h0 * k).round()));
    tex = (await c2.getNextFrame()).image;
  }
  final tw = tex.width, th = tex.height;

  // Lưới phân tích
  final gx = tw >= th ? grid : math.max(4, (grid * tw / th).round());
  final gy = th >= tw ? grid : math.max(4, (grid * th / tw).round());
  final rgba = (await tex.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!;

  // Lấp phần trong suốt bằng màu của hình ở sát mép (màu da con vật),
  // để không bao giờ lộ "vết đen" khi trình duyệt vẽ phần trong suốt.
  final padded = await _padTransparent(rgba, tw, th);
  tex.dispose();
  tex = padded;

  // Ô nào "có hình": lấy mẫu vài điểm trong ô, đủ đậm thì tính là có
  final inside = Uint8List(gx * gy);
  var anyTransparent = false;
  for (var j = 0; j < gy; j++) {
    for (var i = 0; i < gx; i++) {
      var opaque = 0;
      for (final fy in const [0.05, 0.35, 0.65, 0.95]) {
        for (final fx in const [0.05, 0.35, 0.65, 0.95]) {
          final px = ((i + fx) / gx * tw).floor().clamp(0, tw - 1);
          final py = ((j + fy) / gy * th).floor().clamp(0, th - 1);
          final a = rgba.getUint8((py * tw + px) * 4 + 3);
          if (a > 110) opaque++;
          if (a < 40) anyTransparent = true;
        }
      }
      // Ô có khoảng 1/3 diện tích là hình thì tính là "có hình".
      inside[j * gx + i] = opaque >= 5 ? 1 : 0;
    }
  }
  if (!anyTransparent) {
    // Ảnh không có nền trong suốt: cả tấm là "có hình"
    for (var k = 0; k < inside.length; k++) {
      inside[k] = 1;
    }
  }

  // Khoảng cách tới mép (chamfer 3-4, đơn vị ~ ô)
  const big = 1 << 20;
  final dist = Int32List(gx * gy);
  for (var k = 0; k < dist.length; k++) {
    dist[k] = inside[k] == 1 ? big : 0;
  }
  int at(int i, int j) => (i < 0 || j < 0 || i >= gx || j >= gy) ? 0 : dist[j * gx + i];
  for (var j = 0; j < gy; j++) {
    for (var i = 0; i < gx; i++) {
      final k = j * gx + i;
      if (dist[k] == 0) continue;
      var d = dist[k];
      d = math.min(d, at(i - 1, j) + 3);
      d = math.min(d, at(i, j - 1) + 3);
      d = math.min(d, at(i - 1, j - 1) + 4);
      d = math.min(d, at(i + 1, j - 1) + 4);
      dist[k] = d;
    }
  }
  for (var j = gy - 1; j >= 0; j--) {
    for (var i = gx - 1; i >= 0; i--) {
      final k = j * gx + i;
      if (dist[k] == 0) continue;
      var d = dist[k];
      d = math.min(d, at(i + 1, j) + 3);
      d = math.min(d, at(i, j + 1) + 3);
      d = math.min(d, at(i + 1, j + 1) + 4);
      d = math.min(d, at(i - 1, j + 1) + 4);
      dist[k] = d;
    }
  }
  var dmax = 1.0;
  for (final d in dist) {
    if (d > dmax) dmax = d.toDouble();
  }
  dmax /= 3;

  // Độ dày tại mỗi ô theo dáng: mập thì phồng đều tròn trịa, ốm thì mỏng
  double cellH(int i, int j) {
    if (i < 0 || j < 0 || i >= gx || j >= gy) return -1;
    if (inside[j * gx + i] == 0) return -1;
    final x = ((dist[j * gx + i] / 3.0 - 0.5) / dmax).clamp(0.0, 1.0);
    final round = 1 - (1 - x) * (1 - x); // 0 ở mép, 1 ở giữa
    return shape.thick * dmax * math.pow(round, shape.profile).toDouble();
  }

  // Chiều cao tại các đỉnh lưới (góc ô): mép = 0
  final nx = gx + 1, ny = gy + 1;
  final nodeH = Float64List(nx * ny);
  final used = Uint8List(nx * ny);
  for (var j = 0; j < ny; j++) {
    for (var i = 0; i < nx; i++) {
      final hs = [cellH(i - 1, j - 1), cellH(i, j - 1), cellH(i - 1, j), cellH(i, j)];
      if (hs.every((h) => h < 0)) continue;
      used[j * nx + i] = 1;
      nodeH[j * nx + i] = hs.any((h) => h < 0) ? 0 : (hs.reduce((a, b) => a + b) / 4);
    }
  }

  // Làm mềm bề mặt (hết nếp nhăn kiểu giấy vò): mỗi đỉnh bên trong lấy
  // trung bình với các đỉnh xung quanh vài lần, mép vẫn giữ bằng 0.
  for (var pass = 0; pass < 6; pass++) {
    final old = Float64List.fromList(nodeH);
    for (var j = 1; j < ny - 1; j++) {
      for (var i = 1; i < nx - 1; i++) {
        final k = j * nx + i;
        if (used[k] == 0 || old[k] == 0) continue;
        var sum = 0.0;
        var c = 0;
        for (final q in [k - 1, k + 1, k - nx, k + nx, k - nx - 1, k - nx + 1, k + nx - 1, k + nx + 1]) {
          if (used[q] == 0) continue;
          sum += old[q];
          c++;
        }
        if (c > 0) nodeH[k] = old[k] * 0.4 + (sum / c) * 0.6;
      }
    }
  }

  // Phù điêu: cộng thêm độ nổi theo độ sáng của ảnh (sáng = nổi cao)
  if (relief) {
    double lumAt(int px, int py) {
      px = px.clamp(0, tw - 1);
      py = py.clamp(0, th - 1);
      final o = (py * tw + px) * 4;
      if (rgba.getUint8(o + 3) < 100) return 0;
      return (0.3 * rgba.getUint8(o) + 0.59 * rgba.getUint8(o + 1) + 0.11 * rgba.getUint8(o + 2)) / 255;
    }
    final detail = Float64List(nx * ny);
    final rx = math.max(1, (tw / gx / 2).round()), ry = math.max(1, (th / gy / 2).round());
    for (var j = 0; j < ny; j++) {
      for (var i = 0; i < nx; i++) {
        final k = j * nx + i;
        if (used[k] == 0 || nodeH[k] == 0) continue;
        final px = (i / gx * tw).round(), py = (j / gy * th).round();
        var sum = 0.0;
        var c = 0;
        for (final dy in [-ry, 0, ry]) {
          for (final dx in [-rx, 0, rx]) {
            sum += lumAt(px + dx, py + dy);
            c++;
          }
        }
        detail[k] = sum / c;
      }
    }
    final amount = 3.2 * (gx > gy ? gx : gy) / 60; // ~ độ nổi tối đa (đơn vị ô)
    for (var k = 0; k < nodeH.length; k++) {
      if (nodeH[k] > 0) nodeH[k] += detail[k] * amount;
    }
  }

  // Làm mượt đường viền: các đỉnh ở mép được kéo về trung bình với
  // các đỉnh mép bên cạnh, để viền không bị bậc thang theo ô lưới.
  final nodeX = Float64List(nx * ny), nodeY = Float64List(nx * ny);
  for (var j = 0; j < ny; j++) {
    for (var i = 0; i < nx; i++) {
      nodeX[j * nx + i] = i.toDouble();
      nodeY[j * nx + i] = j.toDouble();
    }
  }
  bool isEdge(int i, int j) =>
      i >= 0 && j >= 0 && i < nx && j < ny && used[j * nx + i] == 1 && nodeH[j * nx + i] == 0;
  for (var pass = 0; pass < 3; pass++) {
    final ox = Float64List.fromList(nodeX), oy = Float64List.fromList(nodeY);
    for (var j = 0; j < ny; j++) {
      for (var i = 0; i < nx; i++) {
        if (!isEdge(i, j)) continue;
        var sx = 0.0, sy = 0.0, c = 0;
        for (var dj = -1; dj <= 1; dj++) {
          for (var di = -1; di <= 1; di++) {
            if ((di == 0 && dj == 0) || !isEdge(i + di, j + dj)) continue;
            sx += ox[(j + dj) * nx + i + di];
            sy += oy[(j + dj) * nx + i + di];
            c++;
          }
        }
        if (c < 2) continue;
        final k = j * nx + i;
        nodeX[k] = ox[k] * 0.5 + (sx / c) * 0.5;
        nodeY[k] = oy[k] * 0.5 + (sy / c) * 0.5;
      }
    }
  }

  // Quy đổi sang toạ độ mô hình: cạnh dài = 2 đơn vị, tâm ở gốc
  final cs = 2.0 / math.max(gx, gy);
  double hAt(int i, int j) {
    if (i < 0 || j < 0 || i >= nx || j >= ny) return 0;
    return nodeH[j * nx + i];
  }

  final pos = <double>[];
  final nrm = <double>[];
  final uvs = <double>[];
  final idxFront = Int32List(nx * ny)..fillRange(0, nx * ny, -1);
  final idxBack = Int32List(nx * ny)..fillRange(0, nx * ny, -1);
  var count = 0;
  for (var j = 0; j < ny; j++) {
    for (var i = 0; i < nx; i++) {
      if (used[j * nx + i] == 0) continue;
      final gxp = nodeX[j * nx + i], gyp = nodeY[j * nx + i];
      final x = (gxp - gx / 2) * cs * shape.scaleX;
      final y = -(gyp - gy / 2) * cs * shape.scaleY;
      final h = nodeH[j * nx + i] * cs;
      final hx = (hAt(i + 1, j) - hAt(i - 1, j)) / 2; // theo ô
      final hy = (hAt(i, j - 1) - hAt(i, j + 1)) / 2; // y hướng lên
      final u = gxp / gx * tw, v = gyp / gy * th;
      for (final side in const [1.0, -1.0]) {
        var nX = -hx * side, nY = -hy * side, nZ = side;
        final l = math.sqrt(nX * nX + nY * nY + nZ * nZ);
        nX /= l;
        nY /= l;
        nZ /= l;
        pos.addAll([x, y, h * side]);
        nrm.addAll([nX, nY, nZ]);
        uvs.addAll([u, v]);
        if (side > 0) {
          idxFront[j * nx + i] = count;
        } else {
          idxBack[j * nx + i] = count;
        }
        count++;
      }
    }
  }

  final tris = <int>[];
  final back = <int>[];
  for (var j = 0; j < gy; j++) {
    for (var i = 0; i < gx; i++) {
      if (inside[j * gx + i] == 0) continue;
      final a = j * nx + i, b = a + 1, c = a + nx, d = c + 1;
      // mặt trước (nhìn từ +z ngược chiều kim đồng hồ)
      tris.addAll([idxFront[a], idxFront[c], idxFront[b]]);
      tris.addAll([idxFront[b], idxFront[c], idxFront[d]]);
      back.addAll([0, 0]);
      // mặt sau
      tris.addAll([idxBack[a], idxBack[b], idxBack[c]]);
      tris.addAll([idxBack[b], idxBack[d], idxBack[c]]);
      back.addAll([1, 1]);
    }
  }

  return InflatedModel(
    InflatedMesh(Float32List.fromList(pos), Float32List.fromList(nrm),
        Float32List.fromList(uvs), Uint32List.fromList(tris), Uint8List.fromList(back),
        metallic: relief),
    tex,
  );
}

/// Tô màu cho các điểm ảnh trong suốt bằng màu của điểm có hình gần nhất
/// (loang dần từ mép ra ngoài), rồi làm ảnh đặc hoàn toàn.
Future<ui.Image> _padTransparent(ByteData src, int w, int h) async {
  final n = w * h;
  final out = Uint8List(n * 4);
  final filled = Uint8List(n);
  final queue = Int32List(n);
  var head = 0, tail = 0;
  for (var k = 0; k < n; k++) {
    final a = src.getUint8(k * 4 + 3);
    if (a >= 128) {
      out[k * 4] = src.getUint8(k * 4);
      out[k * 4 + 1] = src.getUint8(k * 4 + 1);
      out[k * 4 + 2] = src.getUint8(k * 4 + 2);
      out[k * 4 + 3] = 255;
      filled[k] = 1;
      queue[tail++] = k;
    }
  }
  if (tail == 0) {
    // Ảnh trong suốt hoàn toàn: tô xám
    for (var k = 0; k < n; k++) {
      out[k * 4] = out[k * 4 + 1] = out[k * 4 + 2] = 128;
      out[k * 4 + 3] = 255;
    }
  }
  while (head < tail) {
    final k = queue[head++];
    final x = k % w, y = k ~/ w;
    for (var d = 0; d < 4; d++) {
      final nx2 = x + (d == 0 ? 1 : d == 1 ? -1 : 0);
      final ny2 = y + (d == 2 ? 1 : d == 3 ? -1 : 0);
      if (nx2 < 0 || ny2 < 0 || nx2 >= w || ny2 >= h) continue;
      final q = ny2 * w + nx2;
      if (filled[q] == 1) continue;
      filled[q] = 1;
      out[q * 4] = out[k * 4];
      out[q * 4 + 1] = out[k * 4 + 1];
      out[q * 4 + 2] = out[k * 4 + 2];
      out[q * 4 + 3] = 255;
      queue[tail++] = q;
    }
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(out);
  final desc = ui.ImageDescriptor.raw(buffer,
      width: w, height: h, pixelFormat: ui.PixelFormat.rgba8888);
  final codec = await desc.instantiateCodec();
  final img = (await codec.getNextFrame()).image;
  desc.dispose();
  buffer.dispose();
  return img;
}

/// Vẽ khối phồng ở góc [yaw], vừa khung [size].
void paintInflated(Canvas canvas, Size size, InflatedModel model,
    {double yaw = 0, double pitch = 0.06}) {
  final m = model.mesh;
  final s = math.min(size.width, size.height);
  final scale = s / 2.1;
  final cx = size.width / 2, cy = size.height / 2;
  const camDist = 7.0;
  final cyw = math.cos(yaw), syw = math.sin(yaw);
  final cp = math.cos(pitch), sp = math.sin(pitch);
  // ánh sáng từ trên-trái-trước
  const lx = -0.45, ly = 0.6, lz = 0.66;
  final ll = math.sqrt(lx * lx + ly * ly + lz * lz);

  final n = m.vertexCount;
  final sx = Float32List(n), sy = Float32List(n), sz = Float32List(n);
  final lit = Float32List(n);
  final nzv = Float32List(n);
  for (var i = 0; i < n; i++) {
    final x = m.pos[i * 3], y = m.pos[i * 3 + 1], z = m.pos[i * 3 + 2];
    final x1 = x * cyw + z * syw;
    final z1 = -x * syw + z * cyw;
    final y2 = y * cp - z1 * sp;
    final z2 = y * sp + z1 * cp;
    final k = camDist / (camDist - z2);
    sx[i] = cx + x1 * scale * k;
    sy[i] = cy - y2 * scale * k;
    sz[i] = z2;
    final ax = m.nrm[i * 3], ay = m.nrm[i * 3 + 1], az = m.nrm[i * 3 + 2];
    final nx1 = ax * cyw + az * syw;
    final nz1 = -ax * syw + az * cyw;
    final ny2 = ay * cp - nz1 * sp;
    final nz2 = ay * sp + nz1 * cp;
    final diff = math.max(0.0, (nx1 * lx + ny2 * ly + nz2 * lz) / ll);
    lit[i] = diff;
    nzv[i] = nz2;
  }

  final tc = m.triCount;
  final vis = <int>[];
  final depth = Float32List(tc);
  for (var t = 0; t < tc; t++) {
    final a = m.tris[t * 3], b = m.tris[t * 3 + 1], c = m.tris[t * 3 + 2];
    final area = (sx[b] - sx[a]) * (sy[c] - sy[a]) - (sy[b] - sy[a]) * (sx[c] - sx[a]);
    if (area >= 0) continue;
    depth[t] = sz[a] + sz[b] + sz[c];
    vis.add(t);
  }
  vis.sort((p, q) => depth[p].compareTo(depth[q]));

  final cnt = vis.length * 3;
  final positions = Float32List(cnt * 2);
  final uvs = Float32List(cnt * 2);
  final colors = Int32List(cnt);
  var o = 0;
  for (final t in vis) {
    final isBack = m.back[t] == 1;
    for (var e = 0; e < 3; e++) {
      final vi = m.tris[t * 3 + e];
      positions[o * 2] = sx[vi];
      positions[o * 2 + 1] = sy[vi];
      uvs[o * 2] = m.uv[vi * 2];
      uvs[o * 2 + 1] = m.uv[vi * 2 + 1];
      final rim = math.pow(1 - nzv[vi].abs(), 3).toDouble() * 0.15;
      var l = m.metallic ? 0.5 + 0.62 * lit[vi] + rim : 0.72 + 0.36 * lit[vi] + rim;
      if (isBack) l *= 0.86;
      final g = (l.clamp(0.0, 1.0) * 255).round();
      colors[o] = (0xFF << 24) | (g << 16) | (g << 8) | g;
      o++;
    }
  }
  final vertices = ui.Vertices.raw(ui.VertexMode.triangles, positions,
      textureCoordinates: uvs, colors: colors);
  final paint = Paint()
    ..shader = ui.ImageShader(
        model.texture, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage)
    ..filterQuality = FilterQuality.medium;
  canvas.drawVertices(vertices, BlendMode.modulate, paint);

  // Kim loại: thêm lớp ánh loé (cộng sáng) theo hướng phản chiếu ánh sáng
  if (m.metallic) {
    final hx = lx / ll, hy = ly / ll, hz = lz / ll + 1;
    final hl = math.sqrt(hx * hx + hy * hy + hz * hz);
    final spec = Int32List(cnt);
    var q = 0;
    for (final t in vis) {
      for (var e = 0; e < 3; e++) {
        final vi = m.tris[t * 3 + e];
        final ax = m.nrm[vi * 3], ay = m.nrm[vi * 3 + 1], az = m.nrm[vi * 3 + 2];
        final nx1 = ax * cyw + az * syw;
        final nz1 = -ax * syw + az * cyw;
        final ny2 = ay * cp - nz1 * sp;
        final nz2 = ay * sp + nz1 * cp;
        final d = math.max(0.0, (nx1 * hx + ny2 * hy + nz2 * hz) / hl);
        final v = (math.pow(d, 28).toDouble() * 230).round().clamp(0, 255);
        // ánh vàng nhạt
        spec[q++] = (0xFF << 24) | (v << 16) | ((v * 0.92).round() << 8) | (v * 0.7).round();
      }
    }
    final sv = ui.Vertices.raw(ui.VertexMode.triangles, positions, colors: spec);
    canvas.drawVertices(sv, BlendMode.dst, Paint()..blendMode = BlendMode.plus);
  }
}

// ---------------------------------------------------------------------
// Bộ nhớ đệm + widget
// ---------------------------------------------------------------------

// Khoá: (ảnh, độ mịn). Ảnh người dùng so theo đúng đối tượng, asset so theo tên.
final Map<(Object, bool, BodyType, bool), Future<InflatedModel?>> _cache = {};

/// [source] là Uint8List (ảnh người dùng) hoặc String (đường dẫn asset).
Future<InflatedModel?> loadInflated(Object source,
    {required bool hi, BodyType body = BodyType.canDoi, bool relief = false}) {
  final key = (source, hi, body, relief);
  if (!_cache.containsKey(key) && _cache.length > 60) {
    _cache.remove(_cache.keys.first);
  }
  return _cache.putIfAbsent(key, () async {
    try {
      final Uint8List bytes;
      if (source is Uint8List) {
        bytes = source;
      } else {
        final data = await rootBundle.load(source as String);
        bytes = data.buffer.asUint8List();
      }
      return await buildInflated(bytes,
          grid: relief ? (hi ? 64 : 40) : (hi ? 52 : 34), body: body, relief: relief);
    } catch (_) {
      return null; // ảnh lỗi / không có file -> dùng kiểu cũ
    }
  });
}

class Inflated3DView extends StatefulWidget {
  final Object source;
  final double size;
  final double yaw;
  final bool hiDetail;
  final BodyType body;

  /// Kiểu phù điêu kim loại.
  final bool relief;

  /// Hiển thị trong lúc đang dựng hoặc khi không dựng được.
  final Widget fallback;

  const Inflated3DView({
    super.key,
    required this.source,
    required this.size,
    required this.fallback,
    this.yaw = 0,
    this.hiDetail = false,
    this.body = BodyType.canDoi,
    this.relief = false,
  });

  @override
  State<Inflated3DView> createState() => _Inflated3DViewState();
}

class _Inflated3DViewState extends State<Inflated3DView> {
  InflatedModel? _model;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant Inflated3DView old) {
    super.didUpdateWidget(old);
    if (!identical(old.source, widget.source) ||
        old.hiDetail != widget.hiDetail ||
        old.body != widget.body ||
        old.relief != widget.relief) {
      _load();
    }
  }

  void _load() {
    final src = widget.source;
    final hi = widget.hiDetail;
    final body = widget.body;
    final relief = widget.relief;
    loadInflated(src, hi: hi, body: body, relief: relief).then((m) {
      if (!mounted ||
          !identical(src, widget.source) ||
          hi != widget.hiDetail ||
          body != widget.body ||
          relief != widget.relief) {
        return;
      }
      setState(() {
        _model = m;
        _failed = m == null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = _model;
    if (m == null || _failed) return widget.fallback;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        child: CustomPaint(painter: _InflatedPainter(m, widget.yaw)),
      ),
    );
  }
}

class _InflatedPainter extends CustomPainter {
  final InflatedModel model;
  final double yaw;
  _InflatedPainter(this.model, this.yaw);

  @override
  void paint(Canvas canvas, Size size) => paintInflated(canvas, size, model, yaw: yaw);

  @override
  bool shouldRepaint(covariant _InflatedPainter o) => o.model != model || o.yaw != yaw;
}
