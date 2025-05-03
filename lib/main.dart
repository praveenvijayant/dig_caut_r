import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Caution Order',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LiveCautionViewer(),
      debugShowCheckedModeBanner: false,
    );
  }
}
class LiveCautionViewer extends StatefulWidget {
  @override
  _LiveCautionViewerState createState() => _LiveCautionViewerState();
}
class _LiveCautionViewerState extends State<LiveCautionViewer> {
  Position? _currentPosition;
  double? _currentKm;
  List<dynamic> _railwaySegments = [];
  @override
  void initState() {
    super.initState();
    _getLocation();
    _loadGeoJson();
  }
  Future<void> _loadGeoJson() async {
    final geojson = await rootBundle.loadString('assets/railway_lines.geojson');
    final data = json.decode(geojson);
    setState(() {
      _railwaySegments = data['features'];
    });
  }
  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentPosition = position;
        _currentKm = _getNearestRailwayKm(position.latitude, position.longitude);
      });
    });
  }
  double? _getNearestRailwayKm(double lat, double lon) {
    final distance = Distance();
    double minDist = double.infinity;
    double? matchedKm;

    for (var feature in _railwaySegments) {
      final coords = feature['geometry']['coordinates'];
      for (var coord in coords) {
        double lon2 = coord[0];
        double lat2 = coord[1];
        double dist = distance.as(LengthUnit.Kilometer, LatLng(lat, lon), LatLng(lat2, lon2));
        if (dist < minDist) {
          minDist = dist;
          matchedKm = feature['properties']['start_km']?.toDouble();
        }
      }
    }
    return matchedKm;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Digital Caution Order')),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Latitude: ${_currentPosition!.latitude.toStringAsFixed(5)}'),
                      Text('Longitude: ${_currentPosition!.longitude.toStringAsFixed(5)}'),
                      Text('Speed: ${(_currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h'),
                      Text('Matched KM: ${_currentKm?.toStringAsFixed(3) ?? "Detecting..."}'),
                    ],
                  ),
                ),
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      zoom: 16.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 60.0,
                            height: 60.0,
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            builder: (ctx) =>
                                Icon(Icons.location_pin, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}


