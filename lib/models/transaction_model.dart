import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userUid;
  final String userEmail;
  final String packageName;
  final double amount;
  final String status; // unpaid, paid
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userUid,
    required this.userEmail,
    required this.packageName,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TransactionModel(
      id: documentId,
      userUid: map['userUid'] ?? '',
      userEmail: map['userEmail'] ?? '',
      packageName: map['packageName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'unpaid',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'userEmail': userEmail,
      'packageName': packageName,
      'amount': amount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}