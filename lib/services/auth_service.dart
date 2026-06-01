import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/device_util.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fungsi untuk login dan verifikasi Hardware ID
  Future<String?> loginAdmin(String email, String password) async {
    try {
      // 1. Proses Login ke Firebase Auth
      UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      
      // --- DIBYPASS SEMENTARA AGAR BISA LOGIN ---
      // 2. Ambil Hardware ID dari HP yang sedang dipakai
      // String currentDeviceId = await DeviceUtil.getHardwareId();

      // 3. Cek data admin di Firestore (Koleksi: admins, Document: uid)
      // DocumentSnapshot adminDoc = await _db.collection('admins').doc(cred.user!.uid).get();

      // Jika data tidak ada di koleksi admins
      // if (!adminDoc.exists) {
      //   await _auth.signOut();
      //   return "Akses Ditolak: Akun ini bukan Admin!";
      // }

      // Ambil Hardware ID yang terdaftar di Firestore
      // String registeredId = adminDoc.get('hardwareId');

      // 4. Bandingkan Hardware ID
      // if (registeredId != currentDeviceId) {
      //   await _auth.signOut();
      //   return "Akses Ditolak: Hardware ID tidak cocok! Gunakan HP Admin yang terdaftar.";
      // }

      // Jika semua lolos, kembalikan null (pertanda sukses tanpa error)
      return null;
      
    } on FirebaseAuthException catch (e) {
      return e.message; // Error dari Firebase (contoh: password salah)
    } catch (e) {
      return e.toString(); // Error umum lainnya
    }
  }
}