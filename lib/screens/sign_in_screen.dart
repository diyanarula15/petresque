import 'package:flutter/material.dart';
import 'package:petlove/utils/authentication.dart';
import 'package:petlove/widgets/google_sign_in_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Define the colors for clarity
  final Color primaryTextColor = const Color.fromARGB(255, 4, 50, 88); // Original ResQpet color
  final Color accentTextColor = const Color.fromARGB(255, 66, 152, 173); // Original Sign In color

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using a consistent background color, maybe slightly lighter than the original dark blue
      backgroundColor: const Color.fromARGB(255, 13, 33, 49), // Slightly lighter background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 24.0, // Increased padding
            right: 24.0, // Increased padding
            bottom: 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Removed the empty Row as it's not needed for layout here
              Expanded(
                // Centering the content vertically
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch text horizontally
                  children: [
                    Flexible(
                      flex: 1,
                      child: Center( // Center the image
                        child: Image.asset(
                          'assets/petcare_image.PNG',
                          height: 250, // Slightly increased image size
                          fit: BoxFit.contain, // Use contain to maintain aspect ratio
                        ),
                      ),
                    ),
                    const SizedBox(height: 30), // Increased spacing
                    // ResQpet Text - Swapped color and increased size
                    Text(
                      'ResQpet',
                      textAlign: TextAlign.center, // Center the text
                      style: TextStyle(
                        color: accentTextColor, // Swapped color to the original Sign In color
                        fontSize: 50, // Increased font size
                        fontWeight: FontWeight.bold, // Added bold font weight
                      ),
                    ),
                    const SizedBox(height: 8), // Spacing between texts
                    // Sign In Text - Swapped color and decreased size
                    Text(
                      'Sign In',
                      textAlign: TextAlign.center, // Center the text
                      style: TextStyle(
                        color: primaryTextColor, // Swapped color to the original ResQpet color
                        fontSize: 30, // Decreased font size
                        fontWeight: FontWeight.w600, // Slightly less bold than ResQpet
                      ),
                    ),
                  ],
                ),
              ),
              // Spacing before the button
              const SizedBox(height: 40),

              FutureBuilder(
                future: Authentication.initializeFirebase(context: context),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center( // Center error text
                      child: Text(
                        'Error initializing Firebase: ${snapshot.error}', // Show error details
                        style: TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else if (snapshot.connectionState == ConnectionState.done) {
                    // Assuming GoogleSignInButton is a valid widget
                    return const GoogleSignInButton();
                  }
                  return Center( // Center the progress indicator
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        accentTextColor, // Use accent color for consistency
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
