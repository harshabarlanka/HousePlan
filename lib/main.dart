import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:houseplan/user_input.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final start = TextEditingController();
  final end = TextEditingController();
  bool isVisible = false;
  List<LatLng> routpoints = [const LatLng(52.05884, -1.345583)];
  LatLng sourceLocation = const LatLng(0, 0);
  LatLng destinationLocation = const LatLng(0, 0);
  List<LatLng> colleges = [];
  List<LatLng> hospitals = [];

  Future<LatLng> _getLatLngFromAddress(String address) async {
    final locations = await locationFromAddress(address);
    if (locations.isNotEmpty) {
      return LatLng(locations[0].latitude, locations[0].longitude);
    }
    return const LatLng(0, 0);
  }

  Future<List<LatLng>> _getPlacesNearLocation(
      LatLng location, List<String> amenities) async {
    final searchRadius = 0.01;
    final lat = location.latitude;
    final lon = location.longitude;

    var allAmenities = <LatLng>[];

    for (var amenity in amenities) {
      var url = Uri.parse(
        'https://overpass-api.de/api/interpreter?data=[out:json];'
        '(node["$amenity"]'
        '(around:$searchRadius,${lat},${lon}););'
        'out;',
      );

      var response = await http.get(url);

      if (response.statusCode == 200) {
        var elements = jsonDecode(response.body)['elements'];

        for (final element in elements) {
          final lat = element['lat'];
          final lon = element['lon'];

          allAmenities.add(LatLng(lat, lon));
        }
      }
    }

    return allAmenities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Map',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.grey[500],
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                myInput(controler: start, hint: 'Enter source address'),
                const SizedBox(
                  height: 15,
                ),
                myInput(controler: end, hint: 'Enter destination address'),
                const SizedBox(
                  height: 15,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[500],
                  ),
                  onPressed: () async {
                    if (start.text.isEmpty || end.text.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Error'),
                            content: const Text(
                                'Please enter both source and destination addresses.'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                      return;
                    }
                    final startLocation =
                        await _getLatLngFromAddress(start.text);
                    final endLocation = await _getLatLngFromAddress(end.text);

                    var v1 = startLocation.latitude;
                    var v2 = startLocation.longitude;
                    var v3 = endLocation.latitude;
                    var v4 = endLocation.longitude;

                    var amenitiesToFetch = ["school", "college", "university"];
                    colleges = await _getPlacesNearLocation(
                        endLocation, amenitiesToFetch);

                    var url = Uri.parse(
                      'http://router.project-osrm.org/route/v1/driving/$v2,$v1;$v4,$v3?steps=true&annotations=true&geometries=geojson&overview=full',
                    );

                    var response = await http.get(url);
                    print(response.body);
                    setState(() {
                      routpoints = [];
                      var ruter = jsonDecode(response.body)['routes'][0]
                          ['geometry']['coordinates'];
                      for (int i = 0; i < ruter.length; i++) {
                        var reep = ruter[i].toString();
                        reep = reep.replaceAll("[", "");
                        reep = reep.replaceAll("]", "");
                        var lat1 = reep.split(',');
                        var long1 = reep.split(",");
                        routpoints.add(LatLng(
                            double.parse(lat1[1]), double.parse(long1[0])));
                      }
                      isVisible = !isVisible;

                      sourceLocation = LatLng(v1, v2);
                      destinationLocation = LatLng(v3, v4);
                    });
                  },
                  child: const Text('Search'),
                ),
                const SizedBox(
                  height: 10,
                ),
                SafeArea(
                  child: SizedBox(
                    height: 500,
                    width: 400,
                    child: Visibility(
                      visible: isVisible,
                      child: FlutterMap(
                        options: MapOptions(
                          center: routpoints.isNotEmpty
                              ? routpoints[0]
                              : const LatLng(0, 0),
                          zoom: 20, // Increased zoom level
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          PolylineLayer(
                            polylineCulling: false,
                            polylines: [
                              Polyline(
                                points: routpoints,
                                color: Colors.blue.shade300,
                                strokeWidth: 9,
                              ),
                            ],
                          ),
                          if (isVisible)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  width: 60.0,
                                  height: 60.0,
                                  point: sourceLocation,
                                  builder: (ctx) => const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                  ),
                                ),
                                Marker(
                                  width: 60.0,
                                  height: 60.0,
                                  point: destinationLocation,
                                  builder: (ctx) => const Icon(
                                    Icons.location_pin,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          if (isVisible && colleges.isNotEmpty)
                            MarkerLayer(
                              markers: colleges
                                  .map(
                                    (college) => Marker(
                                      width: 40.0,
                                      height: 40.0,
                                      point: college,
                                      builder: (ctx) => const Icon(
                                        Icons.search,
                                        size: 30,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
