import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petlove/models/User_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as Path;
import 'package:image_picker/image_picker.dart';
import 'package:petlove/widgets/button_widget.dart'; // Seems unused in the provided snippet
import 'package:petlove/screens/home_page.dart'; // Seems unused in the provided snippet
import 'package:petlove/widgets/firebase_upload.dart'; // Assuming this is not needed for manual upload logic
import 'package:petlove/screens/ai_first_aid_chat.dart'; // Import AI chat screen


class updateProfile extends StatefulWidget {
  const updateProfile({Key? key, required UserModel user})
      : _user = user,
        super(key: key);

  final UserModel _user;

  @override
  _updateProfileState createState() => _updateProfileState();
}

class _updateProfileState extends State<updateProfile> {
  late UserModel _user;
  UploadTask? imagetask;
  File? image;
  String? dpURL;
  FirebaseStorage storage = FirebaseStorage.instance;
  var imageuploadstat = 0;

  // Define consistent colors
  final Color primaryColor = const Color.fromARGB(255, 4, 50, 88);
  final Color accentColor = Colors.orangeAccent;

  final _auth = FirebaseAuth.instance;

  CollectionReference users = FirebaseFirestore.instance.collection('users');

  int role = 1;

  // string for displaying the error Message


   // Function to show the AI Chat as a modal window (Copied for consistency)
   void _showAiChatWindow(BuildContext context) {
     showGeneralDialog(
       context: context,
       barrierDismissible: true, // Dismiss the dialog when tapping outside
       barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
       barrierColor: Colors.black54, // Semi-transparent barrier
       transitionDuration: const Duration(milliseconds: 300), // Animation duration
       pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
         return Center(
           child: Container(
             width: MediaQuery.of(buildContext).size.width * 0.9, // 90% of screen width
             height: MediaQuery.of(buildContext).size.height * 0.7, // 70% of screen height
             child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: AiFirstAidChatScreen(),
             ),
             decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    spreadRadius: 2.0,
                  ),
                ],
                 color: Colors.white, // Light background for the dialog
             ),
           ),
         );
       },
        transitionBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
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
  void initState() {
    _user = widget._user;
    // Initialize controllers with current user data (removed phone number)
     _nameController.text = _user.displayName ?? '';
     _emailController.text = _user.email ?? '';
    // _contactController.text = _user.phoneNumber ?? ''; // Removed as per UserModel structure


    super.initState();
  }

  // Controllers for text fields (removed phone number controller)
   final TextEditingController _nameController = TextEditingController();
   final TextEditingController _emailController = TextEditingController();
   // final TextEditingController _contactController = TextEditingController(); // Removed as per UserModel structure


   @override
   void dispose() {
     // Clean up the controllers when the widget is disposed (removed phone number controller dispose)
     _nameController.dispose();
     _emailController.dispose();
     // _contactController.dispose(); // Removed as per UserModel structure
     super.dispose();
   }


  Future selectFile() async {
    try {
      final result = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (result == null) return;
      final imageTemp = File(result.path);

      setState(() => image = imageTemp);
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future<String?> uploadFile() async {
     if (image == null) return null;

     final fileName = Path.basename(image!.path);
     final destination = 'files/${_user.uid}/profile_picture/$fileName'; // Define upload path specific to user


     try {
       final ref = FirebaseStorage.instance.ref(destination);
       UploadTask task = ref.putFile(image!); // Use putFile for File type
       setState(() {
         imagetask = task;
       });

       TaskSnapshot snapshot = await task.whenComplete(() {});
       String imgUrl = await snapshot.ref.getDownloadURL();

       setState(() {
         dpURL = imgUrl;
         imageuploadstat = 1;
       });
       print("Image uploaded successfully. URL: $imgUrl");
       return imgUrl;
     } catch (e) {
       print('Error uploading image: $e');
       setState(() {
         imageuploadstat = -1; // Indicate upload failure
       });
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
        );
       return null;
     }
  }

  Future<void> updateUserProfile(String name, String email, String? photoURL) async { // Removed contact parameter
    // Basic validation (removed contact validation)
     if (name.isEmpty || email.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields.')),
       );
       return;
     }

    User? firebaseUser = _auth.currentUser;

    if (firebaseUser != null) {
      try {
        // Update Firebase Authentication profile
        await firebaseUser.updateDisplayName(name);
        // Email update is complex and requires re-authentication,
        // so we will only update it in Firestore for now.
        // await firebaseUser.updateEmail(email);

        // Update Firestore document (removed phoneNumber update)
        await users.doc(_user.uid).update({
          'displayName': name,
          'email': email, // Update email in Firestore
          // 'phoneNumber': contact, // Removed as per UserModel structure
          if (photoURL != null) 'photoURL': photoURL, // Update photoURL if available
        });

         // Update the local UserModel (removed phoneNumber update)
         setState(() {
            _user.displayName = name;
            _user.email = email;
            // _user.phoneNumber = contact; // Removed as per UserModel structure
            if (photoURL != null) {
              _user.photoURL = photoURL;
            }
         });


        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Profile updated successfully!')),
        );

      } on FirebaseAuthException catch (e) {
        print('FirebaseAuth error: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to update profile: ${e.message}')),
        );
      } catch (e) {
        print('Firestore update error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      }
    }
  }


  Widget buildUploadStatus(UploadTask task) => StreamBuilder<TaskSnapshot>(
        stream: task.snapshotEvents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final snap = snapshot.data!;
            final progress = snap.bytesTransferred / snap.totalBytes;
            final percentage = (progress * 100).toStringAsFixed(2);

            return Text(
              '$percentage %',
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            );
          } else {
            return Container();
          }
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Colors.white, // Consistent light background color
      appBar: AppBar(
        title: const Text('Update Profile', style: TextStyle(color: Colors.white)), // White text for AppBar title
        backgroundColor: primaryColor, // Consistent primary color for AppBar
        elevation: 0,
      ),
      body: Stack( // Use Stack to position FAB
         children: [
           SingleChildScrollView( // Use SingleChildScrollView for the form content
             padding: const EdgeInsets.all(16.0), // Add padding
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: <Widget>[
                  Text(
                     'Update Your Information',
                     style: TextStyle(
                        color: primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                     ),
                  ),
                 const SizedBox(height: 20),

                 // Profile Picture Section
                  GestureDetector( // Make the image area tappable
                     onTap: selectFile,
                     child: Center( // Center the profile picture
                       child: Stack(
                          alignment: Alignment.bottomRight,
                         children: [
                           CircleAvatar(
                              radius: 60,
                             backgroundColor: Colors.grey[300], // Placeholder background
                             backgroundImage: image != null
                                 ? FileImage(image!) as ImageProvider // Use FileImage if a new image is selected
                                 : (_user.photoURL != null && _user.photoURL!.isNotEmpty
                                     ? NetworkImage(_user.photoURL!) // Use NetworkImage for existing photoURL
                                     : null), // No image if neither
                             child: image == null && (_user.photoURL == null || _user.photoURL!.isEmpty)
                                ? Icon(Icons.person, size: 60, color: Colors.grey[600]) // Default icon
                                : null,
                           ),
                            CircleAvatar(
                               backgroundColor: accentColor, // Accent color for edit icon background
                               radius: 18,
                               child: Icon(Icons.camera_alt, size: 20, color: Colors.white), // Edit icon
                            ),
                         ],
                       ),
                     ),
                  ),
                 const SizedBox(height: 10),
                  Center( // Center the upload status text
                     child: imagetask != null ? buildUploadStatus(imagetask!) : Container(),
                  ),
                 const SizedBox(height: 20),


                 // Name Field
                 Text('Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 8),
                 TextField(
                    controller: _nameController,
                   decoration: InputDecoration(
                      hintText: 'Enter your name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                       filled: true, // Add fill
                       fillColor: Colors.grey[200], // Light fill color
                   ),
                 ),
                 const SizedBox(height: 16),

                 // Email Field
                 Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 8),
                 TextField(
                    controller: _emailController,
                   decoration: InputDecoration(
                      hintText: 'Enter your email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                       filled: true,
                       fillColor: Colors.grey[200],
                   ),
                   keyboardType: TextInputType.emailAddress,
                 ),
                 const SizedBox(height: 16),

                 // Removed Contact Field section

                 // Update Button
                 Center( // Center the button
                   child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                         foregroundColor: Colors.white, backgroundColor: primaryColor, // Use primary color for the button
                         padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                         elevation: 2.0,
                      ),
                     onPressed: () async {
                        String? uploadedPhotoURL;
                        if (image != null) {
                           uploadedPhotoURL = await uploadFile(); // Upload image if selected
                           if (uploadedPhotoURL == null && imageuploadstat == -1) {
                              // Handle upload failure
                              return;
                           }
                        }

                        await updateUserProfile(
                           _nameController.text.trim(),
                           _emailController.text.trim(),
                            uploadedPhotoURL ?? _user.photoURL, // Use new URL if uploaded, otherwise keep existing
                        );
                     },
                     child: const Text(
                       'Update Profile',
                       style: TextStyle(fontSize: 18),
                     ),
                   ),
                 ),
                 const SizedBox(height: 80), // Add some space at the bottom
               ],
             ),
           ),

           // Floating Action Button for the AI Chat Bot (Bottom Left) - Added for consistency
           Positioned(
             bottom: 16.0, // Standard bottom margin
             left: 16.0, // Standard left margin
             child: FloatingActionButton(
               heroTag: 'aiChatFabUpdateProfile', // Unique tag for this screen
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
