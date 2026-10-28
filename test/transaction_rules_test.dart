import 'package:ctrlcash/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTransaction.create', () {
    test('aceita amount maior que zero', () {
      final tx = AppTransaction.create(
        id: 'tx1',
        type: TransactionType.receita,
        category: 'Vendas',
        description: 'Venda 1',
        amount: 10.50,
        date: DateTime(2024, 1, 1),
        paymentMethod: PaymentMethod.pix,
      );

      expect(tx.amount, 10.50);
      expect(tx.type, TransactionType.receita);
    });

    test('rejeita amount zero', () {
      expect(
        () => AppTransaction.create(
          id: 'tx1',
          type: TransactionType.despesa,
          category: 'Outros',
          description: 'Despesa',
          amount: 0,
          date: DateTime(2024, 1, 1),
          paymentMethod: PaymentMethod.dinheiro,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejeita amount negativo', () {
      expect(
        () => AppTransaction.create(
          id: 'tx1',
          type: TransactionType.despesa,
          category: 'Outros',
          description: 'Despesa',
          amount: -0.01,
          date: DateTime(2024, 1, 1),
          paymentMethod: PaymentMethod.dinheiro,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('AppTransaction.fromMap', () {
    test('preserva valores validos', () {
      final tx = AppTransaction.fromMap('tx1', {
        'type': 'receita',
        'category': 'Vendas',
        'description': 'Venda',
        'amount': 25.0,
        'date': '2024-06-15T10:30:00.000',
        'paymentMethod': 'pix',
        'recurring': true,
        'notes': 'obs',
        'receiptUrl': 'https://example.com/recibo.png',
        'budgetId': 'b1',
      });

      expect(tx.id, 'tx1');
      expect(tx.type, TransactionType.receita);
      expect(tx.category, 'Vendas');
      expect(tx.description, 'Venda');
      expect(tx.amount, 25.0);
      expect(tx.date, DateTime(2024, 6, 15, 10, 30));
      expect(tx.paymentMethod, PaymentMethod.pix);
      expect(tx.recurring, true);
      expect(tx.notes, 'obs');
      expect(tx.receiptUrl, 'https://example.com/recibo.png');
      expect(tx.budgetId, 'b1');
    });

    test('resiliente a valores absurdos de amount', () {
      final tx = AppTransaction.fromMap('tx1', {
        'amount': -999,
      });

      expect(tx.amount, -999.0);
    });

    test('resiliente a map vazio', () {
      final tx = AppTransaction.fromMap('tx1', {});

      expect(tx.type, TransactionType.despesa);
      expect(tx.category, 'Outros');
      expect(tx.description, '');
      expect(tx.amount, 0.0);
      expect(tx.paymentMethod, PaymentMethod.outro);
      expect(tx.recurring, false);
    });

    test('valores invalidos de tipo viram despesa', () {
      final tx = AppTransaction.fromMap('tx1', {
        'type': 'invalido',
      });

      expect(tx.type, TransactionType.despesa);
    });

    test('valores invalidos de paymentMethod viram outro', () {
      final tx = AppTransaction.fromMap('tx1', {
        'paymentMethod': 'invalido',
      });

      expect(tx.paymentMethod, PaymentMethod.outro);
    });

    test('date string invalida usa DateTime.now', () {
      final before = DateTime.now();
      final tx = AppTransaction.fromMap('tx1', {
        'date': 'invalido',
      });
      final after = DateTime.now();

      expect(tx.date.isAfter(before) || tx.date.isAtSameMomentAs(before), true);
      expect(tx.date.isBefore(after) || tx.date.isAtSameMomentAs(after), true);
    });
  });
}
