import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_management_provider.dart';

class DashboardStats {
  final int totalUsers;
  final int activeVip;
  final double conversionRate;
  final double totalRevenue;

  DashboardStats({
    required this.totalUsers,
    required this.activeVip,
    required this.conversionRate,
    required this.totalRevenue,
  });
}

// Provider kalkulasi otomatis metrik dashboard admin
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final usersAsync = ref.watch(usersStreamProvider);
  
  return usersAsync.maybeWhen(
    data: (users) {
      final total = users.length;
      final vipCount = users.where((u) => u.statusVip == 'super_vip' || u.statusVip == 'standard').length;
      final conversion = total > 0 ? (vipCount / total) * 100 : 0.0;
      
      // Hitung virtual kalkulasi omset (Standard: 50rb, Super VIP: 100rb)
      final revenue = users.where((u) => u.statusVip == 'standard').length * 50000.0 + 
                      users.where((u) => u.statusVip == 'super_vip').length * 100000.0;

      return DashboardStats(
        totalUsers: total,
        activeVip: vipCount,
        conversionRate: conversion,
        totalRevenue: revenue,
      );
    },
    orElse: () => DashboardStats(totalUsers: 0, activeVip: 0, conversionRate: 0.0, totalRevenue: 0.0),
  );
});