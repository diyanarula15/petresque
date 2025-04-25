import 'package:flutter/material.dart';
import 'package:petlove/models/User_model.dart';
// Ensure these screen imports are correct for your project structure
import 'package:petlove/screens/account_page.dart';
import 'package:petlove/mainkk.dart'; // Contains MyCustomForm, potentially login screen
import 'package:petlove/screens/register_NGO.dart';
import 'package:petlove/screens/join_NGO.dart';
import 'package:petlove/screens/help_request_display_user.dart';
import 'package:petlove/screens/sign_in_screen.dart';
// *** FIXED IMPORT ***
import 'package:petlove/screens/update_user_profile.dart'; // Corrected 'package:'
import 'package:petlove/screens/helper_dashboard.dart';
import 'package:petlove/screens/ai_first_aid_chat.dart';
// Imports needed for Authentication & Logout (based on reference file)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:petlove/screens/sign_in_screen.dart'; // Assuming this is your login screen

// You might need this if your sign-out logic is in a separate file
// import 'package:petlove/utils/authentication.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required UserModel user})
      : _user = user,
        super(key: key);

  final UserModel _user;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late UserModel _user;
  bool _isSigningOut = false; // Track logout state

  final Color primaryColor =
      const Color.fromARGB(255, 4, 50, 88); // Define primary color
  final Color accentColor = Colors.orangeAccent; // Define a prominent accent color
  final Color cardBackgroundColor =
      Colors.blueGrey[50]!; // Lighter background for cards
  final Color cardTextColor =
      Colors.black87; // Darker text for readability on light cards

  // Sample News Data
  final List<Map<String, String>> newsItems = [
    {
      'title': 'Local Shelter Adoption Drive Success!',
      'snippet': 'Over 50 pets found forever homes last weekend...',
      'icon': 'pets' // Corresponds to Icons.pets
    },
    {
      'title': 'Tips for Keeping Pets Cool in Summer',
      'snippet': 'Learn how to prevent heatstroke in your furry friends.',
      'icon': 'thermostat' // Corresponds to Icons.thermostat
    },
    {
      'title': 'Volunteer Orientation Next Saturday',
      'snippet': 'Join our team and make a difference for animals in need.',
      'icon': 'volunteer_activism' // Corresponds to Icons.volunteer_activism
    },
  ];

  // Map string keys to actual Icons
  final Map<String, IconData> newsIcons = {
    'pets': Icons.pets,
    'thermostat': Icons.thermostat,
    'volunteer_activism': Icons.volunteer_activism,
  };

  @override
  void initState() {
    _user = widget._user;
    super.initState();
  }

  // Function to show the AI Chat as a modal window (Unchanged from your code)
  void _showAiChatWindow(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return Center(
          child: Container(
            width: MediaQuery.of(buildContext).size.width * 0.9,
            height: MediaQuery.of(buildContext).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white, // Added background color for the modal
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: AiFirstAidChatScreen(), // The chat screen content
            ),
          ),
        );
      },
      transitionBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) {
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

  // --- Logout Function (from reference logic) ---
  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
    });
    try {
      // Check if the user signed in with Google
      if (await GoogleSignIn().isSignedIn()) {
        await GoogleSignIn().signOut();
      }
      await FirebaseAuth.instance.signOut();
      // Navigate back to Login Screen after logout
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => SignInScreen()), // Ensure LoginScreen is imported
        (Route<dynamic> route) => false, // Remove all previous routes
      );
    } catch (e) {
      // Handle potential errors during sign out
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    } finally {
      // Ensure state is updated even if error occurs
      if (mounted) { // Check if the widget is still in the tree
       setState(() {
         _isSigningOut = false;
       });
      }
    }
  }
  // --- End Logout Function ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: const Text('Home', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [ // Added progress indicator during sign out
          if (_isSigningOut)
            const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  )),
            ),
        ],
      ),
      // --- Updated Drawer ---
      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: primaryColor,
            ),
            child: Column( // Added user info to header
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Menu', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(_user.displayName ?? 'User', style: TextStyle(fontSize: 16, color: Colors.white70)),
                Text(_user.email ?? '', style: TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
          // --- Drawer Items (Functionality aligned with reference code) ---
          ListTile(
            leading: Icon(Icons.person_outline, color: primaryColor), // Icon for Profile
            title: const Text("My Profile", style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AccountPage( // Navigate to AccountPage
                          user: _user,
                        )),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.edit_note_outlined, color: primaryColor), // Icon for Update Profile
            title: const Text("Update Profile", style: TextStyle(fontSize: 18)),
            onTap: () {
               Navigator.pop(context); // Close drawer
               // *** FIXED NAVIGATION ***
               Navigator.push(
                 context,
                 MaterialPageRoute(
                     // Navigate to the updateProfile screen (Widget class)
                     builder: (context) => updateProfile(
                           user: _user,
                         )),
               );
            },
          ),
          ListTile(
            leading: Icon(Icons.list_alt_outlined, color: primaryColor), // Icon for user's requests
            title: const Text("My Help Requests", style: TextStyle(fontSize: 18)),
            onTap: () {
               Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HelpRequestDisplayUser( // Navigate to user's requests screen
                          user: _user,
                        )),
              );
            },
          ),
          Divider(), // Separator
          ListTile(
            leading: Icon(Icons.group_add_outlined, color: primaryColor), // Icon for Join NGO
            title: const Text("Join NGO", style: TextStyle(fontSize: 18)),
            onTap: () {
               Navigator.pop(context); // Close drawer
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NGOsDisplay( // Navigate to NGOsDisplay
                      user: _user,
                    ),
                  ));
            },
          ),
          ListTile(
            leading: Icon(Icons.add_business_outlined, color: primaryColor), // Icon for Register NGO
            title: const Text("Register NGO", style: TextStyle(fontSize: 18)),
            onTap: () {
               Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NGOregistration( // Navigate to NGOregistration
                          uid: _user.uid, // Pass UID as per reference logic
                        )),
              );
            },
          ),
          // --- Conditional Item for Assigned Requests ---
          if (_user.ngo_uid != null) // Show only if part of an NGO
            ListTile(
              leading: Icon(Icons.assignment_turned_in_outlined, color: primaryColor), // Icon for Assigned Requests
              title: const Text("Assigned Requests", style: TextStyle(fontSize: 18)),
              onTap: () {
                 Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HelperAssignedRequests( // Navigate to HelperAssignedRequests
                            user: _user,
                          )),
                );
              },
            ),
          Divider(), // Separator
          // --- Logout Item ---
          ListTile(
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(fontSize: 18)),
            onTap: _isSigningOut ? null : () { // Disable button while signing out
              Navigator.pop(context); // Close drawer first
              _signOut(); // Call the sign out function
            },
          ),
        ]),
      ),
      // --- End Updated Drawer ---
      body: Stack(
        children: [
          // Main content of the home page
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0), // Increased bottom padding for FABs
              child: ListView( // Use ListView for scrollability
                children: [
                  Text(
                    'Welcome, ${(_user.displayName ?? 'User')}!', // Use interpolation
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Section for Quick Actions - MODIFIED
                  Card(
                    elevation: 3.0,
                    color: cardBackgroundColor, // Lighter background
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quick Action', // Singular now
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor)),
                          SizedBox(height: 15),
                          Center( // Center the single button
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, // White text/icon on button
                                backgroundColor: primaryColor, // Primary color button
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12), // Adjusted padding
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0)),
                                elevation: 2.0,
                              ),
                              onPressed: () {
                                // Navigate to create new request
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MyCustomForm(
                                            user: _user,
                                          )),
                                );
                              },
                              icon: Icon(Icons.add_circle_outline),
                              label: Text('Create Help Request'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20.0),

                  // Section for Helper Status/Requests Assigned (if user is a helper)
                  if (_user.ngo_uid != null)
                    Card(
                      elevation: 3.0,
                      color: cardBackgroundColor, // Lighter background
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your Assigned Requests',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor)),
                            SizedBox(height: 10),
                            // TODO: Implement a StreamBuilder here to show a summary of assigned requests
                            Text(
                                'View requests assigned to you by your NGO.', // Updated placeholder text
                                style: TextStyle(color: cardTextColor)),
                            SizedBox(height: 10),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                    foregroundColor: primaryColor),
                                onPressed: () {
                                  // Navigate to the helper dashboard
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            HelperAssignedRequests(
                                              user: _user,
                                            )),
                                  );
                                },
                                child: Text('View All Assigned'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_user.ngo_uid != null) const SizedBox(height: 20.0), // Spacing only if helper section shown

                  // Section for Recent Activity / News - UPDATED
                  Card(
                    elevation: 3.0,
                    color: cardBackgroundColor, // Lighter background
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text('News & Updates',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor)),
                           SizedBox(height: 10),
                           // Displaying Sample News Items
                           ListView.builder(
                             shrinkWrap: true, // Important inside another ListView
                             physics: NeverScrollableScrollPhysics(), // Disable scrolling for this inner list
                             itemCount: newsItems.length,
                             itemBuilder: (context, index) {
                               final item = newsItems[index];
                               return ListTile(
                                 contentPadding: EdgeInsets.zero, // Remove default padding
                                 leading: Icon(newsIcons[item['icon']] ?? Icons.article, color: primaryColor, size: 30), // Use mapped icon or default
                                 title: Text(item['title']!, style: TextStyle(fontWeight: FontWeight.w600, color: cardTextColor)),
                                 subtitle: Text(item['snippet']!, style: TextStyle(color: cardTextColor.withOpacity(0.8))),
                                 onTap: () {
                                    // Optional: Navigate to a full news article screen or show details
                                     ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Tapped on: ${item['title']}')),
                                      );
                                 },
                               );
                             },
                           ),
                        ],
                      ),
                    ),
                  ),
                   const SizedBox(height: 20.0), // Extra space at the bottom if needed
                ],
              ),
            ),
          ),

          // Floating Action Button for the AI Chat Bot (Bottom Left)
          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: FloatingActionButton(
              heroTag: 'aiChatFabHome',
              onPressed: () {
                _showAiChatWindow(context);
              },
              tooltip: 'Pet First Aid Bot',
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.chat_bubble_outline),
            ),
          ),

          // Floating Action Button for "New Request" (Bottom Right) - Kept for quick access
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton.large(
              heroTag: 'requestFabHome',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MyCustomForm(
                            user: _user,
                          )),
                );
              },
              tooltip: 'Create New Request',
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: null, // Important when using Stack + Positioned for FABs
    );
  }
}


