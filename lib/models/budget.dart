import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final String category;
  final double limit;
  final bool monthly;
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.category,
    required this.limit,
    this.monthly = true,
    required this.createdAt,
  });

  factory Budget.fromMap(String id, Map<String, dynamic> m) {
    final rawDate = m['createdAt'];
    DateTime date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }
    return Budget(
      id: id,
      category: (m['category'] ?? 'Outros') as String,
      limit: ((m['limit'] ?? 0) as num).toDouble(),
      monthly: (m['monthly'] ?? true) as bool,
      createdAt: date,
    );
  }

  Map<String, dynamic> toMap() => {
        'category': category,
        'limit': limit,
        'monthly': monthly,
        'createdAt': createdAt.toIso8601String(),
      };
}