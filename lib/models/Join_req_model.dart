class JoinModel {
  String? uid;
  String? ngo_uid;
  String? description;
  String? contact;
  String? status;
  // ADD THIS LINE: Declare the timestamp field
  // Use Object? or dynamic if you're not sure of the exact type
  // when reading from Firestore (it's a Timestamp object),
  // but FieldValue.serverTimestamp() is accepted by set/update.
  Object? timestamp; // Using Object? to be flexible with FieldValue and Timestamp

  // Constructor (Optional, but good practice)
  JoinModel({
    this.uid,
    this.ngo_uid,
    this.description,
    this.contact,
    this.status,
    this.timestamp, // Include in constructor
  });

  // Method to convert JoinModel object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'ngo_uid': ngo_uid,
      'description': description,
      'contact': contact,
      'status': status,
      'timestamp': timestamp, // Include in the map
    };
  }

  // Optional: Factory method to create a JoinModel object from a Firestore document snapshot
  factory JoinModel.fromMap(Map<String, dynamic> map) {
    return JoinModel(
      uid: map['uid'] as String?,
      ngo_uid: map['ngo_uid'] as String?,
      description: map['description'] as String?,
      contact: map['contact'] as String?,
      status: map['status'] as String?,
      // Firestore timestamps are usually returned as Timestamp objects
      timestamp: map['timestamp'], // Keep as Object? or cast if needed later
    );
  }
}