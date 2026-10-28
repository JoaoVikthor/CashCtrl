import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_user.dart';
import '../models/budget.dart';
import '../models/ingredient.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../utils/product_calculator.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'cashctrl_alertas';
  static const String _channelName = 'Alertas';
  static const String _channelDescription =
      'Alertas de orçamento, contas recorrentes e margem de produtos.';

  static const int _idOrcamento = 1001;
  static const int _idRecorrentes = 1002;
  static const int _idMargem = 1003;

  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(id, title, body, notificationDetails);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  Future<void> runStartupChecks({
    required AppUser user,
    required List<Budget> budgets,
    required List<AppTransaction> transactions,
    required List<Product> products,
    required List<Ingredient> ingredients,
    DateTime? now,
  }) async {
    if (kIsWeb) return;
    await initialize();

    final current = now ?? DateTime.now();
    final futures = <Future<void>>[];

    if (user.notifOrcamento) {
      final count = _countOverBudgets(budgets, transactions, current);
      if (count > 0) {
        futures.add(show(
          id: _idOrcamento,
          title: 'Orçamento estourado',
          body:
              '$count ${count == 1 ? 'orçamento estourou' : 'orçamentos estouraram'} este mês',
        ));
      } else {
        await _plugin.cancel(_idOrcamento);
      }
    }

    if (user.notifRecorrentes) {
      final count = _countUpcomingRecurrences(transactions, current);
      if (count > 0) {
        futures.add(show(
          id: _idRecorrentes,
          title: 'Contas recorrentes',
          body:
              '$count ${count == 1 ? 'conta recorrente vence' : 'contas recorrentes vencem'} em até 3 dias',
        ));
      } else {
        await _plugin.cancel(_idRecorrentes);
      }
    }

    if (user.notifMargem) {
      final count = _countNegativeMarginProducts(products, ingredients);
      if (count > 0) {
        futures.add(show(
          id: _idMargem,
          title: 'Margem negativa',
          body:
              '$count ${count == 1 ? 'produto está no vermelho' : 'produtos estão no vermelho'} — veja o ticket',
        ));
      } else {
        await _plugin.cancel(_idMargem);
      }
    }

    await Future.wait(futures);
  }

  int _countOverBudgets(
      List<Budget> budgets, List<AppTransaction> transactions, DateTime now) {
    final spentByCategory = <String, double>{};
    for (final t in transactions) {
      if (t.type.isReceita) continue;
      if (t.date.month == now.month && t.date.year == now.year) {
        spentByCategory[t.category] =
            (spentByCategory[t.category] ?? 0) + t.amount;
      }
    }

    var count = 0;
    for (final b in budgets) {
      final spent = spentByCategory[b.category] ?? 0;
      if (spent > b.limit) count++;
    }
    return count;
  }

  int _countUpcomingRecurrences(
      List<AppTransaction> transactions, DateTime now) {
    final threshold = now.add(const Duration(days: 3));
    var count = 0;
    for (final t in transactions) {
      if (t.generatedFrom != null) continue;
      final next = t.nextOccurrence(now);
      if (next == null) continue;
      if (!next.isAfter(threshold)) count++;
    }
    return count;
  }

  int _countNegativeMarginProducts(
      List<Product> products, List<Ingredient> ingredients) {
    final ingredientMap = {for (final i in ingredients) i.id: i};
    var count = 0;
    for (final p in products) {
      final result = ProductCalculator.calculate(p, ingredientMap);
      if (result.isPrejuizo) count++;
    }
    return count;
  }
}
