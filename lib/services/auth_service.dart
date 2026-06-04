import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/device_util.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fungsi untuk login dan menentukan role (admin / user)
  Future<String?> loginAndGetRole(String email, String password) async {
    try {
      // 1. Proses Login ke Firebase Auth
      UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      
      String uid = cred.user!.uid;

      // 2. Cek apakah user ini Admin
      DocumentSnapshot adminDoc = await _db.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        return "admin";
      }

      // 3. Cek apakah user ini Client
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        // Cek hardware id atau pengecekan lainnya nanti
        return "user";
      }

      // Jika tidak ada di keduanya
      await _auth.signOut();
      return "ERROR: Akun tidak terdaftar di database sistem.";
      
    } on FirebaseAuthException catch (e) {
      return "ERROR: ${e.message}"; // Error dari Firebase (contoh: password salah)
    } catch (e) {
      return "ERROR: ${e.toString()}"; // Error umum lainnya
    }
  }
}