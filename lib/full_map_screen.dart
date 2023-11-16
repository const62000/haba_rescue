import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:haba_rescue_app/address_search_page.dart';
import 'package:haba_rescue_app/conversation_bubble.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';




class FullMapScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;



  FullMapScreen({required this.origin, required this.destination});

  @override
  _FullMapScreenState createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  late GoogleMapController _mapController;
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;

  late LatLng origin;
  late LatLng destination;

  Set<Marker> _markers = {};

  int estimatedTimeLeft = 0;

  @override
  void initState() {
    super.initState();
    origin = widget.origin;
    destination = widget.destination;
    _startLocationTracking();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false, // Disable my location button
            polylines: _polylines,
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                (origin.latitude + destination.latitude) / 2,
                (origin.longitude + destination.longitude) / 2,
              ),
              zoom: _calculateZoomLevel(),
            ),
            markers: {
              Marker(
                markerId: MarkerId('currentLocation'),
                position: LatLng(destination.latitude, destination.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueMagenta,
                ),
              ),
            },
          ),
          Positioned(
            top: 40,
            left: 10,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 10,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () async {
                    final selectedLocation = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddressSearchPage(currentDestination: destination),
                      ),
                    );
                    if (selectedLocation != null) {
                      _updateDestinationCoordinates(selectedLocation.coordinates);
                    }
                  },
                ),

              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '$estimatedTimeLeft mins away',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),

          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _startLocationTracking() {
    // Replace this with your location tracking logic
    // For demonstration purposes, we're using a Timer to simulate location updates
    // You need to replace this code with your actual location tracking implementation
    // and update the _currentLocation and _polylines accordingly

    _currentLocation = origin; // Simulating initial location

    Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {
        _currentLocation = LatLng(
          _currentLocation!.latitude + 0.1,
          _currentLocation!.longitude + 0.1,
        );

        _updatePolylines();
      });
    });
  }

  void _updatePolylines() {
    // setState(() {
    //   _polylines.clear();
    //
    //   Polyline polyline = Polyline(
    //     polylineId: PolylineId('directions'),
    //     color: Colors.blue,
    //     points: [widget.origin, _currentLocation!, widget.destination],
    //     width: 5,
    //   );
    //
    //   _polylines.add(polyline);
    // });


    _getDirections();

    _fitBounds();
  }

  void _fitBounds() {
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        min(origin.latitude, destination.latitude),
        min(origin.longitude, destination.longitude),
      ),
      northeast: LatLng(
        max(origin.latitude, destination.latitude),
        max(origin.longitude, destination.longitude),
      ),
    );

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 100);
    _mapController.animateCamera(cameraUpdate);
  }


  double _calculateZoomLevel() {
    final double latDistance = (origin.latitude - destination.latitude).abs();
    final double lngDistance = (origin.longitude - destination.longitude).abs();
    final double distance = latDistance > lngDistance ? latDistance : lngDistance;
    return 13 - distance;
  }


  Future<void> _getDirections() async {
    // print(destination.longitude);
    final apiKey = 'AIzaSyCr3FYiPyCXjAHl218A2r7fVLAOr08E544';
    // Construct the API URL with origin, destination, and API key
    String apiUrl = 'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude}, ${origin.longitude}&destination=${destination.latitude}, ${destination.longitude}&key=$apiKey';

    http.Response response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> data = json.decode(response.body);

    // print(response.body);

    if (data['status'] == 'OK') {
      List<LatLng> decodedPoints = decodePolyline(data['routes'][0]['overview_polyline']['points']);

      setState(() {
        _polylines.clear();
        _polylines.add(Polyline(
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
        // setState(() {
        //   isLoading = false;
        // });
        // Calculate estimated time left
        int totalDuration = data['routes'][0]['legs'][0]['duration']['value'];
        int remainingDuration = totalDuration;

        if (_currentLocation != null) {
          int currentLegIndex = 0;
          List<dynamic> legs = data['routes'][0]['legs'];
          while (currentLegIndex < legs.length) {
            int legDuration = legs[currentLegIndex]['duration']['value'];
            if (remainingDuration > legDuration) {
              remainingDuration -= legDuration;
            } else {
              break;
            }
            currentLegIndex++;
          }
        }

         estimatedTimeLeft = (remainingDuration / 60).ceil();

        _markers = Set<Marker>.of([
          Marker(
            markerId: MarkerId('currentLocation'),
            position: _currentLocation!,
            infoWindow: InfoWindow(
              title: 'Time Left: $estimatedTimeLeft mins',
              snippet: '',
            ),
          ),
        ]);

        // // Update the marker tag
        // Marker updatedMarker = _markers.firstWhere((marker) => marker.markerId.value == 'current_location');
        // _markers.remove(updatedMarker);
        // _markers.add(
        //   updatedMarker.copyWith(
        //     infoWindowParam: InfoWindow(title: 'Time Left: $estimatedTimeLeft mins'),
        //   ),
        // );

        // Animate camera and set state...
      }
    } else {
      // setState(() {
      //   isLoading = false;
      // });
      print('Error1: ${data['status']}');
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

  void _updateDestinationCoordinates(LatLng coordinates) {
    setState(() {
      destination = coordinates;
    });

    _updatePolylines();
  }


}
