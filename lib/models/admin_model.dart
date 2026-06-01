class AdminModel {
  final String uid;
  final String email;
  final String hardwareId;
  final String role;

  AdminModel({
    required this.uid,
    required this.email,
    required this.hardwareId,
    required this.role,
  });

  // Mengubah data Firestore (Map) menjadi format Class dart
  factory AdminModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AdminModel(
      uid: documentId,
      email: map['email'] ?? '',
      hardwareId: map['hardwareId'] ?? '',
      role: map['role'] ?? 'admin',
    );
  }

  // Mengubah format Class dart untuk disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'hardwareId': hardwareId,
      'role': role,
    };
  }
}