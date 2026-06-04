import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/package_model.dart';
import 'user_management_provider.dart'; // Untuk mengambil firestoreProvider

// Stream Provider untuk membaca list paket
final packageStreamProvider = StreamProvider<List<PackageModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('packages').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => PackageModel.fromMap(doc.data(), doc.id)).toList();
  });
});

// Notifier untuk aksi simpan/edit paket
class PackageActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  // Fungsi untuk Add (id kosong) atau Edit (id terisi)
  Future<void> savePackage(PackageModel pkg) async {
    state = const AsyncValue.loading();
    try {
      final firestore = ref.read(firestoreProvider);
      
      // Jika ID kosong, berarti buat dokumen baru. Jika ada, berarti update.
      final docRef = pkg.id.isEmpty 
          ? firestore.collection('packages').doc() 
          : firestore.collection('packages').doc(pkg.id);

      await docRef.set(pkg.toMap());
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Deklarasi provider aksi paket
final packageActionProvider = NotifierProvider.autoDispose<PackageActionNotifier, AsyncValue<void>>(() {
  return PackageActionNotifier();
});