import 'package:flutter/material.dart';
import 'package:petlove/models/User_model.dart'; // Assuming UserModel is correct
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
// REMOVED: import 'package:fluttertoast/fluttertoast.dart'; // Already removed
import 'package:petlove/screens/join_NGO_form.dart'; // Assuming JoinForm is correct


class NGOsDisplay extends StatefulWidget {
  const NGOsDisplay({Key? key, required UserModel user})
      : _user = user,
        super(key: key);

  final UserModel _user;

  @override
  State<NGOsDisplay> createState() => _NGOsDisplayState();
}

class _NGOsDisplayState extends State<NGOsDisplay> {
  // FirebaseFirestore firestore = FirebaseFirestore.instance; // Already accessible via FirebaseFirestore.instance
  var joinstat = 0; // This variable doesn't seem used
  late UserModel _user;

  final CollectionReference _requestReference =
      FirebaseFirestore.instance.collection('NGOs');
  late final Stream<QuerySnapshot> _requestStream =
      _requestReference.snapshots();

  @override
  void initState() {
    super.initState(); // Always call super.initState() first
    _user = widget._user;
  }

  @override
  Widget build(BuildContext context) {
    // It's generally better practice not to wrap the entire screen content
    // in a MaterialApp inside a builder. MaterialApp should usually be at the root
    // of your application (in main.dart). If this screen is navigated to
    // from another screen using Navigator, return Scaffold directly instead of MaterialApp(home: Scaffold(...)).
    // However, to fix the syntax error in the code you provided, we'll add the semicolon.
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // passing this to our root
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 4, 50, 88),
        title: const Text(
          'Available NGOs',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: _requestStream,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              print('StreamBuilder Error: ${snapshot.error}'); // Log the error
              return const Center(child: Text('Something went wrong loading NGOs.'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Check if data exists AND is not empty
             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
               return const Center(child: Text("No NGOs found."));
            }


            return ListView(
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                 // Use try-catch for safer data access and casting
                Map<String, dynamic> data;
                try {
                   data = document.data()! as Map<String, dynamic>;
                } catch (e) {
                   print("Error casting NGO document data for ${document.id}: $e");
                   return const SizedBox.shrink(); // Return an empty widget for bad data
                }


                return Padding(
                  padding: const EdgeInsets.all(8.0), // Adjusted padding
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to NGODetail on card tap
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NGODetail(
                                  document: data,
                                )),
                      );
                    },
                    child: Card(
                      elevation: 3, // Added slight elevation
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            leading: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[200], // Placeholder
                              backgroundImage: data['dpURL'] != null && (data['dpURL'] as String).isNotEmpty // Check for null or empty string
                                  ? CachedNetworkImageProvider(data['dpURL'])
                                  : null, // Handle null/empty dpURL
                              child: (data['dpURL'] == null || (data['dpURL'] as String).isEmpty)
                                   ? const Icon(Icons.group, color: Colors.grey) // Placeholder icon
                                   : null,
                            ),
                            title: Text(
                              data['Organization'] ?? 'Unknown NGO', // Default value
                              style: const TextStyle(
                                color: Color.fromARGB(255, 4, 50, 88),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                             // Optional: Add subtitle like email or location summary
                             subtitle: Text(data['email'] ?? '', style: const TextStyle(fontSize: 14)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              TextButton(
                                child: const Text(
                                  'View',
                                  style: TextStyle(fontSize: 15),
                                ),
                                onPressed: () {
                                   // Navigate to NGODetail on button press
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => NGODetail(
                                              document: data,
                                            )),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              Padding(
                                padding: const EdgeInsets.all(8.0), // Adjusted padding
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom( // Added style for consistent look
                                     foregroundColor: Colors.white, // Ensure text color is white
                                  ),
                                  child: const Text(
                                    'Join',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  onPressed: () async {
                                    // Check if user is already in an NGO
                                    // Ensure ngo_uid check is robust (null or empty string)
                                    if (_user.ngo_uid != null && _user.ngo_uid!.isNotEmpty) {
                                      // Use ScaffoldMessenger for feedback
                                      if (mounted) { // Check if the widget is still in the widget tree
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("You are already a member of an NGO"),
                                            duration: Duration(seconds: 4), // Optional: customize duration
                                          ),
                                        );
                                      }
                                    } else {
                                      // Navigate to the join form if not already in an NGO
                                      print("Navigating to JoinForm for NGO UID: ${data['uid']}");
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => JoinForm( // Ensure JoinForm exists and takes user and ngo_uid
                                                  user: _user, // Pass the user object
                                                  ngo_uid: data['uid'], // Pass the NGO's UID
                                                )),
                                      );

                                      // The commented-out update logic below is likely handled
                                      // in the JoinForm submission process.

                                      // await FirebaseFirestore.instance
                                      //     .collection('users')
                                      //     .doc(_user.uid)
                                      //     .update({
                                      //       'ngo_uid': data!['uid'],
                                      //     })
                                      //     .then((value) => print("success"))
                                      //     .catchError((error) =>
                                      //         print('Failed: $error'));
                                      // Fluttertoast.showToast(
                                      //     msg: "Request sent Successfully!"); // Old toast
                                    }
                                  },
                                ),
                              ),
                              // const SizedBox(width: 16), // Removed extra SizedBox
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
    )); // ADD SEMICOLON HERE
  }
}

// The NGODetail class does not use Fluttertoast, so no changes are needed here
// regarding the toast replacement. Kept for completeness.
class NGODetail extends StatelessWidget {
  const NGODetail({required Map<String, dynamic>? document, Key? key})
      : data = document,
        super(key: key);

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
     // Added null check for data
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('NGO Details Error')),
        body: const Center(child: Text("NGO data not available.")),
      );
    }

    return Scaffold( // Return Scaffold directly
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // passing this to our root
                  Navigator.of(context).pop();
                },
              ),
              elevation: 0,
              backgroundColor: const Color.fromARGB(255, 4, 50, 88),
              title: const Text(
                'NGO Details',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: ListView(
              children: <Widget>[
                Container(
                  height: 250,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 4, 50, 88),
                        Color.fromARGB(255, 66, 152, 173)
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0.5, 0.9],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          // Use conditional rendering based on dpURL existence and validity
                          CircleAvatar(
                            backgroundColor: Colors.white70,
                            minRadius: 60.0,
                            child: (data!['dpURL'] != null && (data!['dpURL'] as String).isNotEmpty)
                                ? CircleAvatar(
                                    backgroundColor: Colors.grey,
                                    backgroundImage:
                                        CachedNetworkImageProvider(data!['dpURL']),
                                    radius: 50,
                                  )
                                : const CircleAvatar( // Placeholder if no dpURL
                                    backgroundColor: Colors.grey,
                                    child: Icon(
                                      Icons.group,
                                      size: 50,
                                      color: Colors.blueGrey,
                                    ),
                                    radius: 50,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                       // Optional: Add NGO name below avatar
                       Text(data!['Organization'] ?? 'Unknown NGO', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                       const SizedBox(height: 5),
                       Text(data!['email'] ?? '', style: TextStyle(fontSize: 16, color: Colors.white70)),
                    ],
                  ),
                ),
                Container( // Changed this to a Column to hold ListTiles directly
                   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Add padding
                   child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                    children: <Widget>[
                      ListTile( // Use ListTile or just Text widgets here
                         contentPadding: EdgeInsets.zero, // Remove default padding if container has it
                         title: const Text(
                           'Organization Name', // More specific title
                           style: TextStyle(
                             color: Color.fromARGB(255, 4, 50, 88),
                             fontSize: 20,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         subtitle: Text(
                           data!['Organization'] ?? 'N/A', // Default value
                           style: const TextStyle(
                             color: Colors.black,
                             fontSize: 18,
                           ),
                         ),
                       ),
                       const Divider(), // Separator
                       ListTile(
                          contentPadding: EdgeInsets.zero, // Remove default padding
                         title: const Text(
                           'Email',
                           style: TextStyle(
                             color: Color.fromARGB(255, 4, 50, 88),
                             fontSize: 20,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         subtitle: Text(
                           data!['email'] ?? 'N/A', // Default value
                           style: const TextStyle(
                             color: Colors.black,
                             fontSize: 18,
                           ),
                         ),
                       ),
                       const Divider(), // Separator
                       // Add other details here using ListTile or similar structure
                       ListTile(
                          contentPadding: EdgeInsets.zero, // Remove default padding
                          title: const Text(
                           'Description',
                           style: TextStyle(
                             color: Color.fromARGB(255, 4, 50, 88),
                             fontSize: 20,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         subtitle: Text(
                           data!['Description'] ?? 'No description provided.', // Assuming 'Description' field exists
                           style: const TextStyle(
                             color: Colors.black,
                             fontSize: 18,
                           ),
                         ),
                       ),
                       const Divider(), // Separator
                       // Add Location, Contact, etc. if available in NGO data


                       const SizedBox(
                         height: 20,
                       ),
                       Center( // Center the button
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom( // Use ElevatedButton.styleFrom
                              backgroundColor: const Color.fromARGB(255, 4, 50, 88),
                              foregroundColor: Colors.white, // Text color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0), // Adjust padding
                            ),
                            onPressed: () {
                                // This button doesn't seem to do anything in the original code.
                                // You might want to add logic here, e.g., navigate to the JoinForm again,
                                // or simply remove the button if redundant.
                                // For now, keeping it and adding a print statement.
                                print("Join button pressed on detail page.");
                                // Example: Navigate to JoinForm
                                // Navigator.push(context, MaterialPageRoute(builder: (context) => JoinForm(user: your_user_object, ngo_uid: data['uid'])));
                                // Note: You'll need access to the current user object here if you want to navigate to JoinForm
                            },
                            child: const Text(
                              'Join This NGO', // More descriptive text
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                       ),
                        const SizedBox(height: 20), // Spacing at the bottom
                    ],
                  ),
                ),
              ],
            ));
  }
}

// Ensure UserModel and JoinForm classes are defined in their respective files.
// Removed duplicate MaterialApp from NGODetail as well, as it's likely used as a route.