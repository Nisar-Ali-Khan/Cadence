import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/cloud_sync_service.dart';
import '../widgets/section_card.dart';
import 'edit_profile_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';
import 'help_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, bool> reminders;
  final int cycleLength;
  final DateTime cycleStartDate;
  final List<String> medicationNames;
  final void Function(String key) onToggle;
  final VoidCallback onToggleTheme;
  final void Function(List<String> names) onUpdateMeds;
  final VoidCallback onDataChanged;

  const ProfileScreen({
    super.key,
    required this.reminders,
    required this.cycleLength,
    required this.cycleStartDate,
    required this.medicationNames,
    required this.onToggle,
    required this.onToggleTheme,
    required this.onUpdateMeds,
    required this.onDataChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final StorageService _storage;
  Map<String, List<int>> _times = {'medication': [9, 0], 'dailyLog': [20, 0]};
  bool _timesLoading = true;
  bool _appLockEnabled = false;
  List<String> _trackingGoals = [];
  String _condition = 'PCOS';

  @override
  void initState() {
    super.initState();
    final uid = AuthService().currentUser?.uid ?? 'guest';
    _storage = StorageService(uid);
    _loadProfileExtras();
  }

  Future<void> _loadProfileExtras() async {
    final loaded = await _storage.loadReminderTimes();
    final lockEnabled = await _storage.loadAppLockEnabled();
    final goals = await _storage.loadTrackingGoals();
    final condition = await _storage.loadCondition();
    if (!mounted) return;
    setState(() {
      _times = loaded;
      _appLockEnabled = lockEnabled;
      _trackingGoals = goals;
      _condition = condition;
      _timesLoading = false;
    });

    if (widget.reminders['medication'] == true) _scheduleReminder('medication');
    if (widget.reminders['dailyLog'] == true) _scheduleReminder('dailyLog');
  }

  int _idFor(String key) => key == 'medication' ? NotificationService.medicationId : NotificationService.dailyLogId;

  Future<void> _scheduleReminder(String key) async {
    final time = _times[key] ?? [9, 0];
    final isMedication = key == 'medication';
    await NotificationService().scheduleDaily(
      id: _idFor(key),
      title: isMedication ? 'Time for your medication' : 'Quick check-in',
      body: isMedication ? "Don't forget today's dose." : "How are you feeling today? Log it in Cadence.",
      hour: time[0],
      minute: time[1],
    );
  }

  Future<void> _handleToggle(String key) async {
    final willEnable = !(widget.reminders[key] ?? false);
    widget.onToggle(key);
    if (willEnable) {
      await _scheduleReminder(key);
      if (mounted) await _pickTime(key);
    } else {
      await NotificationService().cancel(_idFor(key));
    }
  }

  Future<void> _pickTime(String key) async {
    final current = _times[key] ?? [9, 0];
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current[0], minute: current[1]),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: AppColors.sage, onPrimary: Colors.black, surface: Color(0xFF1E1E1E), onSurface: Colors.white)
                : const ColorScheme.light(primary: AppColors.plum, onPrimary: AppColors.white, surface: AppColors.sand, onSurface: AppColors.ink),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    setState(() => _times[key] = [picked.hour, picked.minute]);
    await _storage.saveReminderTime(key, picked.hour, picked.minute);
    if (widget.reminders[key] == true) await _scheduleReminder(key);
  }

  Future<void> _toggleAppLock() async {
    setState(() => _appLockEnabled = !_appLockEnabled);
    await _storage.saveAppLockEnabled(_appLockEnabled);
  }

  String _formatTime(List<int> t) {
    final tod = TimeOfDay(hour: t[0], minute: t[1]);
    final hour12 = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  String _initials(String? name, String? email) {
    if (name != null && name.trim().isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  Future<void> _exportData(BuildContext context) async {
    final uid = AuthService().currentUser?.uid ?? 'guest';
    final data = await StorageService(uid).exportAllData();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cadence_data_export.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    await Share.shareXFiles([XFile(file.path)], text: 'My Cadence data export (JSON)');
  }

  Future<void> _exportCSV(BuildContext context) async {
    final uid = AuthService().currentUser?.uid ?? 'guest';
    final storage = StorageService(uid);
    final logs = await storage.loadDailyLogs();
    final notes = await storage.loadDailyNotes();
    final medLog = await storage.loadMedicationLog();
    final waterLog = await storage.loadWaterLog();
    final weightLog = await storage.loadWeightLog();

    final buffer = StringBuffer();
    buffer.writeln('Cycle Day,Pain,Fatigue,Mood,Bloating,Acne,Sleep,Medication,Water(glasses),Weight(kg),Note');

    final sortedDays = logs.keys.toList()..sort();
    for (final day in sortedDays) {
      final l = logs[day]!;
      final note = (notes[day] ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
      final dayMeds = medLog[day] ?? {};
      final med = dayMeds.values.any((v) => v) ? 'Yes' : 'No';
      final water = waterLog[day] ?? 0;
      final weight = weightLog[day]?.toString() ?? '';
      final acne = l['acne'] ?? 1;
      final sleep = l['sleep'] ?? 7;
      buffer.writeln('$day,${l['pain']},${l['fatigue']},${l['mood']},${l['bloating']},$acne,$sleep,$med,$water,$weight,$note');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cadence_data_export.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'My Cadence data export (CSV)');
  }

  Future<void> _contactEmail(BuildContext context) async {
    try {
      final uri = Uri(
        scheme: 'mailto',
        path: 'nisar.uetm@gmail.com',
        query: 'subject=${Uri.encodeComponent('Cadence Support')}',
      );
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        _copyEmailFallback(context);
      }
    } catch (_) {
      if (context.mounted) _copyEmailFallback(context);
    }
  }

  void _copyEmailFallback(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: 'nisar.uetm@gmail.com'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No email app found — address copied instead.')),
    );
  }

  Future<void> _contactWhatsapp(BuildContext context) async {
    try {
      final uri = Uri.parse('https://wa.me/923299984514?text=Hi%2C%20I%20need%20help%20with%20Cadence');
      // externalApplication is better for deep linking, but fall back to default if it fails
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening WhatsApp.')),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Log out?', style: AppText.display(context: context, size: 18)),
          content: Text('You can sign back in anytime — your data stays saved.', style: AppText.body(context: context, size: 13.5, color: AppColors.muted)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: AppText.body(context: context, size: 14, color: AppColors.muted))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Log out', style: AppText.body(context: context, size: 14, weight: FontWeight.w700, color: AppColors.rose))),
          ],
        );
      },
    );
    if (confirmed == true) await AuthService().signOut();
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete your account?', style: AppText.display(context: context, size: 18)),
          content: Text(
            'This permanently deletes your account and all logged data, on this device and in the cloud. This can\'t be undone.',
            style: AppText.body(context: context, size: 13.5, color: AppColors.muted),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: AppText.body(context: context, size: 14, color: AppColors.muted))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: AppText.body(context: context, size: 14, weight: FontWeight.w700, color: AppColors.rose))),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final uid = AuthService().currentUser?.uid;
    if (uid != null) {
      await StorageService(uid).clearAllUserData();
      await CloudSyncService(uid).deleteAllCloudData();
    }
    await NotificationService().cancel(NotificationService.medicationId);
    await NotificationService().cancel(NotificationService.dailyLogId);
    final error = await AuthService().deleteAccount();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;
    final displayName = (user?.displayName?.isNotEmpty ?? false) ? user!.displayName! : 'Your profile';
    final email = user?.email ?? '';
    final createdAt = user?.metadata.creationTime;
    final memberSince = createdAt != null ? '${_month(createdAt.month)} ${createdAt.year}' : 'recently';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text('You', style: AppText.display(context: context, size: 24)),
        const SizedBox(height: 16),

        SectionCard(
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(color: AppColors.plum, shape: BoxShape.circle),
                child: Center(child: Text(_initials(user?.displayName, email), style: AppText.display(context: context, size: 20, color: AppColors.white))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: AppText.body(context: context, size: 16, weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(email, style: AppText.body(context: context, size: 12.5, color: AppColors.muted)),
                    const SizedBox(height: 3),
                    Text('Member since $memberSince', style: AppText.body(context: context, size: 11.5, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),

        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            if (changed == true) {
              widget.onDataChanged();
              await _loadProfileExtras();
            }
          },
          child: SectionCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.sage.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.favorite_outline, size: 18, color: AppColors.sage),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(_condition, style: AppText.body(context: context, size: 13.5, weight: FontWeight.w700)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.plum.withOpacity(0.08), borderRadius: BorderRadius.circular(99)),
                            child: Text('${widget.cycleLength}-day cycle', style: AppText.body(context: context, size: 10.5, weight: FontWeight.w600, color: isDark ? AppColors.sageLight : AppColors.plum)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Last period: ${widget.cycleStartDate.day}/${widget.cycleStartDate.month}/${widget.cycleStartDate.year} · tap to edit',
                        style: AppText.body(context: context, size: 11.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
              ],
            ),
          ),
        ),

        if (_trackingGoals.isNotEmpty)
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tracking', style: AppText.display(context: context, size: 15)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _trackingGoals.map((goal) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: AppColors.plum.withOpacity(0.08), borderRadius: BorderRadius.circular(99)),
                      child: Text(goal, style: AppText.body(context: context, size: 12, weight: FontWeight.w600, color: isDark ? AppColors.sageLight : AppColors.plum)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reminders', style: AppText.display(context: context, size: 16)),
              const SizedBox(height: 4),
              _timesLoading
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator(color: AppColors.plum))
                  : Column(children: [_reminderRow(context, 'Medication reminder', 'medication'), const SizedBox(height: 6), _reminderRow(context, 'Daily log nudge', 'dailyLog')]),
            ],
          ),
        ),

        SectionCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.plum.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.fingerprint, size: 18, color: isDark ? AppColors.sageLight : AppColors.plum),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('App lock', style: AppText.body(context: context, size: 13.5, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Require fingerprint or face unlock to open Cadence', style: AppText.body(context: context, size: 11.5, color: AppColors.muted)),
                  ],
                ),
              ),
              Switch(value: _appLockEnabled, onChanged: (_) => _toggleAppLock(), activeColor: AppColors.sage),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text('Settings', style: AppText.display(context: context, size: 16)),
        ),

        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _actionRow(context, icon: Icons.medication_outlined, label: 'Manage medications', onTap: () => _manageMeds(context)),
              _divider(context),
              _actionRow(context,
                  icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  label: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  onTap: widget.onToggleTheme),
              _divider(context),
              _actionRow(context, icon: Icons.lock_reset, label: 'Change password', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))),
              _divider(context),
              _actionRow(context, icon: Icons.download_outlined, label: 'Export JSON', onTap: () => _exportData(context)),
              _divider(context),
              _actionRow(context, icon: Icons.table_chart_outlined, label: 'Export CSV', onTap: () => _exportCSV(context)),
              _divider(context),
              _actionRow(context, icon: Icons.shield_outlined, label: 'Privacy Policy', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
              _divider(context),
              _actionRow(context, icon: Icons.description_outlined, label: 'Terms of Service', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsScreen()))),
              _divider(context),
              _actionRow(context, icon: Icons.delete_outline, label: 'Delete my account', labelColor: AppColors.rose, onTap: () => _confirmDeleteAccount(context)),
            ],
          ),
        ),

        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _actionRow(context, icon: Icons.help_outline, label: 'Help & FAQ', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpScreen()))),
              _divider(context),
              _actionRow(context, icon: Icons.mail_outline, label: 'Email us', onTap: () => _contactEmail(context)),
              _divider(context),
              _actionRow(context, icon: Icons.chat_outlined, label: 'WhatsApp us', onTap: () => _contactWhatsapp(context)),
            ],
          ),
        ),

        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Cadence · Version 1.6.0', style: AppText.body(context: context, size: 11, color: AppColors.muted)),
          ),
        ),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout, size: 17, color: AppColors.rose),
            label: Text('Log out', style: AppText.body(context: context, size: 13.5, weight: FontWeight.w600, color: AppColors.rose)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.rose.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reminderRow(BuildContext context, String label, String key) {
    final enabled = widget.reminders[key] ?? false;
    final time = _times[key] ?? [9, 0];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.body(context: context, size: 13.5)),
              const SizedBox(height: 6),
              if (enabled)
                GestureDetector(
                  onTap: () => _pickTime(key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.plum.withOpacity(0.08), borderRadius: BorderRadius.circular(99)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 13, color: isDark ? AppColors.sageLight : AppColors.plum),
                        const SizedBox(width: 5),
                        Text(_formatTime(time), style: AppText.body(context: context, size: 11.5, color: isDark ? AppColors.sageLight : AppColors.plum, weight: FontWeight.w700)),
                        const SizedBox(width: 2),
                        Icon(Icons.edit, size: 11, color: isDark ? AppColors.sageLight : AppColors.plum),
                      ],
                    ),
                  ),
                )
              else
                Text('Off', style: AppText.body(context: context, size: 11.5, color: AppColors.muted)),
            ],
          ),
        ),
        Switch(value: enabled, onChanged: (_) => _handleToggle(key), activeColor: AppColors.sage),
      ],
    );
  }

  Widget _actionRow(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, Color? labelColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: labelColor ?? (isDark ? AppColors.sageLight : AppColors.plum)),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppText.body(context: context, size: 13.5, weight: FontWeight.w600, color: labelColor ?? (isDark ? Colors.white : AppColors.ink)))),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(height: 1, color: isDark ? Colors.white10 : AppColors.sandDeep, indent: 20, endIndent: 20);
  }

  String _month(int m) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[m - 1];
  }

  void _manageMeds(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManageMedsSheet(initialMeds: widget.medicationNames, onSave: widget.onUpdateMeds),
    );
  }
}

class _ManageMedsSheet extends StatefulWidget {
  final List<String> initialMeds;
  final void Function(List<String> names) onSave;

  const _ManageMedsSheet({required this.initialMeds, required this.onSave});

  @override
  State<_ManageMedsSheet> createState() => _ManageMedsSheetState();
}

class _ManageMedsSheetState extends State<_ManageMedsSheet> {
  late List<String> _meds;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _meds = List.from(widget.initialMeds);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Medications', style: AppText.display(context: context, size: 20)),
          const SizedBox(height: 16),
          if (_meds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('No medications added yet.', style: AppText.body(context: context, size: 14, color: AppColors.muted)),
            ),
          ..._meds.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(m, style: AppText.body(context: context, size: 14, weight: FontWeight.w600))),
                IconButton(onPressed: () => setState(() => _meds.remove(m)), icon: const Icon(Icons.remove_circle_outline, color: AppColors.rose, size: 20)),
              ],
            ),
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: isDark ? Colors.white10 : AppColors.sand, borderRadius: BorderRadius.circular(16)),
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Add new med...', border: InputBorder.none, isDense: true),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    setState(() {
                      _meds.add(_controller.text.trim());
                      _controller.clear();
                    });
                  }
                },
                icon: Icon(Icons.add_circle, color: isDark ? AppColors.sageLight : AppColors.plum, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_meds);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.plum, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))),
              child: Text('Save list', style: AppText.body(context: context, size: 14, weight: FontWeight.w600, color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
