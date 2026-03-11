import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:seiyun_reports_app/core/theme/app_theme.dart';
import 'package:seiyun_reports_app/screens/citizen_reports/viewmodel/citizen_reports_viewmodel.dart';
import 'package:seiyun_reports_app/screens/pickup_schedules/viewmodel/pickup_schedules_viewmodel.dart';
import 'package:seiyun_reports_app/screens/map/viewmodel/map_viewmodel.dart';
import 'package:seiyun_reports_app/screens/map/view/widgets/map_filter_chip.dart';
import 'package:seiyun_reports_app/screens/map/view/widgets/map_marker_item.dart';
import 'package:seiyun_reports_app/screens/map/view/widgets/map_info_bottom_sheet.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mapVM = context.watch<MapViewModel>();
    final reportsProvider = context.watch<CitizenReportsViewModel>();
    final pickupProvider = context.watch<PickupSchedulesViewModel>();

    final List<Marker> markers = _buildMarkers(context, mapVM, reportsProvider, pickupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('خريطة سيئون'),
        actions: [
          IconButton(
            icon: Icon(mapVM.isSatellite ? Icons.map_outlined : Icons.satellite_alt_outlined),
            tooltip: mapVM.isSatellite ? 'العرض العادي' : 'عرض القمر الصناعي',
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
          FlutterMap(
            mapController: mapVM.mapController,
            options: const MapOptions(
              initialCenter: MapViewModel.seiyunCenter,
              initialZoom: 14.0,
              maxZoom: 18.0,
              minZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: mapVM.isSatellite 
                  ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: mapVM.isSatellite ? const [] : const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.seiyun_reports_app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          // Legend / Filters
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  MapFilterChip(
                    label: 'بلاغات المواطنين',
                    color: Colors.blue,
                    icon: Icons.report_problem_outlined,
                    isSelected: mapVM.showReports,
                    onTap: () => mapVM.toggleReports(),
                  ),
                  const SizedBox(width: 8),
                  MapFilterChip(
                    label: 'حاويات النفايات',
                    color: AppTheme.primaryGreen,
                    icon: Icons.delete_outline,
                    isSelected: mapVM.showContainers,
                    onTap: () => mapVM.toggleContainers(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(
    BuildContext context,
    MapViewModel mapVM,
    CitizenReportsViewModel reportsProvider,
    PickupSchedulesViewModel pickupProvider,
  ) {
    final List<Marker> markers = [];

    // Add Report Markers
    if (mapVM.showReports) {
      for (var report in reportsProvider.reports) {
        markers.add(
          Marker(
            point: LatLng(report.latitude, report.longitude),
            width: 45,
            height: 45,
            child: MapMarkerItem(
              icon: Icons.location_on,
              color: Colors.blue,
              onTap:
                  () => MapInfoBottomSheet.show(
                    context,
                    report.title,
                    'الحالة: ${report.status}\nالموقع: ${report.location}\nبواسطة: ${report.authorName}',
                    report.imageUrl,
                  ),
            ),
          ),
        );
      }
    }

    // Add Container Markers
    if (mapVM.showContainers) {
      for (var container in pickupProvider.nearbyContainers) {
        markers.add(
          Marker(
            point: LatLng(container.latitude, container.longitude),
            width: 45,
            height: 45,
            child: MapMarkerItem(
              icon: Icons.delete_rounded,
              color: AppTheme.primaryGreen,
              onTap:
                  () => MapInfoBottomSheet.show(
                    context,
                    container.name,
                    'العنوان: ${container.address}\nالمسافة: ${container.distance.toStringAsFixed(0)} متر\nالحالة: ${container.status == "full"
                        ? "ممتلئة"
                        : container.status == "half"
                        ? "متوسطة"
                        : "فارغة"}',
                    null,
                  ),
            ),
          ),
        );
      }
    }

    return markers;
  }
}
