import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';
import '../router.dart';

class InactivityWatcher extends StatefulWidget {
  final Widget child;
  final VoidCallback onLogout;

  const InactivityWatcher({super.key, required this.child, required this.onLogout});

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _warningTimer;
  Timer? _logoutTimer;
  bool _isWarningOpen = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  bool _onKey(KeyEvent event) { 
    _restartTimers(); 
    return false; 
  }

  void _restartTimers() {
    if (_isWarningOpen) return;
    
    final auth = context.read<AuthNotifier>();
    if (!auth.isAuthenticated) {
      _warningTimer?.cancel();
      _logoutTimer?.cancel();
      return;
    }

    _warningTimer?.cancel();
    _logoutTimer?.cancel();

    _warningTimer = Timer(const Duration(seconds: 150), _showWarning);
    
    _logoutTimer = Timer(const Duration(minutes: 3), () {
      _isWarningOpen = false; 
      
      final dialogContext = rootNavigatorKey.currentContext;
      if (dialogContext != null && Navigator.of(dialogContext, rootNavigator: true).canPop()) {
        Navigator.of(dialogContext, rootNavigator: true).pop();
      }
      
      widget.onLogout(); 
    });
  }

  void _showWarning() {
    final dialogContext = rootNavigatorKey.currentContext;
    if (dialogContext == null) return;

    _isWarningOpen = true;
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('Сессия истекает'),
        content: const Text('Вы были неактивны. Через 30 секунд произойдет выход из системы.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(c);
              _isWarningOpen = false;
              _restartTimers(); 
            },
            child: const Text('Остаться в системе'),
          )
        ],
      )
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _warningTimer?.cancel(); 
    _logoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restartTimers(),
      onPointerMove: (_) => _restartTimers(),
      onPointerHover: (_) => _restartTimers(),
      child: widget.child,
    );
  }
}