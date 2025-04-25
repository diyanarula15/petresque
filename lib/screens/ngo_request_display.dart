import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:petlove/models/User_model.dart'; // Assuming these paths are correct
import 'package:petlove/screens/NGO_home_page.dart'; // Assuming these paths are correct
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:petlove/models/NGO_model.dart'; // Assuming these paths are correct
// REMOVED: import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
// Import url_launcher_string if you plan to use launchUrlString
import 'package:url_launcher/url_launcher_string.dart';


class NGORequestsDisplay extends StatefulWidget {
  const NGORequestsDisplay(
      {Key? key, required String? uid, required NGOModel NGO})
      : _uid = uid,
        _NGO = NGO,
        super(key: key);

  final String? _uid;
  final NGOModel _NGO;

  @override
  State<NGORequestsDisplay> createState() => _NGORequestsDisplayState();
}

class _NGORequestsDisplayState extends State<NGORequestsDisplay> {
  // State variable for NGO's location
  late GeoPoint _NGOGeopoint;
  bool _isLoadingLocation = true; // Added loading state

  @override
  void initState() {
    super.initState();
    _fetchNgoLocation(); // Fetch NGO location when the widget initializes
  }

  // Method to fetch NGO location from Firestore
  Future<void> _fetchNgoLocation() async {
    try {
      DocumentSnapshot ngoDoc = await FirebaseFirestore.instance
          .collection('ngos') // Assuming NGO data is in 'ngos' collection
          .doc(widget._NGO.uid)
          .get();

      if (ngoDoc.exists && ngoDoc.data() != null) {
        Map<String, dynamic> data = ngoDoc.data() as Map<String, dynamic>;
        Map map = data['Location']; // Assuming location is stored like this
        if (map != null && map['geopoint'] is GeoPoint) {
           setState(() {
            _NGOGeopoint = map['geopoint'];
            _isLoadingLocation = false; // Location fetched, stop loading
           });
        } else {
           // Handle case where location data is missing or malformed
           print("NGO location data is missing or invalid.");
           setState(() { _isLoadingLocation = false; }); // Stop loading anyway
           // Optionally show an error message to the user
        }
      } else {
        // Handle case where NGO document doesn't exist
        print("NGO document not found.");
        setState(() { _isLoadingLocation = false; }); // Stop loading anyway
        // Optionally show an error message to the user
      }
    } catch (e) {
      // Handle potential errors during Firestore fetch
      print("Error fetching NGO location: $e");
      setState(() { _isLoadingLocation = false; }); // Stop loading anyway
      // Optionally show an error message to the user
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Current Requests'),
          backgroundColor: const Color.fromARGB(255, 4, 50, 88),
        ),
        // Show loading indicator while fetching location
        body: _isLoadingLocation
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<QuerySnapshot>(
          // Use the actual stream of requests
          stream: FirebaseFirestore.instance.collection('Request').snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Text('Something went wrong');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasData) {
              // Filter documents where 'Location' and 'geopoint' exist
              var filteredDocs = snapshot.data!.docs.where((document) {
                 Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                 return data.containsKey('Location') &&
                        data['Location'] != null &&
                        data['Location'] is Map &&
                        (data['Location'] as Map).containsKey('geopoint') &&
                        (data['Location'] as Map)['geopoint'] is GeoPoint;
              }).toList();


              return ListView(
                children: filteredDocs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data =
                      document.data()! as Map<String, dynamic>;
                  GeoPoint requestGeopoint = data['Location']['geopoint'];

                  var distance = Geolocator.distanceBetween(
                      _NGOGeopoint.latitude,
                      _NGOGeopoint.longitude,
                      requestGeopoint.latitude,
                      requestGeopoint.longitude);

                  // Filter by distance and if HelperUID is null or empty
                  if (distance < 30000 &&
                      (data['HelperUID'] == null || data['HelperUID'] == '')) {
                    return Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: GestureDetector(
                        // onTap: () {
                        //   ; // You can add tap functionality here if needed
                        // },
                        child: Card(
                          child: Column(
                            children: <Widget>[
                              ListTile(
                                leading: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: CachedNetworkImageProvider(
                                    data['ImageURL'] ?? 'https://via.placeholder.com/150', // Provide a fallback image
                                  ),
                                ),
                                title: Text(
                                  data['Animal'] ?? 'Unknown Animal', // Provide a default value
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 4, 50, 88),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                   'Distance: ${(distance / 1000).toStringAsFixed(2)} km', // Display distance
                                   style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: ElevatedButton(
                                      child: const Text(
                                        'LOCATION',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      onPressed: () async {
                                        final double latitude = requestGeopoint.latitude;
                                        final double longitude = requestGeopoint.longitude;
                                        // Construct the geo URI
                                        final Uri mapUri = Uri(
                                          scheme: 'geo',
                                          // Use query parameters for label for better compatibility
                                          path: '$latitude,$longitude',
                                          queryParameters: {'q': '${latitude},$longitude(${data['Animal'] ?? 'Animal Location'})'} // Add a label
                                        );

                                        // Check if the URL can be launched and launch it
                                        // Using launchUrl for Uri objects
                                        if (await canLaunchUrl(mapUri)) {
                                          await launchUrl(mapUri);
                                        } else {
                                          // Fallback to a web map URL if geo URI fails
                                          // Google Maps web URL example
                                          final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
                                          if (await canLaunchUrlString(googleMapsUrl)) {
                                             await launchUrlString(googleMapsUrl);
                                          } else {
                                             // Show an error if neither map app nor web map can be launched
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               const SnackBar(content: Text('Could not launch map.')),
                                             );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: ElevatedButton(
                                      child: const Text(
                                        'ACCEPT',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      onPressed: () {
                                        // Pass the document ID instead of ImageURL
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  NGOteammembers(
                                                    NGO: widget._NGO, // Use widget._NGO
                                                    RequestDocId: document.id, // Pass the document ID
                                                  )),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Return an empty container if the request doesn't match the filter
                    return Container();
                  }
                }).toList(),
              );
            } else {
              // This case might be covered by connectionState == waiting, but good fallback
              return const Center(
                child: Text("No Requests to display"),
              );
            }
          }),
    ));
  }
}

// RequestDetail and RequestInfo classes remain largely the same,
// but you might want to review if both are necessary or if one can be removed.
// I'm keeping them as they are for now per your original code structure.

class RequestDetail extends StatelessWidget {
  const RequestDetail({required Map<String, dynamic>? document, Key? key})
      : data = document,
        super(key: key);

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    // Added null check for data for safety
    if (data == null) {
      return const Scaffold(
        appBar: null, // Or an appropriate AppBar
        body: Center(child: Text("Error: Request data not available.")),
      );
    }
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              leading: Container(
                color: const Color.fromARGB(255, 4, 50, 88),
                padding: const EdgeInsets.all(3),
                child: Flexible(
                  flex: 1,
                  child: IconButton(
                    tooltip: 'Go back',
                    icon: const Icon(Icons.arrow_back),
                    alignment: Alignment.center,
                    iconSize: 20,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ), //Container,
              elevation: 0,
              backgroundColor: const Color.fromARGB(255, 4, 50, 88),
              title: const Text(
                'Current Requests',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: Center(
                child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                color: const Color.fromARGB(255, 255, 253, 208),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      SizedBox(
                        height: 400,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: data!['ImageURL'] ?? 'https://via.placeholder.com/400x400.png?text=No+Image', // Fallback image
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const CircularProgressIndicator(), // Loading indicator
                          errorWidget: (context, url, error) => const Icon(Icons.error), // Error icon
                        ),
                      ),
                      Container(
                          child: Column(children: <Widget>[
                        ListTile(
                            title: const Text(
                              'Animal',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 4, 50, 88),
                              ),
                            ),
                            subtitle: Text(
                              data!['Animal'] ?? 'N/A', // Default value
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            )),
                        ListTile(
                          title: const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 4, 50, 88),
                            ),
                          ),
                          subtitle: Text(
                            data!['Description'] ?? 'No description provided.', // Default value
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        )
                      ]))
                    ],
                  ),
                ),
              ),
            ))));
  }
}

class RequestInfo extends StatefulWidget {
  const RequestInfo({Map<String, dynamic>? document, Key? key})
      : data = document,
        super(key: key);

  final Map<String, dynamic>? data;

  @override
  State<RequestInfo> createState() => _RequestInfoState();
}

class _RequestInfoState extends State<RequestInfo> {
  late Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState(); // Always call super.initState() first
    data = widget.data;
  }

  @override
  Widget build(BuildContext context) {
    // Added null check for data for safety
     if (data == null) {
      return const Scaffold(
        appBar: null, // Or an appropriate AppBar
        body: Center(child: Text("Error: Request data not available.")),
      );
    }
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              leading: Container(
                color: const Color.fromARGB(255, 4, 50, 88),
                padding: const EdgeInsets.all(3),
                child: Flexible(
                  flex: 1,
                  child: IconButton(
                    tooltip: 'Go back',
                    icon: const Icon(Icons.arrow_back),
                    alignment: Alignment.center,
                    iconSize: 20,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ), //Container,
              elevation: 0,
              backgroundColor: const Color.fromARGB(255, 4, 50, 88),
              title: const Text(
                'Current Requests',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: Center(
                child: Container(
                    child: Column(children: <Widget>[
              ListTile(
                  title: const Text(
                    'Animal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 4, 50, 88),
                    ),
                  ),
                  subtitle: Text(
                    data!['Animal'] ?? 'N/A', // Default value
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  )),
              ListTile(
                title: const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 4, 50, 88),
                  ),
                ),
                subtitle: Text(
                  data!['Description'] ?? 'No description provided.', // Default value
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              )
            ])))));
  }
}

class NGOteammembers extends StatefulWidget {
  // Changed parameter name to reflect it's the document ID
  const NGOteammembers(
      {Key? key, required NGOModel NGO, required String RequestDocId})
      : _NGO = NGO,
        _RequestDocId = RequestDocId, // Storing the document ID
        super(key: key);

  final NGOModel _NGO;
  final String _RequestDocId; // State variable for the document ID

  @override
  State<NGOteammembers> createState() => _NGOteammembersState();
}

class _NGOteammembersState extends State<NGOteammembers> {
  FirebaseFirestore firestore = FirebaseFirestore.instance; // Instance is already obtained via FirebaseFirestore.instance
  var joinstat = 0; // This variable doesn't seem used
  late NGOModel _NGO;
  // late UserModel user; // This variable is not used
  late String _RequestDocId; // State variable for the document ID

  @override
  void initState() {
    super.initState(); // Always call super.initState() first
    _NGO = widget._NGO;
    _RequestDocId = widget._RequestDocId; // Get document ID from the widget
  }

  final CollectionReference _userReference =
      FirebaseFirestore.instance.collection('users');

  late final Stream<QuerySnapshot> _userstream = _userReference.snapshots();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Passing this to our root
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 4, 50, 88),
        title: const Text(
          'Team',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: _userstream,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Text('Something went wrong');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            // Check if snapshot has data before processing
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
               return const Center(child: Text("No team members found."));
            }

            return ListView(
              children: snapshot.data!.docs
                  .where((element) => element['ngo_uid'] == _NGO.uid)
                   .map((DocumentSnapshot document) {
                // Corrected cast
                Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: GestureDetector(
                    onTap: () {
                      // Optional: Add tap functionality for team members if needed
                      // Navigator.pop(context); // Original code navigates back, keep or remove?
                    },
                    child: Card(
                      color: Colors.white70,
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                data['photoURL'] ?? 'https://via.placeholder.com/150', // Fallback image
                              ),
                            ),
                            title: Text(
                              data['displayName'] ?? 'Unknown User', // Default value
                              style: const TextStyle(
                                color: Color.fromARGB(255, 4, 50, 88),
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                             subtitle: Text(data['email'] ?? '', // Display email or other info
                                style: const TextStyle(fontSize: 14)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              TextButton(
                                child: const Text(
                                  'Assign',
                                  style: TextStyle(fontSize: 15),
                                ),
                                onPressed: () async {
                                  // Use the document ID to update the specific request
                                  await FirebaseFirestore.instance
                                      .collection('Request') // Using 'Request' as per your update logic
                                      .doc(_RequestDocId) // Use the document ID
                                      .update({
                                      'HelperUID': data['uid'],
                                      // Consider if 'IsCompleted' should be true upon assignment or actual completion
                                      // 'IsCompleted': true, // Keeping your original logic, but review this
                                      'AssignmentTimestamp': FieldValue.serverTimestamp(), // Optional: Add timestamp
                                  }).then((_) {
                                     // Show success message (optional)
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(content: Text('${data['displayName']} assigned successfully!')),
                                     );
                                     // Navigate back to the NGO Home page
                                     Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => NGOHomePage(
                                                  uid: _NGO.uid,
                                                )));
                                  }).catchError((error) {
                                      // Show error message (optional)
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(content: Text('Failed to assign user: $error')),
                                     );
                                  });

                                },
                              ),
                              const SizedBox(width: 16),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
    ));
  }
}