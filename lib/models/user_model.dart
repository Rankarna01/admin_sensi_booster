class UserModel {
  final String uid;
  final String email;
  final String role;
  final String deviceId;
  final String statusVip;
  final String paymentStatus;
  final String referralCode;
  final int referralCount;
  final String referredBy; // Menyimpan kode referral teman yang mengundang
  final DateTime? activeUntil; // Batas waktu paket (Krusial untuk sistem langganan)

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.deviceId,
    required this.statusVip,
    this.paymentStatus = 'unpaid',
    required this.referralCode,
    this.referralCount = 0,
    this.referredBy = '',
    this.activeUntil,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      deviceId: map['deviceId'] ?? '',
      statusVip: map['statusVip'] ?? 'free',
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      referralCode: map['referralCode'] ?? '',
      referralCount: map['referralCount'] ?? 0,
      referredBy: map['referredBy'] ?? '',
      activeUntil: map['activeUntil'] != null ? DateTime.parse(map['activeUntil']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'deviceId': deviceId,
      'statusVip': statusVip,
      'paymentStatus': paymentStatus,
      'referralCode': referralCode,
      'referralCount': referralCount,
      'referredBy': referredBy,
      'activeUntil': activeUntil?.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}