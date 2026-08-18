import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/report_item.dart';
import '../services/pdf_service.dart';
import '../widgets/section_card.dart';

class ReportsScreen extends StatelessWidget {
  final List<ReportItem> reports;
  final Map<int, Map<String, double>> dailyLogs;
  final int cycleLength;
  final VoidCallback onGenerate;

  const ReportsScreen({
    super.key,
    required this.reports,
    required this.dailyLogs,
    required this.cycleLength,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text('Reports', style: AppText.display(context: context, size: 24)),
        const SizedBox(height: 4),
        Text('Doctor-ready summaries of your logs', style: AppText.body(context: context, size: 13, color: AppColors.muted)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.add, size: 18),
            label: Text('Generate new report', style: AppText.body(context: context, size: 14, weight: FontWeight.w600, color: AppColors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.plum,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (reports.isEmpty)
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                const Icon(Icons.description_outlined, size: 40, color: AppColors.muted),
                const SizedBox(height: 14),
                Text('No reports yet', style: AppText.display(context: context, size: 16)),
                const SizedBox(height: 6),
                Text(
                  'Generate your first doctor-ready summary once you\'ve logged a few days.',
                  textAlign: TextAlign.center,
                  style: AppText.body(context: context, size: 13, color: AppColors.muted),
                ),
              ],
            ),
          )
        else
          ...reports.map((r) => _ReportTile(report: r, dailyLogs: dailyLogs, cycleLength: cycleLength)),
      ],
    );
  }
}

class _ReportTile extends StatefulWidget {
  final ReportItem report;
  final Map<int, Map<String, double>> dailyLogs;
  final int cycleLength;

  const _ReportTile({required this.report, required this.dailyLogs, required this.cycleLength});

  @override
  State<_ReportTile> createState() => _ReportTileState();
}

class _ReportTileState extends State<_ReportTile> {
  bool _working = false;

  Future<void> _download() async {
    setState(() => _working = true);
    try {
      final service = PdfService();
      final file = await service.generateReport(
        title: widget.report.title,
        dateLabel: widget.report.date,
        dailyLogs: widget.dailyLogs,
        cycleLength: widget.cycleLength,
      );
      await service.shareReport(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate the PDF. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.plum.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.description_outlined, size: 18, color: AppColors.plum),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.report.title, style: AppText.body(context: context, size: 13.5, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(widget.report.date, style: AppText.mono(context: context, size: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          _working
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.plum))
              : IconButton(onPressed: _download, icon: const Icon(Icons.download_outlined, size: 20, color: AppColors.plum), splashRadius: 20),
        ],
      ),
    );
  }
}