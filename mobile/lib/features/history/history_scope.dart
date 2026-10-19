// =============================================================================
// File: history_scope.dart
// Purpose: Supports the local-first history scope history workflow.
// =============================================================================
import 'dart:async';

import 'package:flutter/material.dart';

import 'data/history_repository.dart';

class HistoryScope extends StatefulWidget {
  const HistoryScope({
    super.key,
    required this.repository,
    required this.child,
  });

  final HistoryRepository repository;
  final Widget child;

  // Process maybe of for this flow.
  static HistoryRepository? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_HistoryInherited>()
      ?.repository;

  @override
  // Create the mutable state object for this widget.
  State<HistoryScope> createState() => _HistoryScopeState();
}

class _HistoryScopeState extends State<HistoryScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    // Initialize controllers, listeners, and first-load state.
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Respond safely when the application lifecycle changes.
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.repository.runMaintenance());
    }
  }

  @override
  void dispose() {
    // Release controllers, listeners, and other owned resources.
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  // Build and return this widget's current interface.
  Widget build(BuildContext context) =>
      _HistoryInherited(repository: widget.repository, child: widget.child);
}

class _HistoryInherited extends InheritedNotifier<HistoryRepository> {
  const _HistoryInherited({required this.repository, required super.child})
    : super(notifier: repository);

  final HistoryRepository repository;
}
