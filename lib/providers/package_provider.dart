import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/package_model.dart';
import 'user_management_provider.dart'; // Untuk mengambil firestoreProvider

final packageStreamProvider = StreamProvider<List<PackageModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('packages').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => PackageModel.fromMap(doc.data(), doc.id)).toList();
  });
});