class PackageModel {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final int referralRewardDays;
  // Menambahkan Map untuk menyimpan status ke-9 fitur
  final Map<String, bool> features; 

  PackageModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.referralRewardDays,
    required this.features,
  });

  factory PackageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PackageModel(
      id: documentId,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      durationDays: map['durationDays'] ?? 0,
      referralRewardDays: map['referralRewardDays'] ?? 0,
      // Jika fitur kosong di database, kita berikan nilai default false
      features: Map<String, bool>.from(map['features'] ?? {
        'speed_test': false,
        'latency_mode': false,
        'game_lab_sensi': false,
        'cpu_tweak': false, // Mencakup core priority, governor, RAM
        'set_dpi': false,
        'floating_game': false,
        'crosshair': false,
        'rog_monitor': false,
        'graphics_tweak': false,
      }),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'referralRewardDays': referralRewardDays,
      'features': features,
    };
  }
}