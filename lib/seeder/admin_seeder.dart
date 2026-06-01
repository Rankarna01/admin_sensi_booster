import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/device_util.dart';

class AdminSeeder {
  // Fungsi untuk membuat admin pertama
  static Future<String> createInitialAdmin() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore db = FirebaseFirestore.instance;

    String email = "admin@mfw.com";
    String password = "kecubung123";

    try {
      UserCredential cred;
      
      // 1. Coba daftarkan akun ke Firebase Auth
      try {
        cred = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        // Jika akun sudah pernah dibuat sebelumnya, lakukan login saja untuk dapat UID
        if (e.code == 'email-already-in-use') {
          cred = await auth.signInWithEmailAndPassword(
            email: email, 
            password: password,
          );
        } else {
          return "Error Auth [${e.code}]: ${e.toString()}";
        }
      }

      // 2. Ambil Hardware ID dari HP kamu yang sekarang
      String currentDeviceId = await DeviceUtil.getHardwareId();

      // 3. Tulis data ke Firestore di koleksi 'admins'
      await db.collection('admins').doc(cred.user!.uid).set({
        'email': email,
        'hardwareId': currentDeviceId,
        'role': 'super_admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Logout otomatis agar kamu bisa mengetes fiturnya lewat UI Login
      await auth.signOut();

      return "Seeder Berhasil! Akun siap digunakan. Hardware ID HP ini telah dikunci.";
    } catch (e) {
      return "Error Seeder: $e";
    }
  }
}