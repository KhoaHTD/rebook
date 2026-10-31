import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/data/vietnam_geo.dart';

/// Bản đồ OpenStreetMap (tile raster, tải theo vùng đang xem). Ghim luôn nằm giữa khung: kéo / chụm bản đồ
/// cho tâm trúng chỗ cần chọn, vị trí là toạ độ ở tâm.
/// Hoàng Sa và Trường Sa luôn được ghi tên "(Việt Nam)" phủ lên trên nền bản đồ.
class OsmMap extends StatefulWidget {
  const OsmMap({
    super.key,
    this.point,
    this.onCenter,
    this.height = 320,
    this.zoom = 15,
  });

  /// Vị trí đặt tâm bản đồ (vĩ độ, kinh độ); null thì hiện cả nước. Đổi từ bên ngoài (định vị tự động) thì
  /// bản đồ chạy tới đó.
  final GeoPoint? point;

  /// Gọi khi người dùng kéo xong: toạ độ ở tâm bản đồ.
  final ValueChanged<GeoPoint>? onCenter;

  final double height;

  /// Mức phóng khi có ghim.
  final double zoom;

  @override
  State<OsmMap> createState() => _OsmMapState();
}

class _OsmMapState extends State<OsmMap> {
  static const _vietnam = LatLng(15.8, 106.5);
  static const _paracel = LatLng(16.5, 112);
  static const _spratly = LatLng(9, 114);

  final _controller = MapController();

  LatLng? get _pin =>
      widget.point == null ? null : LatLng(widget.point!.$1, widget.point!.$2);

  @override
  void didUpdateWidget(OsmMap old) {
    super.didUpdateWidget(old);
    final pin = _pin;
    if (pin == null || widget.point == old.point) return;
    // Điểm vừa do chính cú kéo báo lên thì đã nằm ở tâm, không di chuyển lại.
    final c = _controller.camera.center;
    if ((c.latitude - pin.latitude).abs() < 1e-7 &&
        (c.longitude - pin.longitude).abs() < 1e-7) {
      return;
    }
    _controller.move(pin, widget.zoom);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = context.textStyles.labelSmall!.copyWith(
      color: MapPalette.label,
      fontWeight: FontWeight.w700,
    );
    final pin = _pin;
    Marker islands(LatLng at, String text) => Marker(
      point: at,
      width: 160,
      height: 32,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: label,
        ),
      ),
    );
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(
            backgroundColor: MapPalette.sea,
            initialCenter: pin ?? _vietnam,
            initialZoom: pin == null ? 4.6 : widget.zoom,
            minZoom: 3,
            maxZoom: 19,
            onMapEvent: (e) {
              // Chỉ báo khi người dùng kéo xong (không báo cho chuyển động do mã gọi).
              final byUser =
                  e.source != MapEventSource.mapController &&
                  e.source != MapEventSource.nonRotatedSizeChange;
              final done =
                  e is MapEventMoveEnd ||
                  e is MapEventFlingAnimationEnd ||
                  e is MapEventDoubleTapZoomEnd ||
                  e is MapEventScrollWheelZoom;
              if (byUser && done && widget.onCenter != null) {
                widget.onCenter!((
                  e.camera.center.latitude,
                  e.camera.center.longitude,
                ));
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'vn.edu.fpt.book_marketplace',
            ),
            MarkerLayer(
              markers: [
                islands(_paracel, l10n.mapParacel),
                islands(_spratly, l10n.mapSpratly),
              ],
            ),
            // Ghim cố định giữa khung: mũi ghim chạm đúng tâm bản đồ.
            IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 40,
                    color: MapPalette.pin,
                  ),
                ),
              ),
            ),
            RichAttributionWidget(
              showFlutterMapAttribution: false,
              alignment: AttributionAlignment.bottomRight,
              attributions: [TextSourceAttribution(l10n.mapAttribution)],
            ),
          ],
        ),
      ),
    );
  }
}
