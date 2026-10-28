import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/recurrence.dart';

enum TransactionType { receita, despesa }

extension TransactionTypeExt on TransactionType {
  bool get isReceita => this == TransactionType.receita;

  String get label => switch (this) {
        TransactionType.receita => 'Receita',
        TransactionType.despesa => 'Despesa',
      };

  String get firestoreValue => switch (this) {
        TransactionType.receita => 'receita',
        TransactionType.despesa => 'despesa',
      };

  static TransactionType fromFirestore(String v) => v == 'receita'
      ? TransactionType.receita
      : TransactionType.despesa;
}

enum PaymentMethod { dinheiro, credito, debito, pix, transferencia, outro }

extension PaymentMethodExt on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.dinheiro => 'Dinheiro',
        PaymentMethod.credito => 'Cartão de Crédito',
        PaymentMethod.debito => 'Cartão de Débito',
        PaymentMethod.pix => 'Pix',
        PaymentMethod.transferencia => 'Transferência',
        PaymentMethod.outro => 'Outro',
      };

  static PaymentMethod fromFirestore(String v) {
    switch (v) {
      case 'dinheiro':
        return PaymentMethod.dinheiro;
      case 'credito':
        return PaymentMethod.credito;
      case 'debito':
        return PaymentMethod.debito;
      case 'pix':
        return PaymentMethod.pix;
      case 'transferencia':
        return PaymentMethod.transferencia;
      default:
        return PaymentMethod.outro;
    }
  }

  String get firestoreValue => switch (this) {
        PaymentMethod.dinheiro => 'dinheiro',
        PaymentMethod.credito => 'credito',
        PaymentMethod.debito => 'debito',
        PaymentMethod.pix => 'pix',
        PaymentMethod.transferencia => 'transferencia',
        PaymentMethod.outro => 'outro',
      };
}

class AppTransaction {
  final String id;
  final TransactionType type;
  final String category;
  final String description;
  final double amount;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final bool recurring;
  final String? recurrence;
  final String? generatedFrom;
  final List<String> skippedOccurrences;
  final String? notes;
  final String? receiptUrl;
  final String? budgetId;

  const AppTransaction({
    required this.id,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.recurring = false,
    this.recurrence,
    this.generatedFrom,
    this.skippedOccurrences = const [],
    this.notes,
    this.receiptUrl,
    this.budgetId,
  });

  /// Factory validado (RN01): proibe valores <= 0 em movimentacoes.
  /// Use para criar novas transacoes a partir da UI. Lanca [ArgumentError]
  /// se [amount] for menor ou igual a zero. [fromMap] permanece resiliente
  /// para leitura do Firestore (nao quebra com registros antigos/invalidos).
  factory AppTransaction.create({
    required String id,
    required TransactionType type,
    required String category,
    required String description,
    required double amount,
    required DateTime date,
    required PaymentMethod paymentMethod,
    bool recurring = false,
    String? recurrence,
    String? generatedFrom,
    List<String> skippedOccurrences = const [],
    String? notes,
    String? receiptUrl,
    String? budgetId,
  }) {
    if (amount <= 0) {
      throw ArgumentError(
          'O valor da transação deve ser maior que zero (RN01).');
    }
    final effectiveRecurring = recurrence != null || recurring;
    return AppTransaction(
      id: id,
      type: type,
      category: category,
      description: description,
      amount: amount,
      date: date,
      paymentMethod: paymentMethod,
      recurring: effectiveRecurring,
      recurrence: recurrence,
      generatedFrom: generatedFrom,
      skippedOccurrences: skippedOccurrences,
      notes: notes,
      receiptUrl: receiptUrl,
      budgetId: budgetId,
    );
  }

  factory AppTransaction.fromMap(String id, Map<String, dynamic> m) {
    final rawDate = m['date'];
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
    final recurring = (m['recurring'] ?? false) as bool;
    final recurrence = m['recurrence'] as String?;
    final rawSkipped = m['skippedOccurrences'];
    final skippedOccurrences = rawSkipped is List
        ? rawSkipped.whereType<String>().toList()
        : const <String>[];

    return AppTransaction(
      id: id,
      type: TransactionTypeExt.fromFirestore((m['type'] ?? 'despesa') as String),
      category: (m['category'] ?? 'Outros') as String,
      description: (m['description'] ?? '') as String,
      amount: ((m['amount'] ?? 0) as num).toDouble(),
      date: date,
      paymentMethod:
          PaymentMethodExt.fromFirestore((m['paymentMethod'] ?? 'outro') as String),
      recurring: recurrence != null || recurring,
      recurrence: recurrence,
      generatedFrom: m['generatedFrom'] as String?,
      skippedOccurrences: skippedOccurrences,
      notes: m['notes'] as String?,
      receiptUrl: m['receiptUrl'] as String?,
      budgetId: m['budgetId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.firestoreValue,
        'category': category,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'paymentMethod': paymentMethod.firestoreValue,
        'recurring': recurring,
        'recurrence': recurrence,
        'generatedFrom': generatedFrom,
        'skippedOccurrences': skippedOccurrences,
        'notes': notes,
        'receiptUrl': receiptUrl,
        'budgetId': budgetId,
      };

  String? get effectiveRecurrence => recurrence ?? (recurring ? 'mensal' : null);

  DateTime? nextOccurrence(DateTime after) {
    final frequency = effectiveRecurrence;
    if (frequency == null) return null;
    return nextOccurrenceAfter(
      startDate: date,
      frequency: frequency,
      after: after,
    );
  }

  AppTransaction copyWith({
    TransactionType? type,
    String? category,
    String? description,
    double? amount,
    DateTime? date,
    PaymentMethod? paymentMethod,
    bool? recurring,
    String? recurrence,
    String? generatedFrom,
    List<String>? skippedOccurrences,
    String? notes,
    String? receiptUrl,
    String? budgetId,
  }) =>
      AppTransaction(
        id: id,
        type: type ?? this.type,
        category: category ?? this.category,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        recurring: recurring ?? this.recurring,
        recurrence: recurrence ?? this.recurrence,
        generatedFrom: generatedFrom ?? this.generatedFrom,
        skippedOccurrences: skippedOccurrences ?? this.skippedOccurrences,
        notes: notes ?? this.notes,
        receiptUrl: receiptUrl ?? this.receiptUrl,
        budgetId: budgetId ?? this.budgetId,
      );
}