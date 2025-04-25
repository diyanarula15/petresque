import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petlove/screens/sign_in_screen.dart';
import 'package:petlove/utils/authentication.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Required for CachedNetworkImage if photoURL is a network image


class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  late User _user;
  bool _isSigningOut = false;

  // Define consistent colors
   final Color primaryColor = const Color.fromARGB(255, 4, 50, 88);
   final Color accentColor = Colors.orangeAccent;


  Route _routeToSignInScreen() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const SignInScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  void initState() {
    _user = widget._user;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Consistent light background color
      backgroundColor: Colors.white, // Using white as a consistent light background
      appBar: AppBar(
        title: const Text('User Info', style: TextStyle(color: Colors.white)), // White text for AppBar title
        backgroundColor: primaryColor, // Consistent primary color for AppBar
        elevation: 0, // Remove shadow
      ),
      body: Padding( // Use Padding for the body content
        padding: const EdgeInsets.all(16.0), // Add padding
        child: ListView( // Changed to ListView for scrollability
          children: <Widget>[
            Text(
              'Profile Information',
              style: TextStyle(
                color: primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Profile Picture
            Center( // Center the profile picture
              child: CircleAvatar(
                 radius: 60,
                backgroundColor: Colors.grey[300], // Placeholder background
                backgroundImage: _user.photoURL != null
                    ? CachedNetworkImageProvider(_user.photoURL!) as ImageProvider // Use CachedNetworkImageProvider
                    : null, // Use NetworkImage if photoURL exists
                child: _user.photoURL == null
                    ? Icon(Icons.person, size: 60, color: Colors.grey[600]) // Default icon if no photo
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            // User Name
            Text(
              'Name:',
              style: TextStyle(
                color: primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _user.displayName ?? 'N/A',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            // User Email
            Text(
              'Email:',
              style: TextStyle(
                color: primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _user.email ?? 'N/A',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
             // User UID (Optional to display, but can be useful for debugging)
            Text(
              'User ID:',
              style: TextStyle(
                color: primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
             const SizedBox(height: 8),
             Text(
               _user.uid,
               style: const TextStyle(
                 fontSize: 14, // Slightly smaller font for UID
                 color: Colors.grey, // Grey color for UID
               ),
             ),
            const SizedBox(height: 30),

             // Placeholder for News about animals and stats
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              color: Colors.white, // Explicitly set card color to white for visibility
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('News about animals and stats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                    SizedBox(height: 10),
                    Text('Placeholder for news and statistics related to animals (Functionality not implemented)', style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
            ),
             const SizedBox(height: 30), // Spacing before the button


            _isSigningOut
                ? const CircularProgressIndicator()
                : Center( // Center the sign out button
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.redAccent, // Red accent for sign out
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                         padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                         elevation: 2.0,
                      ),
                      onPressed: () async {
                        setState(() {
                          _isSigningOut = true;
                        });
                        await Authentication.signOut(context: context);
                        setState(() {
                          _isSigningOut = false;
                        });
                         if (mounted) { // Check if the widget is still in the widget tree
                           Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const SignInScreen()), // Removed const here
                              (Route<dynamic> route) => false, // Navigate and remove all previous routes
                           );
                         }
                      },
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
