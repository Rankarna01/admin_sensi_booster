import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

// Provider instance Firestore
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

// Stream Provider untuk memantau list user secara real-time
final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('users').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
  });
});

// Menggunakan Notifier murni (Sesuai dengan update Riverpod 3.x)
class UserManagementNotifier extends Notifier<AsyncValue<void>> {
  
  @override
  AsyncValue<void> build() {
    // Inisialisasi state awal (tidak loading, tidak error)
    return const AsyncValue.data(null);
  }

  // FUNGSI 1: Mendaftarkan User Baru oleh Admin (Dengan Generator Referral)
  Future<void> registerNewUser(String email, String password, String tier) async {
    state = const AsyncValue.loading();
    try {
      // TRIK: Membuat instance Firebase sementara agar Admin tidak ter-logout
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TemporaryAuth',
        options: Firebase.app().options,
      );

      // Buat akun di Firebase Auth menggunakan instance sementara
      UserCredential cred = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      // GENERATOR KODE REFERRAL (6 Karakter Acak Alfanumerik)
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      Random rnd = Random();
      String generatedCode = String.fromCharCodes(Iterable.generate(
          6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

      // SET MASA AKTIF DEFAULT (Contoh: Free 3 hari, Standard 30 hari, VIP 30 hari)
      DateTime expirationDate = DateTime.now();
      if (tier == 'free') expirationDate = expirationDate.add(const Duration(days: 3));
      else if (tier == 'standard') expirationDate = expirationDate.add(const Duration(days: 30));
      else if (tier == 'super_vip') expirationDate = expirationDate.add(const Duration(days: 30));

      // Buat struktur data di Firestore
      UserModel newUser = UserModel(
        uid: cred.user!.uid,
        email: email,
        role: 'user',
        deviceId: '',
        statusVip: tier,
        paymentStatus: tier == 'free' ? 'paid' : 'unpaid', // Free otomatis 'paid'
        referralCode: generatedCode, // Kode referral unik masuk ke sini
        activeUntil: expirationDate, // Batas waktu kedaluwarsa masuk ke sini
      );

      // Gunakan ref.read untuk mengeksekusi fungsi database
      await ref.read(firestoreProvider).collection('users').doc(cred.user!.uid).set(newUser.toMap());

      // Hapus instance sementara
      await tempApp.delete();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // FUNGSI 2: Update Tier VIP Manual dari Detail Page
  Future<void> updateVipStatus(String uid, String newStatus) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(firestoreProvider).collection('users').doc(uid).update({'statusVip': newStatus});
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // FUNGSI 3: Konfirmasi Pembayaran
  Future<void> updatePaymentStatus(String uid, String paymentStatus) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(firestoreProvider).collection('users').doc(uid).update({'paymentStatus': paymentStatus});
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // FUNGSI 4: Reset Hardware ID
  Future<void> resetHardwareId(String uid) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(firestoreProvider).collection('users').doc(uid).update({'deviceId': ''});
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Deklarasi Provider menggunakan NotifierProvider autoDispose
final userActionProvider = NotifierProvider.autoDispose<UserManagementNotifier, AsyncValue<void>>(() {
  return UserManagementNotifier();
});