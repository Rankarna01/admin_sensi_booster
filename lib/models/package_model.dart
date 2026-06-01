class PackageModel {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final int referralRewardDays;

  PackageModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.referralRewardDays,
  });

  factory PackageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PackageModel(
      id: documentId,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      durationDays: map['durationDays'] ?? 0,
      referralRewardDays: map['referralRewardDays'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'referralRewardDays': referralRewardDays,
    };
  }
}