import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice_ex/places.dart';
import 'package:haba_rescue_app/model/place_with_coordinates.dart';

class AddressSearchPage extends StatefulWidget {
  final LatLng? currentDestination;

  AddressSearchPage({this.currentDestination});

  @override
  _AddressSearchPageState createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: 'AIzaSyCr3FYiPyCXjAHl218A2r7fVLAOr08E544');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<PlacesSearchResult>> _searchPlaces(String searchText) async {
    final response = await places.searchByText(searchText);
    if (response.isOkay) {
      return response.results!;
    } else {
      // Handle error
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Change Location'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: Visibility(
                  visible: _searchController.text.isNotEmpty,
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Rebuild the widget to show/hide the close icon
              },
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.location_on,
              color: Colors.purple,
            ),
            title: Text('Original Location'),
            onTap: () {
              // Return the selected place with coordinates to the FullMapScreen page
              Navigator.pop(context, PlaceWithCoordinates(
                place: PlacesSearchResult(
                  name: 'Original Location',
                  formattedAddress: '',
                  geometry: Geometry(location: Location(lat: 0, lng: 0)), reference: '', placeId: '',
                ),
                coordinates: widget.currentDestination!,
              ));
            },
          ),
          Expanded(
            child: FutureBuilder<List<PlacesSearchResult>>(
              future: _searchPlaces(_searchController.text),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Show a loading indicator while fetching search results
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  // Handle error state
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (snapshot.hasData) {
                  // Render the search results using ListView.builder
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final place = snapshot.data![index];
                      return ListTile(
                        title: Text(place.name),
                        subtitle: Text(place.formattedAddress ?? ''),
                        onTap: () {
                          // Return the selected place to the FullMapScreen page
                          Navigator.pop(context, place);
                        },
                      );
                    },
                  );
                } else {
                  // No search results found
                  return Center(
                    child: Text('No results found'),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
