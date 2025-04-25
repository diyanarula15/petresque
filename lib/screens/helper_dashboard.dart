import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petlove/models/User_model.dart'; // Correct source for UserModel
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Required for CachedNetworkImage
import 'package:petlove/screens/help_request_display_user.dart'; // Assuming RequestDetailWithoutHelper is correct
import 'package:url_launcher/url_launcher.dart'; // ADDED
import 'package:petlove/screens/ai_first_aid_chat.dart'; // Import the AI chat screen


// You might need a separate screen for request details without helper actions
// For simplicity here, I'm including a basic placeholder class
class RequestDetailWithoutHelper extends StatelessWidget {
  final Map<String, dynamic> document;
  final String requestId; // Added requestId if needed for actions on the detail screen
  const RequestDetailWithoutHelper({Key? key, required this.document, required this.requestId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
      final Color primaryColor = const Color.fromARGB(255, 4, 50, 88);
    // Placeholder implementation
    return Scaffold(
      appBar: AppBar(
        title: Text(document['Animal'] ?? 'Request Details', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView( // Changed to ListView for scrollability
          children: [
             Text('Animal: ${document['Animal'] ?? 'N/A'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
             Text('Description:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
             Text(document['Description'] ?? 'No description', style: const TextStyle(fontSize: 16)),
             const SizedBox(height: 16),
             if (document['Location'] != null && document['Location']['geopoint'] != null)
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('Location:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   Text('Lat: ${document['Location']['geopoint'].latitude.toStringAsFixed(4)}, Lng: ${document['Location']['geopoint'].longitude.toStringAsFixed(4)}', style: const TextStyle(fontSize: 16)),
                   const SizedBox(height: 8),
                    // Button to launch map from details
                   ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: primaryColor,
                      ),
                      onPressed: () {
                          // Call the _launchMap function (need access to it, or define it here)
                          // For simplicity, you might redefine a similar launch function here or pass it
                          _launchMapFromDetail(document['Location']['geopoint'], context);
                      },
                       icon: Icon(Icons.map),
                       label: Text('View on Map'),
                    ),
                 ],
               ),
             const SizedBox(height: 16),
             if (document['ImageURL'] != null && document['ImageURL'].isNotEmpty)
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('Image:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Center( // Center the image
                     child: CachedNetworkImage(
                        imageUrl: document['ImageURL'],
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error, size: 50),
                         height: 200, // Larger height for detail view
                         fit: BoxFit.contain,
                      ),
                   ),
                 ],
               ),
             const SizedBox(height: 16),
             // Add more details here as needed (e.g., timestamp, user info if available)

             // Example action buttons for a helper
              Center(
                 child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      // TODO: Implement logic to mark request as completed
                       ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mark as Completed (Functionality not implemented)')),
                        );
                    },
                    child: Text('Mark as Completed'),
                 ),
              ),
              const SizedBox(height: 10),
               Center(
                 child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () {
                      // TODO: Implement logic to decline/unassign request
                       ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Decline Assignment (Functionality not implemented)')),
                        );
                    },
                    child: Text('Decline Assignment'),
                 ),
              ),
          ],
        ),
      ),
    );
  }

    // Define _launchMapFromDetail function here or pass it from parent
    Future<void> _launchMapFromDetail(GeoPoint geoPoint, BuildContext context) async {
      // Use a standard Google Maps web URL format for launchUrl
      // This format often opens in the native app if installed, or falls back to the web.
      final String googleMapsUrl =
          "http://maps.google.com/?q=${geoPoint.latitude},${geoPoint.longitude}"; // Corrected URL format

      final Uri mapUri = Uri.parse(googleMapsUrl);

      try {
        if (await canLaunchUrl(mapUri)) {
          await launchUrl(mapUri, mode: LaunchMode.externalApplication);
        } else {
          // Using ScaffoldMessenger outside of the State requires checking for mounted
          if (Navigator.of(context).context.mounted) { // Check if context is mounted
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Could not open map application.')),
             );
          }
        }
      } catch (e) {
        print('Error launching map from detail: $e');
         if (Navigator.of(context).context.mounted) { // Check if context is mounted
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error opening map: ${e.toString()}')),
            );
         }
      }
    }
}


class HelperAssignedRequests extends StatefulWidget {
  const HelperAssignedRequests({Key? key, required UserModel user})
      : _user = user,
        super(key: key);

  final UserModel _user;

  @override
  State<HelperAssignedRequests> createState() => _HelperAssignedRequestsState();
}

class _HelperAssignedRequestsState extends State<HelperAssignedRequests> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  final CollectionReference _requestReference =
      FirebaseFirestore.instance.collection('Request');

  // Making the stream final as it shouldn't change after initialization
  late final Stream<QuerySnapshot> _requestStream = _requestReference
      .where('HelperUID', isEqualTo: widget._user.uid)
      .where('IsCompleted', isEqualTo: false) // Filter for incomplete requests
      .snapshots();

  // --- Helper function to launch map ---
  Future<void> _launchMap(GeoPoint geoPoint, BuildContext context) async {
    // Use a standard Google Maps web URL format
    // This format often opens in the native app if installed, or falls back to the web.
    final String googleMapsUrl =
        "http://maps.google.com/?q=${geoPoint.latitude},${geoPoint.longitude}"; // Corrected URL format

    // Parse the string into a Uri object
    final Uri mapUri = Uri.parse(googleMapsUrl);

    try {
      // Use canLaunchUrl and launchUrl from url_launcher
      if (await canLaunchUrl(mapUri)) {
        // Use externalApplication mode to prefer opening in a dedicated map app
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch map for URI: $mapUri');
        // Show feedback to the user if the map couldn't be opened
        if (mounted) { // Check if the widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open map application. Please ensure you have a map app installed.')),
          );
        }
      }
    } catch (e) {
      print('Error launching map: $e');
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening map: ${e.toString()}')), // Show error message
          );
      }
    }
  }
  // --- End of helper function ---


  // Function to show the AI Chat as a modal window (Copied from HomePage)
  void _showAiChatWindow(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true, // Dismiss the dialog when tapping outside
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54, // Semi-transparent barrier
      transitionDuration: const Duration(milliseconds: 300), // Animation duration
      pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        // Use a Center widget to size and position the chat window
        return Center(
          child: Container(
            width: MediaQuery.of(buildContext).size.width * 0.9, // 90% of screen width
            height: MediaQuery.of(buildContext).size.height * 0.7, // 70% of screen height
            child: ClipRRect( // Clip corners for a window effect
               borderRadius: BorderRadius.circular(16.0),
               child: AiFirstAidChatScreen(), // The chat screen content
            ),
            decoration: BoxDecoration( // Optional: Add a subtle shadow or border
               boxShadow: [
                 BoxShadow(
                   color: Colors.black26,
                   blurRadius: 10.0,
                   spreadRadius: 2.0,
                 ),
               ],
            ),
          ),
        );
      },
       transitionBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
         // Add a scaling transition
         return ScaleTransition(
           scale: CurvedAnimation(
             parent: animation,
             curve: Curves.easeOut,
           ),
           child: child,
         );
       },
    );
  }


  @override
  Widget build(BuildContext context) {
      final Color primaryColor = const Color.fromARGB(255, 4, 50, 88); // Define primary color

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Requests', style: TextStyle(color: Colors.white)), // Set title color
        backgroundColor: primaryColor, // Use primary color
        elevation: 0,
      ),
      body: Stack( // Use Stack to position FAB
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0), // Added padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Requests assigned to you:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                Expanded( // Use Expanded to make the list fill available space
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _requestStream,
                    builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No assigned requests found.', style: TextStyle(color: Colors.grey)));
                      }

                      return ListView(
                        children: snapshot.data!.docs.map((DocumentSnapshot document) {
                          Map<String, dynamic> data =
                              document.data()! as Map<String, dynamic>;
                          // Display request details clearly
                          return Card(
                              elevation: 2.0, // Subtle elevation
                              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), // Add margin
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Rounded corners
                              child: ListTile(
                                leading: Icon(Icons.pets, color: primaryColor), // Icon for the request
                                title: Text(data['Animal'] ?? 'Unknown Animal', style: TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['Description'] ?? 'No description', maxLines: 2, overflow: TextOverflow.ellipsis), // Limit description lines
                                    if (data['Location'] != null && data['Location']['geopoint'] != null) // Check for null geopoint
                                      Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: GestureDetector( // Make location clickable to open map
                                             onTap: () => _launchMap(data['Location']['geopoint'], context),
                                             child: Text('Location: ${data['Location']['geopoint'].latitude.toStringAsFixed(4)}, ${data['Location']['geopoint'].longitude.toStringAsFixed(4)}',
                                                   style: TextStyle(fontSize: 12, color: primaryColor, decoration: TextDecoration.underline)), // Style as a link
                                           ),
                                         ),
                                    if (data['ImageURL'] != null && data['ImageURL'].isNotEmpty)
                                      Padding(
                                         padding: const EdgeInsets.only(top: 8.0),
                                         child: CachedNetworkImage( // Use CachedNetworkImage for efficiency
                                            imageUrl: data['ImageURL'],
                                            placeholder: (context, url) => CircularProgressIndicator(),
                                            errorWidget: (context, url, error) => Icon(Icons.error),
                                             height: 100, // Fixed height for image preview
                                             fit: BoxFit.cover,
                                          ),
                                        ),
                                  ],
                                ),
                                isThreeLine: true, // Allow subtitle to take up to 3 lines
                                trailing: Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.grey), // Add trailing icon
                                onTap: () {
                                   // Navigate to a detailed view of the request
                                    Navigator.push(
                                     context,
                                     MaterialPageRoute(
                                         builder: (context) => RequestDetailWithoutHelper( // Assuming this screen exists
                                                document: document.data()! as Map<String, dynamic>, // Pass the document data
                                                requestId: document.id, // Pass the document ID if needed
                                              )),
                                     );
                                },
                              ),
                            );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

           // Floating Action Button for the AI Chat Bot (Bottom Left) - Added for consistency
           Positioned(
             bottom: 16.0, // Standard bottom margin
             left: 16.0, // Standard left margin
             child: FloatingActionButton(
               heroTag: 'aiChatFabHelper', // Unique tag for this screen
               onPressed: () {
                  _showAiChatWindow(context); // Call the modal chat function
               },
               tooltip: 'Pet First Aid Bot',
               backgroundColor: primaryColor, // Use primary color
               foregroundColor: Colors.white, // Icon color
               child: const Icon(Icons.chat_bubble_outline), // Chat icon
             ),
           ),
        ],
      ),
      // Set floatingActionButtonLocation to null when using Stack for positioning
      floatingActionButtonLocation: null,
    );
  }

}

// REMOVED THE DUPLICATE DEFINITION OF RequestDetailWithoutHelper
/*
class RequestDetailWithoutHelper extends StatelessWidget {
  final Map<String, dynamic> document;
  const RequestDetailWithoutHelper({Key? key, required this.document}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder implementation
    return Scaffold(
      appBar: AppBar(
        title: Text(document['Animal'] ?? 'Request Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Animal: ${document['Animal'] ?? 'N/A'}'),
            Text('Description: ${document['Description'] ?? 'No description'}'),
            // Add more details here
          ],
        ),
      ),
    );
  }
}
*/

// REMOVED - THIS WAS THE DUPLICATE DEFINITION CAUSING THE ERROR
// class UserModel {
//    final String uid;
//    UserModel({required this.uid});
// }