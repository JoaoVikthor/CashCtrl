import 'package:cloud_firestore/cloud_firestore.dart';

class PriceAuditLog {
  final String action;
  final String entityType;
  final String entityId;
  final String summary;
  final String? supplier;
  final double? previousPrice;
  final double? newPrice;
  final double? pricePerUnit;
  final String source;
  final DateTime? timestamp;

  const PriceAuditLog({
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.summary,
    this.supplier,
    this.previousPrice,
    this.newPrice,
    this.pricePerUnit,
    this.source = 'manual',
    this.timestamp,
  });

  Map<String, dynamic> toMap(DateTime expireAt) => {
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'summary': summary,
        'supplier': supplier,
        'previousPrice': previousPrice,
        'newPrice': newPrice,
        'pricePerUnit': pricePerUnit,
        'source': source,
        'timestamp': FieldValue.serverTimestamp(),
        'expireAt': Timestamp.fromDate(expireAt),
      };

  factory PriceAuditLog.fromMap(Map<String, dynamic> m) {
    final rawTimestamp = m['timestamp'];
    DateTime? timestamp;
    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      timestamp = rawTimestamp;
    } else if (rawTimestamp is String) {
      timestamp = DateTime.tryParse(rawTimestamp);
    }
    return PriceAuditLog(
      action: (m['action'] ?? '') as String,
      entityType: (m['entityType'] ?? '') as String,
      entityId: (m['entityId'] ?? '') as String,
      summary: (m['summary'] ?? '') as String,
      supplier: m['supplier'] as String?,
      previousPrice: (m['previousPrice'] as num?)?.toDouble(),
      newPrice: (m['newPrice'] as num?)?.toDouble(),
      pricePerUnit: (m['pricePerUnit'] as num?)?.toDouble(),
      source: (m['source'] ?? 'manual') as String,
      timestamp: timestamp,
    );
  }
}
