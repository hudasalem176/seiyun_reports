import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:seiyun_reports_app/core/theme/app_theme.dart';
import 'package:seiyun_reports_app/screens/map/viewmodel/map_viewmodel.dart';
import 'package:seiyun_reports_app/screens/map/view/widgets/map_filter_chip.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialTitle;
  final bool isPicker;

  const MapScreen({
    super.key,
    this.initialLocation,
    this.initialTitle,
    this.isPicker = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _pickedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.isPicker &&
        widget.initialLocation != null &&
        widget.initialLocation!.latitude != 0) {
      _pickedLocation = widget.initialLocation;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapVM = context.read<MapViewModel>();
      mapVM.fetchMapData();
      if (widget.initialLocation != null &&
          widget.initialLocation!.latitude != 0 &&
          !widget.isPicker) {
        mapVM.startLocationTracking(widget.initialLocation);
      } else if (widget.isPicker) {
        mapVM.startLocationTracking(null);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MapViewModel>().stopLocationTracking();
      }
    });
    super.dispose();
  }

  Future<void> _openExternalMap(LatLng location) async {
    final String url =
        'google.navigation:q=${location.latitude},${location.longitude}&mode=d';
    final Uri uri = Uri.parse(url);
    final String fallbackUrl =
        'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}&travelmode=driving';
    final Uri fallbackUri = Uri.parse(fallbackUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'عذراً، لم نتمكن من العثور على تطبيق خرائط للتوجيه',
              ),
            ),
          );
        }
      }
    } catch (e) {
      // فشل فتح الخرائط الخارجية
    }
  }

  void _showMarkerDetails(BuildContext ctx, MapViewModel mapVM) {
    final info = mapVM.tappedInfo;
    if (info == null) return;

    final bool isContainer = info['type'] == 'container';

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _MarkerBottomSheet(
            info: info,
            isContainer: isContainer,
            onNavigate:
                isContainer
                    ? () {
                      Navigator.pop(ctx);
                      _openExternalMap(
                        LatLng(info['lat'] as double, info['lng'] as double),
                      );
                    }
                    : null,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapVM = context.watch<MapViewModel>();
    final Set<Marker> markers = Set.from(mapVM.markers);
    final Set<Polyline> polylines = {};

    // ✦ خط المسار إلى الهدف
    if (mapVM.isIsolatedMode &&
        mapVM.currentPosition != null &&
        mapVM.targetLocation != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_target'),
          points: [
            LatLng(
              mapVM.currentPosition!.latitude,
              mapVM.currentPosition!.longitude,
            ),
            mapVM.targetLocation!,
          ],
          color: AppTheme.primaryColor,
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.buttCap,
        ),
      );
    }

    // ✦ ماركر اختيار الموقع
    if (widget.isPicker && _pickedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('picked_location'),
          position: _pickedLocation!,
          draggable: true,
          onDragEnd: (location) {
            setState(() {
              _pickedLocation = location;
            });
          },
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isPicker ? 'تحديد الموقع على الخريطة' : 'خريطة سيئون',
          ),
          actions:
              widget.isPicker
                  ? [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed:
                            () => Navigator.pop(context, _pickedLocation),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('حفظ'),
                      ),
                    ),
                  ]
                  : [
                    if (mapVM.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'تحديث',
                      onPressed: () => mapVM.fetchMapData(),
                    ),
                    IconButton(
                      icon: Icon(
                        mapVM.isSatellite
                            ? Icons.map_outlined
                            : Icons.satellite_alt_outlined,
                      ),
                      tooltip: 'نوع الخريطة',
                      onPressed: () => mapVM.toggleSatellite(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location),
                      tooltip: 'موقعي',
                      onPressed: () => mapVM.moveToCenter(),
                    ),
                  ],
        ),
        body: Stack(
          children: [
            // ── الخريطة ──────────────────────────────────────
            GoogleMap(
              onMapCreated: (controller) {
                mapVM.onMapCreated(controller);
                if (widget.initialLocation != null &&
                    widget.initialLocation!.latitude != 0 &&
                    !widget.isPicker) {
                  mapVM.focusOnLocation(widget.initialLocation!);
                }
              },
              initialCameraPosition: CameraPosition(
                target:
                    (widget.initialLocation == null ||
                            widget.initialLocation!.latitude == 0)
                        ? MapViewModel.seiyunCenter
                        : widget.initialLocation!,
                zoom:
                    (widget.initialLocation == null ||
                            widget.initialLocation!.latitude == 0)
                        ? 14.0
                        : 17.0,
              ),
              mapType: mapVM.isSatellite ? MapType.satellite : MapType.normal,
              markers: markers,
              polylines: polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              onTap:
                  widget.isPicker
                      ? (loc) => setState(() => _pickedLocation = loc)
                      : (_) => mapVM.setTappedInfo(
                        null,
                      ), // إغلاق البانيل عند النقر على الخريطة
            ),

            // ── شريط الفلتر العلوي ────────────────────────────
            if (!widget.isPicker)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _FilterBar(mapVM: mapVM),
                ),
              ),

            // ── بطاقة المسافة ──────────────────────────────────
            if (mapVM.isIsolatedMode && mapVM.distanceToTarget != null)
              Positioned(
                bottom: 130,
                left: 16,
                right: 16,
                child: _DistanceIndicator(
                  distance: mapVM.distanceToTarget!,
                  title: widget.initialTitle ?? 'الحاوية المقصودة',
                  onNavigate: () => _openExternalMap(widget.initialLocation!),
                ),
              ),

            // ── بطاقة تفاصيل الماركر المنقور عليه ───────────────
            if (!widget.isPicker && mapVM.tappedInfo != null)
              Positioned(
                bottom: mapVM.isIsolatedMode ? 230 : 80,
                left: 16,
                right: 16,
                child: _InlineMarkerCard(
                  info: mapVM.tappedInfo!,
                  onNavigate: () {
                    final lat = mapVM.tappedInfo!['lat'] as double;
                    final lng = mapVM.tappedInfo!['lng'] as double;
                    _openExternalMap(LatLng(lat, lng));
                  },
                  onClose: () => mapVM.setTappedInfo(null),
                ),
              ),

            // ── أزرار التحكم بالزوم ────────────────────────────
            Positioned(
              right: 12,
              bottom: mapVM.isIsolatedMode ? 120 : 40,
              child: Column(
                children: [
                  if (mapVM.isIsolatedMode) ...[
                    _ZoomFab(
                      heroTag: 'clear_track',
                      icon: Icons.close,
                      color: Colors.redAccent,
                      onTap: () => mapVM.stopLocationTracking(),
                    ),
                    const SizedBox(height: 10),
                  ],
                  _ZoomFab(
                    heroTag: 'zoom_in',
                    icon: Icons.add,
                    color: Colors.white,
                    iconColor: Colors.black87,
                    onTap: () => mapVM.zoomIn(),
                  ),
                  const SizedBox(height: 8),
                  _ZoomFab(
                    heroTag: 'zoom_out',
                    icon: Icons.remove,
                    color: Colors.white,
                    iconColor: Colors.black87,
                    onTap: () => mapVM.zoomOut(),
                  ),
                ],
              ),
            ),

            // ── مفتاح الألوان ──────────────────────────────────
            if (!widget.isPicker && !mapVM.isIsolatedMode && mapVM.showReports)
              const Positioned(bottom: 40, left: 12, child: _LegendCard()),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
//  شريط الفلتر العلوي
// ════════════════════════════════════════════════
class _FilterBar extends StatelessWidget {
  final MapViewModel mapVM;
  const _FilterBar({required this.mapVM});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MapFilterChip(
            label: 'البلاغات',
            color: const Color(0xFF2980B9),
            icon: Icons.report_gmailerrorred_rounded,
            isSelected: mapVM.showReports,
            onTap: () => mapVM.toggleReports(),
          ),
          const SizedBox(width: 8),
          MapFilterChip(
            label: 'الحاويات',
            color: const Color(0xFF1B8C4E),
            icon: Icons.delete_rounded,
            isSelected: mapVM.showContainers,
            onTap: () => mapVM.toggleContainers(),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
//  بطاقة تفاصيل الماركر (Inline)
// ════════════════════════════════════════════════
class _InlineMarkerCard extends StatelessWidget {
  final Map<String, dynamic> info;
  final VoidCallback onNavigate;
  final VoidCallback onClose;

  const _InlineMarkerCard({
    required this.info,
    required this.onNavigate,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bool isContainer = info['type'] == 'container';
    final color =
        isContainer
            ? const Color(0xFF1B8C4E)
            : _reportColor(info['status'] ?? '');
    final icon =
        isContainer ? Icons.delete_rounded : _reportIcon(info['status'] ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // أيقونة النوع
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),

          // المعلومات
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isContainer
                      ? (info['name'] ?? 'حاوية نفايات')
                      : 'بلاغ رقم ${info['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (!isContainer) _StatusBadge(status: info['status'] ?? ''),
                if (isContainer)
                  Text(
                    'اضغط التوجيه للوصول إلى الحاوية',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),

          // أزرار
          Column(
            children: [
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onNavigate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.navigation_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'توجيه',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _reportColor(String status) {
    switch (status) {
      case 'تم الحل':
        return const Color(0xFF27AE60);
      case 'قيد المعالجة':
        return const Color(0xFF2980B9);
      case 'ملغية':
        return const Color(0xFFC0392B);
      default:
        return const Color(0xFFE67E22);
    }
  }

  static IconData _reportIcon(String status) {
    return Icons.report_gmailerrorred_rounded;
  }
}

// ════════════════════════════════════════════════
//  شارة حالة البلاغ
// ════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'تم الحل':
        color = const Color(0xFF27AE60);
        break;
      case 'قيد المعالجة':
        color = const Color(0xFF2980B9);
        break;
      case 'ملغية':
        color = const Color(0xFFC0392B);
        break;
      default:
        color = const Color(0xFFE67E22);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.isEmpty ? 'جديد' : status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
//  مفتاح الألوان (Legend)
// ════════════════════════════════════════════════
class _LegendCard extends StatelessWidget {
  const _LegendCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'البلاغات',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          _LegendItem(color: const Color(0xFFE67E22), label: 'جديد'),
          _LegendItem(color: const Color(0xFF2980B9), label: 'قيد المعالجة'),
          _LegendItem(color: const Color(0xFF27AE60), label: 'تم الحل'),
          _LegendItem(color: const Color(0xFFC0392B), label: 'ملغي'),
          const Divider(height: 10, thickness: 0.5),
          _LegendItem(color: const Color(0xFF1B8C4E), label: 'حاوية نفايات'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
//  زر Zoom صغير
// ════════════════════════════════════════════════
class _ZoomFab extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ZoomFab({
    required this.heroTag,
    required this.icon,
    required this.color,
    this.iconColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
//  بطاقة المسافة إلى الهدف
// ════════════════════════════════════════════════
class _DistanceIndicator extends StatelessWidget {
  final double distance;
  final String title;
  final VoidCallback onNavigate;

  const _DistanceIndicator({
    required this.distance,
    required this.title,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final String distText =
        distance > 1000
            ? '${(distance / 1000).toStringAsFixed(1)} كم'
            : '${distance.toStringAsFixed(0)} متر';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_walk,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'تبعد عنك $distText',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onNavigate,
            icon: const Icon(Icons.navigation_outlined, size: 16),
            label: const Text('توجيه'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
//  Bottom Sheet التفاصيل (unused but kept for future use)
// ════════════════════════════════════════════════
class _MarkerBottomSheet extends StatelessWidget {
  final Map<String, dynamic> info;
  final bool isContainer;
  final VoidCallback? onNavigate;

  const _MarkerBottomSheet({
    required this.info,
    required this.isContainer,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isContainer
                ? (info['name'] ?? 'حاوية نفايات')
                : 'بلاغ رقم ${info['id']}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (!isContainer) ...[
            const SizedBox(height: 8),
            _StatusBadge(status: info['status'] ?? ''),
          ],
          const SizedBox(height: 20),
          if (onNavigate != null)
            ElevatedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('الذهاب إلى الموقع'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
