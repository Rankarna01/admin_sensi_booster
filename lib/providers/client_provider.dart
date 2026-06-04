import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/package_model.dart';
import 'user_management_provider.dart';

// 1. Dapatkan pengguna yang sedang login
final currentAuthUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 2. Dapatkan data UserModel berdasarkan auth
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(currentAuthUserProvider).value;
  if (authUser == null) return Stream.value(null);

  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('users').doc(authUser.uid).snapshots().map((doc) {
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  });
});

// 3. Dapatkan PackageModel berdasarkan statusVip user saat ini
final currentPackageProvider = StreamProvider<PackageModel?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(null);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('packages')
      // Kita cari package berdasarkan nama yang cocok dengan statusVip (misal "free", "standard", "vip")
      .where('name', isEqualTo: user.statusVip)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return null;
    return PackageModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  });
});
