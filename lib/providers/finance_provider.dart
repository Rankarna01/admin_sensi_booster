import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import 'user_management_provider.dart'; // Mengambil firestoreProvider

// Stream untuk membaca semua transaksi real-time dari yang terbaru
final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('transactions')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data(), doc.id)).toList();
  });
});

// Notifier Murni untuk Aksi Konfirmasi Keuangan (Riverpod 3.x Style)
class FinanceNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  // FUNGSI UTAMA: Konfirmasi Pembayaran Sukses
  Future<void> confirmTransaction(TransactionModel tx) async {
    state = const AsyncValue.loading();
    try {
      final firestore = ref.read(firestoreProvider);
      final batch = firestore.batch();

      // 1. Update status transaksi menjadi 'paid'
      final txRef = firestore.collection('transactions').doc(tx.id);
      batch.update(txRef, {'status': 'paid'});

      // 2. Otomatis update status VIP & Pembayaran User yang bersangkutan
      final userRef = firestore.collection('users').doc(tx.userUid);
      
      // Set masa aktif premium 30 hari dari sekarang
      DateTime expirationDate = DateTime.now().add(const Duration(days: 30));

      batch.update(userRef, {
        'statusVip': tx.packageName.toLowerCase(), // otomatis standard / super_vip sesuai yang dibeli
        'paymentStatus': 'paid',
        'activeUntil': expirationDate.toIso8601String(),
      });

      // Eksekusi Batch query sekaligus agar aman dan cepat
      await batch.commit();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final financeActionProvider = NotifierProvider.autoDispose<FinanceNotifier, AsyncValue<void>>(() {
  return FinanceNotifier();
});