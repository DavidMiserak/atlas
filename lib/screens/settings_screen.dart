import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/backup_repository.dart';
import '../providers/session_provider.dart';
import '../utils/weight_calculator.dart';
import 'workout_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsRepo = SettingsRepository();
  final _backupRepo = BackupRepository();

  OneRmFormula _formula = OneRmFormula.rpeRts;
  bool _keepScreenAwakeDuringRest = false;
  bool _loading = true;
  bool _backupBusy = false;
  bool _restoreBusy = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final formula = await _settingsRepo.getOneRmFormula();
    final keepAwake = await _settingsRepo.getKeepScreenAwakeDuringRest();
    if (mounted) {
      setState(() {
        _formula = formula;
        _keepScreenAwakeDuringRest = keepAwake;
        _loading = false;
      });
    }
  }

  bool get _sessionActive =>
      context.read<SessionProvider>().currentSession != null;

  // ── Backup ──────────────────────────────────────────────────────────────────

  Future<void> _onBackupTap() async {
    if (_sessionActive) {
      _showSnack('Finish your current session before backing up.');
      return;
    }
    setState(() => _backupBusy = true);
    try {
      final path = await _backupRepo.createBackup();
      final savedTo = await _backupRepo.saveBackup(path);
      if (mounted) {
        _showSnack(
          savedTo != null ? 'Backup saved to $savedTo' : 'Backup created.',
        );
      }
    } catch (e) {
      developer.log('Backup failed: $e');
      if (mounted) _showError('Backup failed', e.toString());
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  // ── Restore ─────────────────────────────────────────────────────────────────

  Future<void> _onRestoreTap() async {
    if (_sessionActive) {
      _showSnack('Finish your current session before restoring.');
      return;
    }

    // Offer to backup first (D5)
    final shouldBackup = await _showConfirm(
      title: 'Back up first?',
      message:
          'Before restoring, would you like to save a backup of your current data?',
      confirmLabel: 'Back up first',
      cancelLabel: 'Skip backup',
    );
    if (!mounted) return;
    if (shouldBackup) {
      setState(() => _backupBusy = true);
      try {
        final path = await _backupRepo.createBackup();
        await _backupRepo.saveBackup(
          path,
        ); // result ignored here — pre-restore backup
      } catch (e) {
        if (mounted) _showError('Backup failed', e.toString());
        if (mounted) setState(() => _backupBusy = false);
        return;
      }
      if (mounted) setState(() => _backupBusy = false);
    }

    final proceed = await _showConfirm(
      title: 'Restore from backup?',
      message:
          'This will replace ALL current data with the backup. '
          'Your current data will be lost.',
      confirmLabel: 'Continue',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (!mounted || !proceed) return;

    final path = await _backupRepo.pickBackupFile();
    if (!mounted || path == null) return;

    setState(() => _restoreBusy = true);
    try {
      await _backupRepo.restoreBackup(path);
      if (!mounted) return;
      _navigateToRoot();
    } on FormatException catch (e) {
      if (mounted) _showError('Invalid backup', e.message);
    } on StateError catch (e) {
      if (mounted) _showError('Cannot restore', e.message);
    } catch (e) {
      developer.log('Restore failed: $e');
      if (mounted) {
        _showError('Restore failed', 'Please try again or reinstall the app.');
      }
    } finally {
      if (mounted) setState(() => _restoreBusy = false);
    }
  }

  // ── Clear 1RM History ────────────────────────────────────────────────────────

  Future<void> _onClearOneRmTap() async {
    final proceed = await _showConfirm(
      title: 'Clear 1RM history?',
      message:
          'This will delete all 1RM records for every exercise. '
          'Your training session history is preserved. '
          'The app will prompt for new 1RM estimates the next time you start each exercise.',
      confirmLabel: 'Clear 1RM History',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (!mounted || !proceed) return;
    try {
      await _settingsRepo.clearOneRmHistory();
      if (mounted) _showSnack('1RM history cleared.');
    } catch (e) {
      developer.log('Clear 1RM failed: $e');
      if (mounted) _showError('Clear failed', e.toString());
    }
  }

  // ── Factory Reset ────────────────────────────────────────────────────────────

  Future<void> _onFactoryResetTap() async {
    if (_sessionActive) {
      _showSnack('Finish your current session before resetting.');
      return;
    }
    final proceed = await _showConfirm(
      title: 'Factory reset?',
      message:
          'This will permanently delete ALL your data including workout '
          'history, 1RM records, and formula preference. '
          'You cannot undo this.',
      confirmLabel: 'Reset Everything',
      cancelLabel: 'Cancel',
      destructive: true,
      holdToConfirm: true,
    );
    if (!mounted || !proceed) return;

    try {
      await _settingsRepo.factoryReset();
      if (!mounted) return;
      _navigateToRoot();
    } catch (e) {
      developer.log('Factory reset failed: $e');
      if (mounted) _showError('Reset failed', e.toString());
    }
  }

  // ── Formula ──────────────────────────────────────────────────────────────────

  Future<void> _onFormulaChanged(OneRmFormula? value) async {
    if (value == null) return;
    await _settingsRepo.setOneRmFormula(value);
    if (mounted) {
      setState(() => _formula = value);
      _showSnack('Formula saved.');
    }
  }

  Future<void> _onKeepScreenAwakeChanged(bool value) async {
    await _settingsRepo.setKeepScreenAwakeDuringRest(value);
    if (mounted) {
      setState(() => _keepScreenAwakeDuringRest = value);
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _navigateToRoot() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const WorkoutSelectionScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
      (route) => false,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirm({
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool destructive = false,
    bool holdToConfirm = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => holdToConfirm
          ? _HoldToConfirmDialog(
              title: title,
              message: message,
              confirmLabel: confirmLabel,
              cancelLabel: cancelLabel,
            )
          : AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(cancelLabel),
                ),
                TextButton(
                  style: destructive
                      ? TextButton.styleFrom(foregroundColor: Colors.red)
                      : null,
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmLabel),
                ),
              ],
            ),
    );
    return result == true;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  ListView(
                    children: [
                      _SectionHeader(title: 'Training Data'),
                      _ActionTile(
                        icon: Icons.backup_outlined,
                        title: 'Backup Data',
                        subtitle: 'Save a copy of all your training data',
                        loading: _backupBusy,
                        enabled: !_backupBusy && !_restoreBusy,
                        onTap: _onBackupTap,
                      ),
                      _ActionTile(
                        icon: Icons.restore_outlined,
                        title: 'Restore from Backup',
                        subtitle: 'Replace all data with a previous backup',
                        loading: _restoreBusy,
                        enabled: !_backupBusy && !_restoreBusy,
                        onTap: _onRestoreTap,
                      ),
                      _ActionTile(
                        icon: Icons.delete_sweep_outlined,
                        title: 'Clear 1RM History',
                        subtitle:
                            'Delete all 1RM records — use when moving to a new gym',
                        enabled: !_backupBusy && !_restoreBusy,
                        onTap: _onClearOneRmTap,
                        destructive: true,
                      ),
                      _ActionTile(
                        icon: Icons.restart_alt_outlined,
                        title: 'Factory Reset',
                        subtitle: 'Delete all data and restore seed program',
                        enabled: !_backupBusy && !_restoreBusy,
                        onTap: _onFactoryResetTap,
                        destructive: true,
                      ),
                      const Divider(height: 32, indent: 16, endIndent: 16),
                      _SectionHeader(title: 'Rest Timer'),
                      SwitchListTile(
                        title: Text(
                          'Keep screen awake during rest timer',
                          style: GoogleFonts.outfit(fontSize: 15),
                        ),
                        subtitle: Text(
                          'Prevents auto-lock while the rest countdown is active.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF888888),
                          ),
                        ),
                        value: _keepScreenAwakeDuringRest,
                        onChanged: _onKeepScreenAwakeChanged,
                      ),
                      const Divider(height: 32, indent: 16, endIndent: 16),
                      _SectionHeader(title: '1RM Formula'),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<OneRmFormula>(
                              initialValue: _formula,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              items: OneRmFormula.values
                                  .map(
                                    (f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(
                                        f.displayName,
                                        style: GoogleFonts.outfit(fontSize: 14),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _onFormulaChanged,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Applies to new sessions only. Existing records are unchanged.',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                  if (_restoreBusy) const _RestoreProgressOverlay(),
                ],
              ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: const Color(0xFF888888),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final bool enabled;
  final bool destructive;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
    this.enabled = true,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red : null;
    return ListTile(
      leading: loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, color: enabled ? color : const Color(0xFF444444)),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: enabled ? color : const Color(0xFF444444),
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF888888)),
      ),
      enabled: enabled && !loading,
      onTap: onTap,
      minVerticalPadding: 12,
    );
  }
}

class _RestoreProgressOverlay extends StatelessWidget {
  const _RestoreProgressOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Restoring data…',
                  style: GoogleFonts.outfit(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please do not close the app.',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hold-to-confirm dialog ────────────────────────────────────────────────────

class _HoldToConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  const _HoldToConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  @override
  State<_HoldToConfirmDialog> createState() => _HoldToConfirmDialogState();
}

class _HoldToConfirmDialogState extends State<_HoldToConfirmDialog> {
  double _progress = 0;
  Timer? _timer;
  static const _holdDuration = Duration(seconds: 3);
  static const _tickInterval = Duration(milliseconds: 50);

  void _startHold() {
    _timer = Timer.periodic(_tickInterval, (t) {
      setState(() {
        _progress +=
            _tickInterval.inMilliseconds / _holdDuration.inMilliseconds;
        if (_progress >= 1.0) {
          t.cancel();
          Navigator.of(context).pop(true);
        }
      });
    });
  }

  void _cancelHold() {
    _timer?.cancel();
    setState(() => _progress = 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 20),
          GestureDetector(
            onTapDown: (_) => _startHold(),
            onTapUp: (_) => _cancelHold(),
            onTapCancel: _cancelHold,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 52,
                      backgroundColor: Colors.red.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.red,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      _progress > 0
                          ? widget.confirmLabel
                          : 'Hold to ${widget.confirmLabel}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancelLabel),
        ),
      ],
    );
  }
}
