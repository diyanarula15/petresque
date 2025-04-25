import 'package:flutter/material.dart';
import 'package:petlove/models/Join_req_model.dart'; // Assuming JoinModel is correct
import 'package:petlove/models/User_model.dart'; // Assuming UserModel is correct
import 'package:cloud_firestore/cloud_firestore.dart';
// REMOVE THIS LINE: import 'package:fluttertoast/fluttertoast.dart';
import 'package:petlove/screens/home_page.dart'; // Assuming HomePage is correct


class JoinForm extends StatefulWidget {
  const JoinForm({Key? key, required UserModel user, required String? ngo_uid})
      : _user = user,
        _ngo_uid = ngo_uid,
        super(key: key);

  final UserModel _user;
  final String? _ngo_uid;

  @override
  State<JoinForm> createState() => _JoinFormState();
}

class _JoinFormState extends State<JoinForm> {
  late UserModel _user;
  late String? _ngo_uid;

  @override
  void initState() {
    _user = widget._user;
    _ngo_uid = widget._ngo_uid;

    super.initState();
  }

  final _formKey = GlobalKey<FormState>();
  // editing Controller

  final contactEditingController = TextEditingController();
  final descriptionEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final contactField = TextFormField(
      style: const TextStyle(color: Color.fromARGB(255, 4, 50, 88), fontSize: 18),
      autofocus: false,
      controller: contactEditingController,
      keyboardType: TextInputType.phone,
      // Validator commented out - consider adding a valid phone validator
      // validator: (value) {
      //   RegExp regex = new RegExp(
      //       "/(\+\d{1,3}\s?)?((\(\d{3}\)\s?)|(\d{3})(\s|-?))(\d{3}(\s|-?))(\d{4})(\s?(([E|e]xt[:|.|]?)|x|X)(\s?\d+))?/g");
      //   if (value!.isEmpty) {
      //     return ("Contact cannot be Empty");
      //   }
      //   if (!regex.hasMatch(value)) {
      //     return ("Enter Valid Contact Number)");
      //   }
      //   return null;
      // },
      onSaved: (value) {
        contactEditingController.text = value!;
      },
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color.fromARGB(255, 4, 50, 88)),
          borderRadius: BorderRadius.circular(5.5),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Color.fromARGB(255, 4, 50, 88),
          ),
        ),
        prefixIcon: const Icon(
          Icons.contact_phone,
          color: Color.fromARGB(255, 4, 50, 88),
        ),
        filled: true,
        fillColor: Colors.white,
        labelText: "Contact",
        labelStyle: const TextStyle(color: Color.fromARGB(255, 4, 50, 88)),
      ),
    );
    final descriptionField = TextFormField(
      minLines: 1,
      maxLines: 5,
      style: const TextStyle(color: Color.fromARGB(255, 4, 50, 88), fontSize: 18),
      autofocus: false,
      controller: descriptionEditingController,
      keyboardType: TextInputType.text,
      validator: (value) {
        // Using a simpler check for minimum length
        if (value == null || value.trim().isEmpty) { // Check for null or empty after trimming
          return ("Description cannot be empty");
        }
        if (value.trim().length < 3) {
          return ("Enter at least 3 Characters");
        }
        return null;
      },
      onSaved: (value) {
        descriptionEditingController.text = value!.trim(); // Trim whitespace
      },
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color.fromARGB(255, 4, 50, 88)),
          borderRadius: BorderRadius.circular(5.5),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Color.fromARGB(255, 4, 50, 88),
          ),
        ),
        prefixIcon: const Icon(
          Icons.description,
          color: Color.fromARGB(255, 4, 50, 88),
        ),
        filled: true,
        fillColor: Colors.white,
        labelText: "Description",
        labelStyle: const TextStyle(color: Color.fromARGB(255, 4, 50, 88)),
      ),
    );
    final ApplyButton = Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(3),
      color: const Color.fromARGB(255, 4, 50, 88),
      child: MaterialButton(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          minWidth: MediaQuery.of(context).size.width,
          onPressed: () {
            Apply(_user.uid, _ngo_uid); // Call Apply function
          },
          child: const Text(
            "Apply",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          )),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Apply to Join NGO'), // More descriptive title
        backgroundColor: const Color.fromARGB(255, 4, 50, 88),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // passing this to our root
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(36.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    // Commented out logo image
                    // SizedBox(
                    //     height: 180,
                    //     child: Image.asset(
                    //       "assets/logo.png",
                    //       fit: BoxFit.contain,
                    //     )),
                    // SizedBox(height: 45), // Adjusted spacing
                    const SizedBox(height: 20), // Spacing before description
                    descriptionField,
                    const SizedBox(height: 20),

                    contactField,
                    const SizedBox(height: 20),

                    //upload logo button (commented out)

                    // Commented out SizedBox and Row
                    // const SizedBox(height: 8),
                    // const SizedBox(height: 8),
                    // const Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: <Widget>[
                    //     SizedBox(
                    //       width: 15,
                    //     ),
                    //     SizedBox(
                    //       width: 15,
                    //     ),
                    //   ],
                    // ),

                    const SizedBox(
                      height: 20, // Spacing before button
                    ),
                    ApplyButton,
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void Apply(String? uid, String? ngoUid) async {
    if (_formKey.currentState!.validate()) {
      // No need to call _formKey.currentState.save() as you're using controllers
      postDetailsToFirestore(uid, ngoUid);
    }
  }

  postDetailsToFirestore(String? uid, String? ngoUid) async {
    // Check if uid and ngoUid are available before proceeding
    if (uid == null || ngoUid == null) {
       print("Error: User UID or NGO UID is null.");
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error submitting request. User or NGO data missing.")),
          );
       }
       return; // Exit the function
    }


    FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

    JoinModel datajoin = JoinModel();

    // writing all the values
    datajoin.uid = uid;
    datajoin.ngo_uid = ngoUid;
    datajoin.description = descriptionEditingController.text.trim(); // Trim whitespace
    datajoin.contact = contactEditingController.text.trim(); // Trim whitespace
    datajoin.status = "pending"; // Changed status to 'pending' which is more common for initial requests
    datajoin.timestamp = FieldValue.serverTimestamp(); // Added timestamp

    try {
      await firebaseFirestore
          .collection("JoinRequests")
          .doc() // Auto-generate a unique document ID
          .set(datajoin.toMap());

      // Use ScaffoldMessenger to show SnackBar
      if (mounted) { // Check if the widget is still in the widget tree
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request Sent Successfully :) "),
            duration: Duration(seconds: 4), // Optional: customize duration
          ),
        );
      }

      // Navigate back to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage(
                  user: _user, // Use the stored _user variable
                )),
      );
    } catch (e) {
      print("Error sending join request: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send request: ${e.toString()}")),
        );
      }
    }
  }
}

// Make sure JoinModel exists and has the toMap() method
/*
class JoinModel {
  String? uid;
  String? ngo_uid;
  String? description;
  String? contact;
  String? status;
  FieldValue? timestamp; // Added timestamp field

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'ngo_uid': ngo_uid,
      'description': description,
      'contact': contact,
      'status': status,
      'timestamp': timestamp,
    };
  }

  // Optional: fromMap constructor/factory
  // JoinModel.fromMap(Map<String, dynamic> map) {
  //   uid = map['uid'];
  //   ngo_uid = map['ngo_uid'];
  //   description = map['description'];
  //   contact = map['contact'];
  //   status = map['status'];
  //   timestamp = map['timestamp']; // Note: This will be a Timestamp object from Firestore
  // }
}
*/
// Ensure UserModel and HomePage classes are defined in their respective files.