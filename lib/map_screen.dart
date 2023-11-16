import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:haba_rescue_app/full_map_screen.dart';
import 'package:http/http.dart' as http;


class MapScreen extends StatefulWidget {
  final String policyNumber;
  final String description;
  final double latitude;
  final double longitude;

  MapScreen({
    required this.policyNumber,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  Set<Marker> _markers = {};
  // Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];

  Completer<GoogleMapController> _controllerCompleter = Completer();
  Set<Polyline> polylines = {};

  late LatLng currentLocation;


  late String policyNumber;
  late String description;
  late double latitude;
  late double longitude;

  bool isLoading = false;

  bool isStillLoading = false;

  // final directions = Directions.GoogleMapsDirections(apiKey: 'AIzaSyCr3FYiPyCXjAHl218A2r7fVLAOr08E544');


  @override
  void initState() {
    super.initState();

    policyNumber = widget.policyNumber;
    description = widget.description;
    latitude =  widget.latitude;
    longitude = widget.longitude;



    print('latitude $latitude, longitude $longitude');

    _getCurrentLocation();

    _addMarker(LatLng(latitude, longitude), 'Selected Location');
  }

  void _addMarker(LatLng position, String markerId) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: position,
        ),
      );
    });
  }

  void _addUserMarker(LatLng position, String markerId) {
    setState(() {
      _markers.add(
        Marker(

            position: position, markerId: MarkerId(markerId))
      );
    });
  }

  Future<void> _getCurrentLocation() async {

    setState(() {
      isLoading = false;
      isStillLoading = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('we got here');
    if (!serviceEnabled) {
      // Location services are not enabled, handle it as per your requirement
      print('service not enabled 1');
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Request location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Location permissions are denied, handle it as per your requirement
        print('service not enabled 2');
        setState(() {
          isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Location permissions are permanently denied, handle it as per your requirement
      print('service not enabled forever');
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Use the current position to update the map and draw the route
    currentLocation = LatLng(position.latitude, position.longitude);
    final GoogleMapController controller = await _controllerCompleter.future;

    setState(() {
      isLoading = false;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              currentLocation.latitude!,
              currentLocation.longitude!,
            ),
            zoom: 15,
          ),
        ),
      );
    }
    );
    // _addUserMarker(currentLocation, 'User location');

    setState(() {
      isLoading = false;
    });

    print('Current locaton: $currentLocation');
    await _getDirections(currentLocation,  latitude,  longitude);
  }




  Future<void> _getDirections(LatLng currentLocation, double lat, double long) async {
    setState(() {
      isLoading = true;
      isStillLoading = true;
    });





    final apiKey = 'AIzaSyCr3FYiPyCXjAHl218A2r7fVLAOr08E544';
    String apiUrl =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${currentLocation.latitude},${currentLocation.longitude}&destination=$lat,$long&key=$apiKey';

    http.Response response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> data = json.decode(response.body);

    if (data['status'] == 'OK') {
      List<LatLng> decodedPoints = decodePolyline(data['routes'][0]['overview_polyline']['points']);

      setState(() {
        polylines.clear();
        polylines.add(Polyline(
          polylineId: PolylineId('directions'),
          points: decodedPoints,
          color: Colors.purple,
          width: 3,
        ));
      });

      if (decodedPoints.isNotEmpty) {
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            data['routes'][0]['bounds']['southwest']['lat'],
            data['routes'][0]['bounds']['southwest']['lng'],
          ),
          northeast: LatLng(
            data['routes'][0]['bounds']['northeast']['lat'],
            data['routes'][0]['bounds']['northeast']['lng'],
          ),
        );

        // mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
        setState(() {
          isLoading = false;
          isStillLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
        isStillLoading = false;
      });
      print('Error: ${data['status']}');
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      double latitude = lat / 1e5;
      double longitude = lng / 1e5;

      points.add(LatLng(latitude, longitude));
    }

    return points;

  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Icon(
              Icons.circle,
              color: Colors.green,
              size: 10,
            ),
            SizedBox(width: 5),
            Text(
              'Accepted request',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    height: 200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Options'),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            // Handle button tap
                          },
                          child: Text('Button'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: isLoading ?
      Center(
        child: CircularProgressIndicator(),
      )
      :
      Container(
        color: Colors.purple,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Policy Number',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  policyNumber,
                  style: TextStyle(
                    color: Colors.purple.shade400,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                            AssetImage('assets/profile_picture.png'),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User Name',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Row(
                                  children: [
                                    SizedBox(width: 5),
                                    Text(
                                      '123-456-7890',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(width: 5),
                                    InkWell(
                                      onTap: () {
                                        // Handle phone number copy or dial action
                                      },
                                      child: Icon(Icons.copy, size: 15, color: Colors.grey.shade400,),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: Colors.purple.shade200,),
                          SizedBox(width: 10),
                          Text(
                            description,
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car_outlined, color: Colors.purple.shade200),
                          SizedBox(width: 10),
                          Text(
                            'Car Description',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.water_damage_outlined, color: Colors.purple.shade200),
                          SizedBox(width: 10),
                          Text(
                            'Damage Description',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.umbrella_outlined, color: Colors.purple.shade200),
                          SizedBox(width: 10),
                          Text(
                            'Policy Type',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),
                    Container(
                      height: 350,
                      child: Stack(
                        children: [
                          GoogleMap(
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            myLocationButtonEnabled: false, // Disable my location button
                            initialCameraPosition: CameraPosition(
                              target: LatLng(latitude, longitude),
                              zoom: 15,
                            ),
                            polylines: polylines,
                            onMapCreated: (controller) {
                              _controllerCompleter.complete(controller);
                            },
                            markers: {
                              Marker(
                                markerId: MarkerId('currentLocation'),
                                position: LatLng(latitude, longitude),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueMagenta,
                                ),
                              ),
                            },
                          ),
                          Positioned(
                            bottom: 40,
                            right: 10,
                            child: isStillLoading ?
                            CircularProgressIndicator()
                            :
                            IconButton(
                              icon: Icon(Icons.zoom_out_map,
                              size: 30,),
                              onPressed: () {
                                // Handle full map page navigation
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullMapScreen(
                                      origin: LatLng(currentLocation.latitude, currentLocation.longitude), // origin
                                      destination: LatLng(latitude, longitude, // Destination
                                    ),
                                  ),
                                )
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
