import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapViewModel extends ChangeNotifier {
  static const LatLng seiyunCenter = LatLng(15.9429, 48.7844);
  final MapController mapController = MapController();

  bool _showReports = true;
  bool get showReports => _showReports;

  bool _showContainers = true;
  bool get showContainers => _showContainers;

  bool _isSatellite = false;
  bool get isSatellite => _isSatellite;

  void toggleReports() {
    _showReports = !_showReports;
    notifyListeners();
  }

  void toggleContainers() {
    _showContainers = !_showContainers;
    notifyListeners();
  }

  void toggleSatellite() {
    _isSatellite = !_isSatellite;
    notifyListeners();
  }

  void moveToCenter() {
    mapController.move(seiyunCenter, 14.0);
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
