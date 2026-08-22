import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class CycleHistoryScreen extends StatefulWidget {
  final List<DateTime> history;
  final Function(DateTime) onAdd;
  final Function(DateTime) onDelete;

  const CycleHistoryScreen({
    super.key,
    required this.history,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  State<CycleHistoryScreen> createState() => _CycleHistoryScreenState();
}

class _CycleHistoryScreenState extends State<CycleHistoryScreen> {
  Future<void> _confirmDelete(BuildContext context, DateTime date) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete entry?', style: AppText.display(context: ctx, size: 18)),
          content: Text('Are you sure you want to remove this period start date?', style: AppText.body(context: ctx, size: 13.5, color: AppColors.muted)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: AppText.body(context: ctx, size: 14, color: AppColors.muted))),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true), 
              child: Text('Delete', style: AppText.body(context: ctx, size: 14, weight: FontWeight.w700, color: AppColors.rose)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      widget.onDelete(date);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedHistory = List<DateTime>.from(widget.history)..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.ink),
        title: Text('Cycle History', style: AppText.display(context: context, size: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Keep track of your past cycles to improve predictions and share with your doctor.',
            style: AppText.body(context: context, size: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          if (sortedHistory.isEmpty)
            SectionCard(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.history_rounded, size: 40, color: AppColors.muted),
                  const SizedBox(height: 12),
                  Text('No history yet', style: AppText.body(context: context, weight: FontWeight.w600)),
                ],
              ),
            )
          else
            ...sortedHistory.map((date) => _buildHistoryTile(context, date)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickDate(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHistoryTile(BuildContext context, DateTime date) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.rose.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today, size: 18, color: AppColors.rose),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(date),
                  style: AppText.body(context: context, weight: FontWeight.w700),
                ),
                Text(
                  'Period started',
                  style: AppText.body(context: context, size: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, date),
            icon: const Icon(Icons.delete_outline, color: AppColors.muted, size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.dark
                ? const ColorScheme.dark(primary: AppColors.sage, onPrimary: Colors.black)
                : const ColorScheme.light(primary: AppColors.plum, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (selected != null) {
      widget.onAdd(selected);
      setState(() {});
    }
  }
}
