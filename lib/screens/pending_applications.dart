import 'package:flutter/material.dart';
import 'package:petlove/models/NGO_model.dart'; // Assuming NGOModel is correct
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
// REMOVED: import 'package:fluttertoast/fluttertoast.dart'; // Ensure this is removed
import 'package:petlove/models/User_model.dart'; // Assuming UserModel is correct
// If ApplicationDetail is in a separate file, you'll need to import it:
// import 'package:petlove/screens/application_detail.dart'; // Example import


class pendingappls extends StatefulWidget {
  const pendingappls({Key? key, required NGOModel NGO})
      : _NGO = NGO,
        super(key: key);

  final NGOModel _NGO;
  @override
  State<pendingappls> createState() => _pendingapplsState();
}

class _pendingapplsState extends State<pendingappls> {
  // Removed unused state variables: firestore, joinstat, user state variable
  late NGOModel _NGO;

  @override
  void initState() {
    super.initState(); // Always call super.initState() first
    _NGO = widget._NGO;
  }

  final CollectionReference _joinngoReference =
      FirebaseFirestore.instance.collection('JoinRequests');

  // Filter stream by ngo_uid and status 'pending'
  late final Stream<QuerySnapshot> _joinngostream = _joinngoReference
      .where('ngo_uid', isEqualTo: _NGO.uid)
      .where('status', isEqualTo: "pending") // Corrected status filter from 'ongoing' to 'pending'
      .snapshots();

  // Function to fetch applicant details
  Future<UserModel?> _fetchApplicantDetails(String? uid) async {
    if (uid == null || uid.isEmpty) {
      print("Error: Attempted to fetch user with null or empty UID.");
      return null;
    }
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        // Corrected cast
        Map<String, dynamic> userData = userDoc.data()! as Map<String, dynamic>;
        // Assuming UserModel has fields like displayName, email, photoURL, ngo_uid
        // If your UserModel has a fromMap constructor, use that:
        // return UserModel.fromMap(userData);
        // Otherwise, manually create it (ensure all relevant fields are included):
        return UserModel(
          uid: uid,
          displayName: userData['displayName'] as String?,
          email: userData['email'] as String?,
          photoURL: userData['photoURL'] as String?,
          ngo_uid: userData['ngo_uid'] as String?,
          // Add any other fields your UserModel has from the 'users' collection
        );
      } else {
        print("User document not found for UID: $uid");
        // Don't show Snackbar here, as it might happen on stream updates
        return null;
      }
    } catch (e) {
      print("Error fetching user details for UID $uid: $e");
      // Don't show Snackbar here
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    // *** IMPORTANT FIX: Return Scaffold directly, not MaterialApp(home: Scaffold(...)) ***
    // This widget is intended to be a screen/route within a main MaterialApp.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 4, 50, 88),
        title: const Text(
          'Pending Applications',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: _joinngostream,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
               print('StreamBuilder Error: ${snapshot.error}'); // Log the error
              return const Center(child: Text('Something went wrong loading applications.'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

             // Check if data exists AND is not empty
             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
               return const Center(child: Text("No pending applications found."));
            }

            // Filter out any documents that might have somehow slipped through the filter
            // or have critical missing data before building the ListView
            var filteredDocs = snapshot.data!.docs.where((document) {
                 try {
                   Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                   String? applicantUid = data['uid'] as String?;
                   // Ensure ngo_uid is present and matches, and status is pending, and contact exists
                   return data.containsKey('ngo_uid') && data['ngo_uid'] == _NGO.uid &&
                          data.containsKey('status') && data['status'] == 'pending' &&
                          applicantUid != null && applicantUid.isNotEmpty &&
                          data.containsKey('contact'); // Ensure contact is available for the list tile title
                 } catch (e) {
                   print("Error validating JoinRequest document ${document.id}: $e");
                   return false; // Exclude this document
                 }
            }).toList();

            if (filteredDocs.isEmpty) {
               return const Center(child: Text("No pending applications found matching criteria."));
            }


            return ListView(
              children: filteredDocs.map((DocumentSnapshot document) {
                // Corrected cast - safe because we filtered above
                Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

                var id = document.id; // Document ID of the join request
                String applicantUid = data['uid'] as String; // Applicant's User UID (guaranteed by filter)


                return Padding(
                  padding: const EdgeInsets.all(8.0), // Adjusted padding
                  child: GestureDetector(
                    onTap: () async {
                      // Fetch user details and navigate to ApplicationDetail
                      // Use push instead of pushAndRemoveUntil unless you really want to clear the stack
                      UserModel? applicantUser = await _fetchApplicantDetails(applicantUid);
                       if (applicantUser != null && mounted) {
                         Navigator.push(
                             context,
                             MaterialPageRoute(
                                 builder: (context) => ApplicationDetail(
                                       document: data, // Pass JoinRequest data
                                       user: applicantUser, // Pass Applicant User data
                                     )),
                           );
                       } else {
                         // Show error if user details couldn't be fetched
                         if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Could not load applicant details.')),
                           );
                         }
                       }
                    },
                    child: Card(
                      elevation: 3, // Added elevation
                      child: Column(
                        children: <Widget>[
                          ListTile(
                             leading: const Icon(Icons.person_outline, size: 40, color: Color.fromARGB(255, 4, 50, 88)), // Generic icon as user dp is in detail view
                            title: Text(
                              data['contact'] ?? 'Contact N/A', // Handle null (though filtered, adding ?? is safer)
                              style: const TextStyle(
                                color: Color.fromARGB(255, 4, 50, 88),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(data['description'] ?? 'No description provided.', // Display description here too
                               style: const TextStyle(fontSize: 14)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              TextButton(
                                child: const Text(
                                  'View',
                                  style: TextStyle(fontSize: 15),
                                ),
                                onPressed: () async {
                                   // Fetch user details and navigate to ApplicationDetail
                                  UserModel? applicantUser = await _fetchApplicantDetails(applicantUid);
                                  if (applicantUser != null && mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ApplicationDetail(
                                                document: data, // Pass JoinRequest data
                                                user: applicantUser, // Pass Applicant User data
                                              )),
                                    );
                                  } else {
                                    // Show error if user details couldn't be fetched
                                     if (mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                         const SnackBar(content: Text('Could not load applicant details.')),
                                       );
                                     }
                                  }
                                },
                              ),
                              const SizedBox(width: 16),
                              Padding(
                                padding: const EdgeInsets.all(8.0), // Adjusted padding
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom( // Added style
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text(
                                    'Accept',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  onPressed: () async {
                                    if (applicantUid.isEmpty || id.isEmpty) { // Check against empty string now
                                       print("Error: Cannot accept - missing UIDs.");
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Error accepting request. Missing data.")),
                                          );
                                        }
                                       return;
                                    }

                                    try {
                                      DocumentSnapshot userDoc =
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(applicantUid) // Use applicantUid
                                              .get();
                                      Map<String, dynamic> userdata = userDoc
                                          .data()! as Map<String, dynamic>;

                                      // Check if user is already part of ANY NGO
                                      // Use safe access and check for null or empty string
                                      String? currentUserNgoUid = userdata['ngo_uid'] as String?;

                                      if (currentUserNgoUid == null || currentUserNgoUid.isEmpty) {
                                        // Update user's ngo_uid and request status
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(applicantUid) // Use applicantUid
                                            .update({'ngo_uid': _NGO.uid}); // Assign to this NGO
                                        await FirebaseFirestore.instance
                                            .collection('JoinRequests')
                                            .doc(id) // Use join request document ID
                                            .update({'status': 'accepted', 'acceptedTimestamp': FieldValue.serverTimestamp()}); // Update status and add timestamp

                                        // Show success message via SnackBar
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Application Accepted! Volunteer added :)")),
                                          );
                                        }
                                      } else {
                                        // User is already in an NGO
                                         if (mounted) {
                                           ScaffoldMessenger.of(context).showSnackBar(
                                             const SnackBar(content: Text("User is already registered in an NGO :(")),
                                           );
                                         }
                                      }
                                    } catch (e) {
                                       print("Error accepting application ${id}: $e");
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Failed to accept application: ${e.toString()}")),
                                          );
                                        }
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Padding(
                                padding: const EdgeInsets.all(8.0), // Adjusted padding
                                child: ElevatedButton(
                                   style: ElevatedButton.styleFrom( // Added style
                                     foregroundColor: Colors.white,
                                     backgroundColor: Colors.redAccent, // Indicate rejection
                                  ),
                                  child: const Text(
                                    'Reject',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  onPressed: () async {
                                     if (id.isEmpty) { // Check against empty string now
                                        print("Error: Cannot reject - missing request ID.");
                                         if (mounted) {
                                           ScaffoldMessenger.of(context).showSnackBar(
                                             const SnackBar(content: Text("Error rejecting request. Missing data.")),
                                           );
                                         }
                                        return;
                                     }
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('JoinRequests')
                                          .doc(id) // Use join request document ID
                                          .update({'status': 'rejected', 'rejectedTimestamp': FieldValue.serverTimestamp()}); // Update status and add timestamp

                                      // Show success message via SnackBar
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Application Rejected.")),
                                        );
                                      }
                                    } catch (e) {
                                       print("Error rejecting application ${id}: $e");
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Failed to reject application: ${e.toString()}")),
                                          );
                                        }
                                    }
                                  },
                                ),
                              ),
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
    ); // Semicolon here, after returning Scaffold
  }

  // Removed the Applicantdetails function as its logic is now inline in _fetchApplicantDetails

}

// Assuming ApplicationDetail is defined in this file or imported from elsewhere.
// Updated to return Scaffold directly and added basic null checks/defaults.
class ApplicationDetail extends StatelessWidget {
  const ApplicationDetail(
      {required Map<String, dynamic>? document, // JoinRequest data
      required UserModel user, // Applicant User data
      Key? key})
      : data = document,
        user = user, // User is required, so it won't be null if passed correctly
        super(key: key);

  final Map<String, dynamic>? data; // JoinRequest data
  final UserModel user; // Applicant User data

  @override
  Widget build(BuildContext context) {
     // Add null checks for data object (user is required, so it won't be null).
     if (data == null) {
       return Scaffold(
         appBar: AppBar(title: const Text('Application Details Error')),
         body: const Center(child: Text("Application data not available.")),
       );
     }

    // *** IMPORTANT FIX: Return Scaffold directly, not MaterialApp(home: Scaffold(...)) ***
    // This widget is intended to be a screen/route within a main MaterialApp.
    return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              elevation: 0,
              backgroundColor: const Color.fromARGB(255, 4, 50, 88),
              title: const Text(
                'Application Details',
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
                          // Use conditional rendering based on user.photoURL existence and validity
                           CircleAvatar(
                             backgroundColor: Colors.white70,
                             minRadius: 60.0,
                             child: (user.photoURL != null && user.photoURL!.isNotEmpty) // Check for null or empty string
                                 ? CircleAvatar(
                                     backgroundColor: Colors.grey,
                                     backgroundImage: CachedNetworkImageProvider(user.photoURL!), // Use ! after checking for null/empty
                                     radius: 50,
                                   )
                                 : const CircleAvatar( // Placeholder if no photo
                                     backgroundColor: Colors.grey,
                                     child: Icon(
                                       Icons.person,
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
                      // Optional: Add applicant name below avatar
                       Text(user.displayName ?? 'Unknown Applicant', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                       const SizedBox(height: 5),
                       Text(user.email ?? '', style: TextStyle(fontSize: 16, color: Colors.white70)),

                    ],
                  ),
                ),
                 Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: <Widget>[
                      ListTile(
                         contentPadding: EdgeInsets.zero,
                         title: const Text(
                           'Name',
                           style: TextStyle(
                             color: Color.fromARGB(255, 4, 50, 88),
                             fontSize: 20,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         subtitle: Text(
                           user.displayName ?? 'N/A', // Default value
                           style: const TextStyle(
                             color: Colors.black,
                             fontSize: 18,
                           ),
                         ),
                       ),
                       const Divider(),
                       ListTile(
                          contentPadding: EdgeInsets.zero,
                         title: const Text(
                           'Email',
                           style: TextStyle(
                             color: Color.fromARGB(255, 4, 50, 88),
                             fontSize: 20,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         subtitle: Text(
                           user.email ?? 'N/A', // Default value
                           style: const TextStyle(
                             color: Colors.black,
                             fontSize: 18,
                           ),
                         ),
                       ),
                       const Divider(),
                       ListTile(
                         contentPadding: EdgeInsets.zero,
                         title: const Text(
                           'Contact',
                           style: TextStyle(
                             color: Color.fromARGB(255, 4, 50, 88),
                             fontSize: 20,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         subtitle: Text(
                           data!['contact'] ?? 'N/A', // Default value
                           style: const TextStyle(
                             color: Colors.black,
                             fontSize: 18,
                           ),
                         ),
                       ),
                       const Divider(),
                       ListTile(
                         contentPadding: EdgeInsets.zero,
                         title: const Text(
                           'Description',
                           style: TextStyle(
                             color: Color.fromARGB(255, 4, 50, 88),
                             fontSize: 20,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         subtitle: Text(
                           data!['description'] ?? 'No description provided.', // Default value
                           style: const TextStyle(
                             color: Colors.black,
                             fontSize: 18,
                           ),
                         ),
                       ),
                       const Divider(),
                       // Add timestamp if you added it to your JoinModel and Firestore
                        if (data!['timestamp'] is Timestamp) // Check if timestamp exists and is a Timestamp
                           ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Application Date',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 4, 50, 88),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                 (data!['timestamp'] as Timestamp).toDate().toString(), // Format as string
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                ),
                              ),
                           ),
                         const Divider(),
                          if (data!['status'] != null) // Display status
                           ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Status',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 4, 50, 88),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                 data!['status'].toString(), // Display status
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                ),
                              ),
                           ),
                         // Check for and display accepted/rejected timestamps if they exist
                         if (data!['acceptedTimestamp'] is Timestamp)
                           ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Accepted Date',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 4, 50, 88),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                 (data!['acceptedTimestamp'] as Timestamp).toDate().toString(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                ),
                              ),
                           ),
                         if (data!['rejectedTimestamp'] is Timestamp)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Rejected Date',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 4, 50, 88),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                 (data!['rejectedTimestamp'] as Timestamp).toDate().toString(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                ),
                              ),
                           ),


                     ],
                   ),
                 ),
              ],
            ), // This closes the ListView
    ); // This closes the Scaffold. It needs a semicolon here.
  } // This closes the build method.
// No semicolon needed after the closing brace of the build method unless it's an expression body => ... ;

} // This closes the ApplicationDetail class. No semicolon here.