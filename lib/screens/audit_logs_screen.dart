import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/price_audit_log.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';
import '../widgets/app_branded_header.dart';
import '../widgets/app_toast.dart';
import '../widgets/audit_entry_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/search_field.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  String _query = '';
  int _filterIndex = 0;

  List<PriceAuditLog> _logs = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  DocumentSnapshot? _lastDoc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _logs = [];
      _lastDoc = null;
      _hasMore = true;
    });
    try {
      final uid = context.read<UserProvider>().uid;
      final service = context.read<FirestoreService>();
      if (uid == null) throw StateError('Usuário não autenticado.');
      final page = await service.fetchPriceAuditLogs(uid, limit: 50);
      setState(() {
        _logs = page.logs;
        _lastDoc = page.lastDoc;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final uid = context.read<UserProvider>().uid;
    if (uid == null) return;
    setState(() => _loadingMore = true);
    try {
      final service = context.read<FirestoreService>();
      final page = await service.fetchPriceAuditLogs(
        uid,
        limit: 50,
        startAfter: _lastDoc,
      );
      setState(() {
        _logs.addAll(page.logs);
        _lastDoc = page.lastDoc;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() => _loadingMore = false);
      if (!mounted) return;
      AppToast.error(context, 'Erro ao carregar mais: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBrandedHeader(title: 'Auditoria', showBack: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (_error != null) {
      return ErrorState(
        message: 'Não foi possível carregar o histórico.',
        onRetry: _loadInitial,
      );
    }

    final logs = _applyFilters(_logs);

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.card,
      onRefresh: _loadInitial,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registro de ações',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppTypography.section,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tudo que altera custos, ofertas e fichas técnicas aparece aqui.',
                  style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                AppSearchField(
                  hint: 'Buscar por ação, produto ou fornecedor…',
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                AppFilterChipRow(
                  options: const [
                    'Tudo',
                    'Produtos',
                    'Ofertas',
                    'Fichas técnicas',
                    'Sistema',
                  ],
                  selectedIndex: _filterIndex,
                  onSelected: (index) =>
                      setState(() => _filterIndex = index),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: logs.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long,
                    title: 'Nenhuma ação registrada',
                    message:
                        'Alterações em produtos, ofertas e fichas técnicas aparecerão aqui.',
                  )
                : _buildTimeline(logs),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<PriceAuditLog> logs) {
    final groups = _groupByDay(logs);
    final keys = groups.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
      itemCount: keys.length + 1,
      itemBuilder: (context, index) {
        if (index == keys.length) {
          return _buildLoadMore();
        }
        final key = keys[index];
        final dayLogs = groups[key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _dayLabel(key),
                style: const TextStyle(
                  color: AppColors.textSec,
                  fontSize: AppTypography.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  ...dayLogs.asMap().entries.map((entry) {
                    final log = entry.value;
                    final isLast = entry.key == dayLogs.length - 1;
                    return Column(
                      children: [
                        InkWell(
                          onTap: () => _showDetail(context, log),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: AuditEntryTile(log: log),
                          ),
                        ),
                        if (!isLast)
                          const Divider(
                            color: AppColors.border,
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadMore() {
    if (!_hasMore && _logs.length >= 50) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Fim do histórico',
            style: TextStyle(
                color: AppColors.textSec,
                fontSize: AppTypography.secondary),
          ),
        ),
      );
    }
    if (!_hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _loadingMore
            ? const CircularProgressIndicator(color: AppColors.gold)
            : TextButton(
                onPressed: _loadMore,
                child: const Text(
                  'Carregar mais',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }

  void _showDetail(BuildContext context, PriceAuditLog log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      _iconFor(log.action),
                      color: _isDestructive(log.action)
                          ? AppColors.danger
                          : AppColors.gold,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        log.summary,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppTypography.section,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _fullTimestamp(log),
                  style: const TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.body,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_entityTypeLabel(log.entityType)} · ${log.action}',
                  style: const TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                if (log.previousPrice != null && log.newPrice != null)
                  Text(
                    'Anterior: ${formatCurrencyAbs(log.previousPrice!)} → Novo: ${formatCurrencyAbs(log.newPrice!)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppTypography.body,
                    ),
                  )
                else if (log.newPrice != null)
                  Text(
                    'Novo valor: ${formatCurrencyAbs(log.newPrice!)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppTypography.body,
                    ),
                  ),
                if (log.supplier != null && log.supplier!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Fornecedor: ${log.supplier}',
                    style: const TextStyle(
                      color: AppColors.textSec,
                      fontSize: AppTypography.body,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<PriceAuditLog> _applyFilters(List<PriceAuditLog> logs) {
    final query = _query.trim().toLowerCase();
    var result = logs;

    if (query.isNotEmpty) {
      result = result.where((log) {
        final text =
            '${log.action} ${log.summary} ${log.supplier ?? ''}'.toLowerCase();
        return text.contains(query);
      }).toList();
    }

    switch (_filterIndex) {
      case 1:
        result = result.where((log) => log.entityType == 'ingredient').toList();
      case 2:
        result = result.where((log) => log.entityType == 'offer').toList();
      case 3:
        result = result.where((log) => log.entityType == 'product').toList();
      case 4:
        result = result.where((log) {
          return log.entityType == 'migration' ||
              log.source == 'system' ||
              !['ingredient', 'offer', 'product']
                  .contains(log.entityType);
        }).toList();
    }

    return result;
  }

  Map<DateTime, List<PriceAuditLog>> _groupByDay(List<PriceAuditLog> logs) {
    final groups = <DateTime, List<PriceAuditLog>>{};
    for (final log in logs) {
      final timestamp = log.timestamp;
      if (timestamp == null) continue;
      final day = DateTime(
        timestamp.year,
        timestamp.month,
        timestamp.day,
      );
      groups.putIfAbsent(day, () => []).add(log);
    }
    final sorted = groups.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(sorted);
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (day == today) return 'Hoje';
    if (day == yesterday) return 'Ontem';
    return formatDate(day);
  }

  String _fullTimestamp(PriceAuditLog log) {
    final timestamp = log.timestamp;
    if (timestamp == null) return '';
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${formatDate(timestamp)} às $hour:$minute';
  }

  bool _isDestructive(String action) => action.contains('.delete');

  String _entityTypeLabel(String entityType) {
    switch (entityType) {
      case 'ingredient':
        return 'Produto';
      case 'offer':
        return 'Oferta';
      case 'product':
        return 'Ficha técnica';
      default:
        return 'Sistema';
    }
  }

  IconData _iconFor(String action) {
    if (action.contains('.create')) return Icons.add_circle_outline;
    if (action.contains('.update')) return Icons.edit_outlined;
    if (action.contains('.delete')) return Icons.delete_outline;
    if (action.contains('setActive') || action.contains('toggleActive')) {
      return Icons.check_circle_outline;
    }
    if (action.contains('migration')) return Icons.sync;
    return Icons.receipt_long;
  }
}
