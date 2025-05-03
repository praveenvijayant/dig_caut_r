import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(CautionViewerApp());

class CautionViewerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CautionViewerHomePage(),
    );
  }
}

class CautionViewerHomePage extends StatefulWidget {
  @override
  _CautionViewerHomePageState createState() => _CautionViewerHomePageState();
}

class _CautionViewerHomePageState extends State<CautionViewerHomePage> {
  double speed = 0.0;
  double kilometer = 0.0;
  String status = "Safe";
  String fromMast = "-";
  String toMast = "-";
  String reason = "-";
  int limit = 100;
  double distance = 0.0;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        speed = position.speed * 3.6;
        kilometer = _simulateKmFromLatLng(position.latitude, position.longitude);
        // Fake logic: if KM between 388.0 and 388.5, simulate caution zone
        if (kilometer >= 388.0 && kilometer <= 388.5) {
          status = "CAUTION AHEAD";
          fromMast = "388/33";
          toMast = "388/09";
          limit = 75;
          reason = "Level Correction";
          distance = 388.5 - kilometer;
        } else {
          status = "Safe";
          fromMast = toMast = reason = "-";
          limit = 100;
          distance = 0.0;
        }
      });
    });
  }

  double _simulateKmFromLatLng(double lat, double lng) {
    // Dummy converter — replace with geojson logic in production
    return 387.5 + (lat % 0.01) * 100; // Simulates a stretch between 387.5 to 388.5
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Current Speed: ${speed.toStringAsFixed(1)} kmph", style: TextStyle(color: Colors.white, fontSize: 20)),
                    Text("Current KM: ${kilometer.toStringAsFixed(3)}", style: TextStyle(color: Colors.white, fontSize: 20)),
                    Divider(color: Colors.white24),
                    Text("Next Caution: $fromMast to $toMast", style: TextStyle(color: Colors.amberAccent, fontSize: 18)),
                    Text("Speed Limit: $limit kmph", style: TextStyle(color: Colors.redAccent, fontSize: 18)),
                    Text("Reason: $reason", style: TextStyle(color: Colors.lightBlue, fontSize: 18)),
                    Text("Distance to Caution: ${distance.toStringAsFixed(2)} km", style: TextStyle(color: Colors.greenAccent, fontSize: 18)),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(8),
                      color: (status == "Safe") ? Colors.green : Colors.red,
                      child: Text("$status", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.grey[900],
                child: Center(child: Text("Map View (Simulated)", style: TextStyle(color: Colors.white60))),
              ),
            )
          ],
        ),
      ),
    );
  }
}