import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice_ex/places.dart';

class PlaceWithCoordinates {
  final PlacesSearchResult place;
  final LatLng coordinates;

  PlaceWithCoordinates({required this.place, required this.coordinates});
}
