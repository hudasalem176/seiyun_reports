import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../data/map_repository.dart';
import '../models/map_data_model.dart';
import '../utils/map_marker_helper.dart';

class MapViewModel extends ChangeNotifier {
  final MapRepository _repository;
  static const LatLng seiyunCenter = LatLng(15.9429, 48.7844);
  GoogleMapController? mapController;

  MapDataModel? _mapData;
  MapDataModel? get mapData => _mapData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  double? _distanceToTarget;
  double? get distanceToTarget => _distanceToTarget;

  LatLng? _targetLocation;
  LatLng? get targetLocation => _targetLocation;

  bool _isIsolatedMode = false;
  bool get isIsolatedMode => _isIsolatedMode;

  BitmapDescriptor? reportIconPending;
  BitmapDescriptor? reportIconProcessing;
  BitmapDescriptor? reportIconSolved;
  BitmapDescriptor? reportIconCancelled;
  BitmapDescriptor? containerIcon;

  bool _showReports = true;
  bool get showReports => _showReports;

  bool _showContainers = true;
  bool get showContainers => _showContainers;

  bool _isSatellite = false;
  bool get isSatellite => _isSatellite;

  Set<Marker> _markers = {};
  Set<Marker> get markers => _markers;

  // بيانات العنصر المنقور عليه
  Map<String, dynamic>? _tappedInfo;
  Map<String, dynamic>? get tappedInfo => _tappedInfo;

  void setTappedInfo(Map<String, dynamic>? info) {
    _tappedInfo = info;
    notifyListeners();
  }

  MapViewModel(this._repository) {
    _loadIcons().then((_) => fetchMapData());
  }

  /// تحميل وتخصيص أيقونات العلامات (الماركرز) على الخريطة
  Future<void> _loadIcons() async {
    containerIcon = await MapMarkerHelper.buildCircleMarker(
      icon: Icons.delete_rounded,
      color: const Color(0xFF1B8C4E),
      iconColor: Colors.white,
      size: 60,
    );
    reportIconPending = await MapMarkerHelper.buildCircleMarker(
      icon: Icons.report_gmailerrorred_rounded,
      color: const Color(0xFFE67E22),
      iconColor: Colors.white,
      size: 60,
    );
    reportIconProcessing = await MapMarkerHelper.buildCircleMarker(
      icon: Icons.report_gmailerrorred_rounded,
      color: const Color(0xFF2980B9),
      iconColor: Colors.white,
      size: 60,
    );
    reportIconSolved = await MapMarkerHelper.buildCircleMarker(
      icon: Icons.report_gmailerrorred_rounded,
      color: const Color(0xFF27AE60),
      iconColor: Colors.white,
      size: 60,
    );
    reportIconCancelled = await MapMarkerHelper.buildCircleMarker(
      icon: Icons.report_gmailerrorred_rounded,
      color: const Color(0xFFC0392B),
      iconColor: Colors.white,
      size: 60,
    );
    _buildMarkers();
    notifyListeners();
  }

  /// جلب بيانات الخريطة (الحاويات والبلاغات) من المستودع
  Future<void> fetchMapData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _mapData = await _repository.getMapData();
      _buildMarkers();
    } catch (e) {
      // فشل الحصول على بيانات الخريطة
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// بناء وتخزين العلامات (الماركرز) في الذاكرة لتسريع عرض الخريطة
  void _buildMarkers() {
    final Set<Marker> newMarkers = {};
    if (_mapData == null) {
      _markers = newMarkers;
      return;
    }

    if (_showReports) {
      for (var report in _mapData!.reports) {
        if (report.lat == 0 || report.lng == 0) continue;
        final pos = LatLng(report.lat, report.lng);
        newMarkers.add(
          Marker(
            markerId: MarkerId('rep_${report.id}'),
            position: pos,
            icon: _getReportIcon(report.status),
            onTap: () {
              setTappedInfo({
                'type': 'report',
                'id': report.id,
                'status': report.status,
                'lat': report.lat,
                'lng': report.lng,
              });
              focusOnLocation(pos);
            },
          ),
        );
      }
    }

    if (_showContainers) {
      for (var container in _mapData!.containers) {
        if (container.lat == 0 || container.lng == 0) continue;
        final containerLatLng = LatLng(container.lat, container.lng);
        newMarkers.add(
          Marker(
            markerId: MarkerId('cont_${container.id}'),
            position: containerLatLng,
            icon:
                containerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
            onTap: () {
              setTappedInfo({
                'type': 'container',
                'id': container.id,
                'name': container.locationName,
                'lat': container.lat,
                'lng': container.lng,
              });
              startLocationTracking(containerLatLng);
              focusOnLocation(containerLatLng);
            },
          ),
        );
      }
    }

    _markers = newMarkers;
  }

  BitmapDescriptor _getReportIcon(String status) {
    switch (status) {
      case 'تم الحل':
        return reportIconSolved ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'قيد المعالجة':
        return reportIconProcessing ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'ملغية':
        return reportIconCancelled ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return reportIconPending ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  /// بدء تتبع موقع المستخدم الحالي وحساب المسافة إلى موقع مستهدف
  Future<void> startLocationTracking(LatLng? target) async {
    _targetLocation = target;
    _isIsolatedMode = target != null;

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _calculateDistance();
      notifyListeners();
    });

    _currentPosition = await Geolocator.getCurrentPosition();
    _calculateDistance();
    notifyListeners();
  }

  /// إيقاف تتبع موقع المستخدم وتصفير البيانات المتعلقة به
  void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _targetLocation = null;
    _isIsolatedMode = false;
    _distanceToTarget = null;
    notifyListeners();
  }

  /// حساب المسافة بين موقع المستخدم الحالي والموقع المستهدف
  void _calculateDistance() {
    if (_currentPosition != null && _targetLocation != null) {
      _distanceToTarget = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _targetLocation!.latitude,
        _targetLocation!.longitude,
      );
    }
  }

  /// إظهار أو إخفاء البلاغات على الخريطة
  void toggleReports() {
    _showReports = !_showReports;
    _buildMarkers();
    notifyListeners();
  }

  /// إظهار أو إخفاء الحاويات على الخريطة
  void toggleContainers() {
    _showContainers = !_showContainers;
    _buildMarkers();
    notifyListeners();
  }

  /// التبديل بين العرض العادي وعرض القمر الصناعي للخريطة
  void toggleSatellite() {
    _isSatellite = !_isSatellite;
    notifyListeners();
  }

  /// تهيئة متحكم الخريطة عند إنشائها
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  /// تحريك الكاميرا إلى موقع المستخدم الحالي أو إلى مركز سيئون
  void moveToCenter() {
    if (_currentPosition != null) {
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 17.0,
          ),
        ),
      );
    } else {
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(target: seiyunCenter, zoom: 14.0),
        ),
      );
    }
  }

  /// التركيز وتقريب الكاميرا على موقع محدد على الخريطة
  void focusOnLocation(LatLng location) {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 18.0),
      ),
    );
  }

  /// تكبير مستوى الرؤية (الزوم) في الخريطة
  void zoomIn() {
    mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  /// تصغير مستوى الرؤية (الزوم) في الخريطة
  void zoomOut() {
    mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    mapController = null;
    super.dispose();
  }
}
