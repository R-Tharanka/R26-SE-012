import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/farmer_ui.dart';
import '../data/history_repository.dart';
import '../history_scope.dart';
import '../models/history_record.dart';
import '../widgets/history_labels.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _pageSize = 20;
  HistoryRepository? _repository;
  List<HistoryRecord> _records = const [];
  HistoryCursor? _nextCursor;
  HistoryFeature? _filter;
  bool _loading = true;
  bool _loadingMore = false;
  bool _clearing = false;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = HistoryScope.maybeOf(context);
    if (identical(repository, _repository)) return;
    _repository?.removeListener(_repositoryChanged);
    _repository = repository;
    repository?.addListener(_repositoryChanged);
    unawaited(_refresh(runMaintenance: true));
  }

  @override
  void dispose() {
    _repository?.removeListener(_repositoryChanged);
    super.dispose();
  }

  void _repositoryChanged() {
    if (mounted && !_loading && !_loadingMore && !_clearing) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh({bool runMaintenance = false}) async {
    final repository = _repository;
    if (repository == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (runMaintenance) await repository.runMaintenance();
      final page = await repository.fetchPage(
        limit: _pageSize,
        feature: _filter,
      );
      if (!mounted) return;
      setState(() {
        _records = page.records;
        _nextCursor = page.nextCursor;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final repository = _repository;
    final cursor = _nextCursor;
    if (repository == null || cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await repository.fetchPage(
        limit: _pageSize,
        before: cursor,
        feature: _filter,
      );
      if (!mounted) return;
      setState(() {
        final ids = _records.map((record) => record.id).toSet();
        _records = [
          ..._records,
          ...page.records.where((record) => ids.add(record.id)),
        ];
        _nextCursor = page.nextCursor;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loadingMore = false;
      });
    }
  }

  Future<void> _setFilter(HistoryFeature? value) async {
    if (_filter == value) return;
    setState(() => _filter = value);
    await _refresh();
  }

  Future<void> _setAutoDelete(bool enabled) async {
    final repository = _repository;
    if (repository == null) return;
    try {
      final result = await repository.setAutoDeleteEnabled(enabled);
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.pending > 0
                ? t.historyClearPartial
                : t.historyAutoDeleteUpdated,
          ),
        ),
      );
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).historyUnavailableMessage),
        ),
      );
    }
  }

  Future<void> _clearAll() async {
    final repository = _repository;
    if (repository == null || _clearing) return;
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.historyClearConfirmTitle),
        content: Text(t.historyClearConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.historyCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.historyClearConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _clearing = true);
    try {
      final result = await repository.clearAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isComplete ? t.historyClearSuccess : t.historyClearPartial,
          ),
        ),
      );
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.historyClearPartial)));
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final repository = _repository;
    if (repository == null) {
      return FarmerEmptyState(
        icon: Icons.storage_outlined,
        title: t.historyUnavailableTitle,
        message: t.historyUnavailableMessage,
      );
    }
    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: () => _refresh(runMaintenance: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            kPagePadding,
            12,
            kPagePadding,
            32,
          ),
          children: [
            FarmerSectionHeader(title: t.navHistory, subtitle: t.historyIntro),
            const SizedBox(height: 16),
            _SettingsCard(
              enabled: repository.autoDeleteEnabled,
              clearing: _clearing,
              onChanged: _setAutoDelete,
              onClear: _clearAll,
            ),
            const SizedBox(height: 16),
            _filters(t),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _errorCard(t)
            else if (_records.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: FarmerEmptyState(
                  icon: Icons.history_rounded,
                  title: t.historyEmptyTitle,
                  message: t.historyEmptyMessage,
                ),
              )
            else ...[
              for (final record in _records)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryCard(
                    record: record,
                    imageFile: repository.imageFile(record),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => HistoryDetailScreen(record: record),
                      ),
                    ),
                  ),
                ),
              if (_nextCursor != null)
                OutlinedButton.icon(
                  onPressed: _loadingMore ? null : _loadMore,
                  icon: _loadingMore
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more_rounded),
                  label: Text(
                    _loadingMore ? t.historyLoadingMore : t.historyLoadMore,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filters(AppLocalizations t) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ChoiceChip(
        label: Text(t.historyAllTypes),
        selected: _filter == null,
        onSelected: (_) => _setFilter(null),
      ),
      for (final feature in HistoryFeature.values)
        ChoiceChip(
          label: Text(historyFeatureLabel(t, feature)),
          selected: _filter == feature,
          onSelected: (_) => _setFilter(feature),
        ),
    ],
  );

  Widget _errorCard(AppLocalizations t) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(
            Icons.storage_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            t.historyUnavailableTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(t.historyUnavailableMessage, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton(onPressed: _refresh, child: Text(t.retry)),
        ],
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.enabled,
    required this.clearing,
    required this.onChanged,
    required this.onClear,
  });

  final bool enabled;
  final bool clearing;
  final ValueChanged<bool> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Card(
      child: Column(
        children: [
          SwitchListTile.adaptive(
            title: Text(t.historyAutoDeleteTitle),
            subtitle: Text(t.historyAutoDeleteDescription),
            value: enabled,
            onChanged: onChanged,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.delete_sweep_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(t.historyClearAll),
            trailing: clearing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right_rounded),
            onTap: clearing ? null : onClear,
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.record,
    required this.imageFile,
    required this.onTap,
  });

  final HistoryRecord record;
  final File imageFile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMMMd(
      locale,
    ).add_jm().format(record.createdAtLocal);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: Image.file(
                imageFile,
                fit: BoxFit.cover,
                cacheWidth: 240,
                errorBuilder: (_, __, ___) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      historyFeatureLabel(t, record.feature),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      historyOutcomeLabel(t, record),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(date, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
