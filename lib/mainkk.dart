//mainkk.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petlove/models/User_model.dart';
import 'package:petlove/screens/home_page.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:permission_handler/permission_handler.dart'; // Import the permission_handler package


class MyCustomForm extends StatefulWidget {
  const MyCustomForm({Key? key, required UserModel user})
      : _user = user,
        super(key: key);

  final UserModel _user;
  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

class MyCustomFormState extends State<MyCustomForm> {
  GeoFlutterFire geo = GeoFlutterFire();
  final _formKey = GlobalKey<FormState>();
  late UserModel _user;
  //late User _user;
  File? image;
  String? imageURL; // Changed to nullable String
  bool uploadingDone = false;
  LatLng? location; // Made nullable to handle initial state
  GeoFirePoint? geopoint; // Made nullable

  int uploadStatus = 0;

  FirebaseStorage storage = FirebaseStorage.instance;
  final descriptionController = TextEditingController();
  final animalController = TextEditingController();
  final locationController = TextEditingController();
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    descriptionController.dispose();
    animalController.dispose();
    locationController.dispose();
    super.dispose();
  }

  uploadImage() async {
    if (image != null) {
      String? response = await uploadFile(); // uploadFile returns String?
      setState(() {
        imageURL = response;
        if (response != null) { // Only change status to 2 if upload was successful
           uploadStatus = 2;
        } else {
           uploadStatus = 0; // Stay at 0 or set to error status if needed
        }
      });
    } else {
       // Handle case where no image is selected before upload
       // Explicitly cast context to BuildContext
       ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          const SnackBar(content: Text('Please select an image first.')),
        );
    }
  }

  Future<String?> uploadFile() async { // Explicitly return String?
    final fileName = basename(image!.path);
    final destination = 'files/$fileName';
    try {
      final ref = FirebaseStorage.instance.ref(destination).child('file/');
      UploadTask task1 = ref.putFile(image!);

      String imgUrl = await (await task1).ref.getDownloadURL();

      return imgUrl;
    } catch (e) {
      print('Error occurred during image upload: $e');
      // Explicitly cast context to BuildContext
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      return null; // Return null on error
    }
  }

  @override
  void initState() {
    _user = widget._user;

    super.initState();
  }

  Future pickImageGallery() async { // Renamed for clarity
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final imageTemp = File(image.path);

      setState(() => this.image = imageTemp);
      // Reset upload status when a new image is picked
      setState(() {
        uploadStatus = 0;
        imageURL = null;
      });
    } on PlatformException catch (e) {
      print('Failed to pick image from gallery: $e');
       // Explicitly cast context to BuildContext
       ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          SnackBar(content: Text('Failed to pick image from gallery: $e')),
        );
    }
  }

  Future pickImageC() async {
    try {
      final image = await ImagePicker()
          .pickImage(source: ImageSource.camera, imageQuality: 50);

      if (image == null) return;

      final imageTemp = File(image.path);

      setState(() => this.image = imageTemp);
      // Reset upload status when a new image is picked
       setState(() {
        uploadStatus = 0;
        imageURL = null;
      });

      return imageTemp;
    } on PlatformException catch (e) {
      print('Failed to pick image from camera: $e');
       // Explicitly cast context to BuildContext
       ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          SnackBar(content: Text('Failed to pick image from camera: $e')),
        );
    }
  }

  void _awaitReturnValueFromSecondScreen(BuildContext context) async {
    // start the SecondScreen and wait for it to finish with a result
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => setCurrentLocation(
            user: _user,
          ),
        ));

    // after the SecondScreen result comes back update the Text widget with it
    if (result != null && result is LatLng) {
      setState(() {
        location = result;
        geopoint = geo.point(latitude: location!.latitude, longitude: location!.longitude);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 4, 50, 88);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // passing this to our root
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
        backgroundColor: primaryColor,
        title: const Text(
          'New Request',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: const [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.red, // Keeping red as requested
            ),
            child: Center( // Centered the placeholder text
              child: Text('Drawer Header', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
          ),
          // Add other drawer items here
        ]),
      ),
      body: Form(
        key: _formKey,
        child: ListView( // Changed Column to ListView to prevent overflow on smaller screens
          padding: const EdgeInsets.all(16.0), // Added padding to the list view
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0), // Adjusted padding
              child: TextFormField(
                controller: animalController,
                decoration: InputDecoration(
                  icon: Icon(Icons.pets, color: primaryColor), // Added color to icon
                  hintText: 'Enter Species of Animal',
                  labelText: 'Animal',
                  border: OutlineInputBorder(), // Added border
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15), // Adjusted padding
                ),
                validator: (value) { // Added validation
                  if (value == null || value.isEmpty) {
                    return 'Please enter the animal species';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0), // Adjusted padding
              child: TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  icon: Icon(Icons.report_sharp, color: primaryColor), // Added color to icon
                  hintText: 'Give description of the Animal',
                  labelText: 'Description',
                  border: OutlineInputBorder(), // Added border
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15), // Adjusted padding
                ),
                maxLines: 3, // Allow multiple lines for description
                 validator: (value) { // Added validation
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton( // Changed to ElevatedButton
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text("Choose current location",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    _awaitReturnValueFromSecondScreen(context);
                  }),
            ),
             if (location != null) // Display selected location if available
               Padding(
                 padding: const EdgeInsets.symmetric(vertical: 8.0),
                 child: Center(
                   child: Text(
                     'Location Set: ${location!.latitude.toStringAsFixed(4)}, ${location!.longitude.toStringAsFixed(4)}',
                     style: TextStyle(fontSize: 16, color: primaryColor),
                     textAlign: TextAlign.center,
                   ),
                 ),
               ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  ElevatedButton( // Changed to ElevatedButton
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: primaryColor,
                         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(8.0),
                         ),
                      ),
                      child: const Text("Pick Image from Camera",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        pickImageC();
                      }),
                   const SizedBox(height: 10), // Added spacing
                   ElevatedButton( // Added button for gallery
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: primaryColor,
                         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(8.0),
                         ),
                      ),
                      child: const Text("Pick Image from Gallery",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        pickImageGallery(); // Corrected function call
                      }),
                  const SizedBox(height: 20),
                  if (image != null) // Show image preview only if image is picked
                      SizedBox(
                          height: 200, // Adjusted height
                          child: Image.file(
                            image!,
                            fit: BoxFit.contain,
                          ),
                        ),
                   if (image != null) const SizedBox(height: 20), // Add spacing if image is shown

                  if (uploadStatus == 0 && image != null) ...[ // Show upload button only if image is picked and not uploading
                    Container( // Removed 'new' keyword
                      child: ElevatedButton( // Changed to ElevatedButton
                           style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                           ),
                          child: const Text('Upload Image'), // Changed text for clarity
                          onPressed: () {
                             if (image != null) {
                               uploadImage();
                               setState(() {
                                 uploadStatus = 1;
                               });
                             } else {
                                // Explicitly cast context to BuildContext
                               ScaffoldMessenger.of(context as BuildContext).showSnackBar(
                                  const SnackBar(content: Text('Please select an image first.')),
                                );
                             }
                          }),
                    ),
                  ] else if (uploadStatus == 1) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: primaryColor), // Added color
                          SizedBox(height: 10),
                          Text('Uploading Image...', style: TextStyle(color: primaryColor)),
                        ],
                      ),
                    ),
                  ] else if (uploadStatus == 2) ...[
                     Center(
                       child: Column(
                         children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 50),
                            SizedBox(height: 10),
                            Text('Image Uploaded!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            SizedBox(height: 20),
                           ElevatedButton(
                             style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                             ),
                             child: const Text('Submit Request'), // Changed text for clarity
                             onPressed: () {
                               // Basic validation before submitting
                               if (_formKey.currentState!.validate() && location != null && imageURL != null) {
                                  FirebaseFirestore.instance.collection('Request').add({
                                    'Description': descriptionController.text,
                                    'UserID': _user.uid,
                                    'Location': geopoint!.data, // Use geopoint! as it's checked for null
                                    'ImageURL': imageURL,
                                    'Animal': animalController.text,
                                    'IsCompleted': false,
                                    'HelperUID': '',
                                    'Timestamp': FieldValue.serverTimestamp(), // Added timestamp
                                  }).then((value) {
                                     // Explicitly cast context to BuildContext
                                     ScaffoldMessenger.of(context as BuildContext).showSnackBar(
                                        const SnackBar(content: Text('Request Submitted Successfully!')),
                                      );
                                      Navigator.pushReplacement( // Use pushReplacement to prevent going back to form
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => HomePage( // Assuming HomePage exists
                                              user: _user,
                                            )),
                                      );
                                  }).catchError((error) {
                                     print('Error submitting request: $error'); // Print error for debugging
                                     // Explicitly cast context to BuildContext
                                     ScaffoldMessenger.of(context as BuildContext).showSnackBar(
                                        SnackBar(content: Text('Failed to submit request: $error')),
                                      );
                                  });
                                } else {
                                   // Explicitly cast context to BuildContext
                                   ScaffoldMessenger.of(context as BuildContext).showSnackBar(
                                      const SnackBar(content: Text('Please fill in all details, choose a location, and upload an image.')),
                                    );
                                }
                             },
                           ),
                         ],
                       ),
                     ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RequestFormSubmitted extends StatefulWidget {
  const RequestFormSubmitted({Key? key, required UserModel user})
      : _user = user,
        super(key: key);

  final UserModel _user;

  @override
  _RequestFormSubmittedState createState() => _RequestFormSubmittedState();
}

// Removed the incorrect duplicate definition of _RequestFormSubmittedState


class _RequestFormSubmittedState extends State<RequestFormSubmitted> {
  late UserModel _user;

  @override
  void initState() {
    _user = widget._user;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 4, 50, 88);

    return Scaffold(
        backgroundColor: Colors.white, // Changed background to white
        body: SafeArea(
            child: Padding( // Added padding
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch content
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 80), // Added a success icon
                  const SizedBox(height: 20.0),
                  Text(
                    "Request Submitted Successfully!",
                    style: TextStyle(
                      fontSize: 24, // Slightly larger font
                      fontWeight: FontWeight.bold, // Bold text
                      color: primaryColor, // Use primary color
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30.0), // Increased spacing
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15.0), // Increased padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      // Use pushReplacement to prevent going back to this screen
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => HomePage( // Assuming HomePage exists
                            user: _user,
                          ),
                        ),
                      );
                                  },
                    child: const Text(
                      'Go Home',
                      style: TextStyle(
                        fontSize: 18, // Adjusted font size
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5, // Slightly increased letter spacing
                      ),
                    ),
                  ),
                ],
              ),
            )));
  }
}

class setCurrentLocation extends StatefulWidget {
  const setCurrentLocation({Key? key, required UserModel user})
      : _user = user,
        super(key: key);
  final UserModel _user;
  @override
  State<setCurrentLocation> createState() => _setCurrentLocationState();
}

class _setCurrentLocationState extends State<setCurrentLocation> {
  late UserModel _user;
  late GoogleMapController _googleMapController;
  Position? currentPosition; // Make nullable to handle initial state before fetching
  var locationSetFlag = false;
  var newLatitude = 0.0;
  var newLongitude = 0.0;

  final Color primaryColor = const Color.fromARGB(255, 4, 50, 88);

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled.
      // Return an error to be handled by FutureBuilder
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied after requesting.
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever.
      // Guide the user to app settings to grant permissions.
      return Future.error(
          'Location permissions are permanently denied.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    // Get the current position only once
    currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    return currentPosition!; // Return the obtained position
  }

  void _sendDataBack(BuildContext context) {
    if (!locationSetFlag && currentPosition != null) { // Use the stored initial position if not set by tap
      newLatitude = currentPosition!.latitude; // Use currentPosition! as it's checked for null
      newLongitude = currentPosition!.longitude; // Use currentPosition! as it's checked for null
    } else if (!locationSetFlag && currentPosition == null){
        // Handle case where position couldn't be determined initially
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not determine current location. Please try again.')),
          );
        return; // Don't pop if location is not set
    }
    LatLng latLngToSendBack = LatLng(newLatitude, newLongitude);
    Navigator.pop(context, latLngToSendBack);
  }

  // Helper function to show dialog for location service disabled
  Future<void> _showLocationServiceDialog(BuildContext context) async {
    return showDialog<void>(
      context: context, // Use the passed BuildContext
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) { // Inner context for the dialog
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Please enable location services to use this feature.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss the dialog
                await Geolocator.openLocationSettings(); // Open location settings
              },
            ),
          ],
        );
      },
    );
  }

   // Helper function to show dialog for permission denied
  Future<void> _showPermissionDeniedDialog(BuildContext context, String message) async {
    return showDialog<void>(
      context: context, // Use the passed BuildContext
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) { // Inner context for the dialog
        return AlertDialog(
          title: const Text('Location Permission Denied'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
             TextButton(
              child: const Text('Open App Settings'),
              onPressed: () async {
                 Navigator.of(context).pop(); // Dismiss the dialog
                 await openAppSettings(); // Open app settings using permission_handler
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // passing this to our root
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
        backgroundColor: primaryColor,
        title: const Text(
          'Set Current Location',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _determinePosition(),
        builder: (BuildContext context, AsyncSnapshot<Position> snapshot) {
          if (snapshot.hasData) {
            // Store the initial position if successfully obtained
             if (!locationSetFlag && currentPosition == null) {
                currentPosition = snapshot.data!;
             }
            return Stack(alignment: Alignment.center, children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target:
                      LatLng(snapshot.data!.latitude, snapshot.data!.longitude),
                  zoom: 15,
                ),
                onMapCreated: (controller) => _googleMapController = controller,
                markers: Set<Marker>.of(
                  <Marker>{
                    Marker(
                      markerId: const MarkerId('currentLocation'),
                      position: locationSetFlag
                          ? LatLng(newLatitude, newLongitude)
                          : LatLng(snapshot.data!.latitude,
                              snapshot.data!.longitude),
                      infoWindow: const InfoWindow(
                        title: 'Your Current Location',
                      ),
                    )
                  },
                ),
                onTap: (LatLng position) {
                  setState(() {
                    locationSetFlag = true;
                    newLatitude = position.latitude;
                    newLongitude = position.longitude;
                  });
                },
              ),
              Positioned(
                bottom: 20, // Increased bottom padding
                child: ElevatedButton( // Changed to ElevatedButton for better styling options
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: primaryColor, // Text color
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Increased padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0), // More rounded corners
                      ),
                      elevation: 8, // Increased elevation
                    ),
                    child: const Text("Submit current location",
                        style: TextStyle(fontSize: 18)), // Adjusted font size
                    onPressed: () {
                      _sendDataBack(context);
                    }),
              )
            ]);
          } else if (snapshot.hasError) {
            // Handle different error types and show appropriate dialogs
            String errorMessage = snapshot.error.toString();
             if (errorMessage.contains('Location services are disabled.')) { // Added period for exact match
               _showLocationServiceDialog(context); // Pass context
             } else if (errorMessage.contains('Location permissions are denied.')) { // Added period for exact match
                _showPermissionDeniedDialog(context, 'Location access is required to set your current location.'); // Pass context
             } else if (errorMessage.contains('Location permissions are permanently denied.')) { // Added period for exact match
                 _showPermissionDeniedDialog(context, 'Location access was permanently denied. Please go to app settings to grant permissions.'); // Pass context
             }


            // Display a message while dialog is shown or if dialog is dismissed without granting
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 60, color: Colors.redAccent), // Slightly larger and different red
                    SizedBox(height: 20),
                     Text(
                       "Could not determine location.", // More general message
                       textAlign: TextAlign.center,
                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                     ),
                     SizedBox(height: 10),
                      Text(
                       "Details: ${errorMessage.replaceFirst('Exception:', '')}", // Display the specific error message in details, removed "Exception:"
                       textAlign: TextAlign.center,
                       style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                     ),
                     SizedBox(height: 30),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                           foregroundColor: Colors.white, backgroundColor: primaryColor,
                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(30.0),
                           ),
                            elevation: 8,
                        ),
                        onPressed: () {
                          // Retry determining position
                          setState(() {
                             // Trigger a rebuild to call _determinePosition again
                          });
                        },
                        child: const Text('Retry', style: TextStyle(fontSize: 18)),
                      ),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}