/// 3 dáng người/con vật cho ảnh 3D, theo 3 kiểu dáng chuẩn trong thiết kế
/// nhân vật: ốm (ectomorph), cân đối (mesomorph), mập (endomorph).
enum BodyType { om, canDoi, map }

const Map<BodyType, String> kBodyTypeNames = {
  BodyType.om: 'Ốm',
  BodyType.canDoi: 'Cân đối',
  BodyType.map: 'Mập',
};

BodyType bodyTypeFromName(String? s) =>
    BodyType.values.firstWhere((b) => b.name == s, orElse: () => BodyType.canDoi);

/// Thông số cho ảnh thổi phồng.
class InflateShape {
  final double thick; // độ dày tối đa so với bề ngang hình
  final double profile; // < 0.5: phồng đều (tròn trịa), > 0.5: nhọn dần
  final double scaleX; // bề ngang
  final double scaleY; // chiều cao
  const InflateShape(this.thick, this.profile, this.scaleX, this.scaleY);
}

const Map<BodyType, InflateShape> kInflateShapes = {
  BodyType.om: InflateShape(0.45, 0.75, 0.84, 1.07),
  BodyType.canDoi: InflateShape(0.85, 0.5, 1.0, 1.0),
  BodyType.map: InflateShape(1.25, 0.3, 1.2, 0.93),
};

/// Thông số cho Chibi 3D.
class ChibiShape {
  final double torso; // độ to của thân
  final double limb; // độ to của tay chân
  final double legLen; // độ dài chân
  const ChibiShape(this.torso, this.limb, this.legLen);
}

const Map<BodyType, ChibiShape> kChibiShapes = {
  BodyType.om: ChibiShape(0.7, 0.65, 1.45),
  BodyType.canDoi: ChibiShape(1.0, 1.0, 1.0),
  BodyType.map: ChibiShape(1.38, 1.32, 0.85),
};

/// Kiểu hiển thị của mỗi hình.
enum ImageStyle { standard, thoiPhong, phuDieu, chibi, nguoiQue }

const Map<ImageStyle, String> kImageStyleNames = {
  ImageStyle.standard: 'Standard (phẳng)',
  ImageStyle.thoiPhong: '3D thổi phồng',
  ImageStyle.phuDieu: '3D phù điêu (biểu tượng)',
  ImageStyle.chibi: 'Chibi 3D',
  ImageStyle.nguoiQue: 'Người que',
};

ImageStyle imageStyleFromName(String? s, [ImageStyle fallback = ImageStyle.thoiPhong]) =>
    ImageStyle.values.firstWhere((b) => b.name == s, orElse: () => fallback);
