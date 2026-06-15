import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  void _triggerExport(BuildContext context, WidgetRef ref, String format) async {
    // Show a quick triggering message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Triggering $format export job...'),
        backgroundColor: Colors.teal,
        duration: const Duration(seconds: 1),
      ),
    );
    try {
      await ref.read(exportsProvider.notifier).requestExport(format);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _retryExport(BuildContext context, WidgetRef ref, ExportJob job) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Retrying export job ${job.exportId.substring(job.exportId.length - 5)}...'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );
    try {
      await ref.read(exportsProvider.notifier).retryExport(job.exportId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _mockDownloadFile(BuildContext context, ExportJob job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.file_download_done_rounded, color: Colors.green),
            const SizedBox(width: 8),
            Text('${job.format} Download Ready'),
          ],
        ),
        content: Text(
          'Your file is generated and hosted at:\n\n'
          '${job.downloadUrl}\n\n'
          'Would you like to simulate saving it locally?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Saved journal_export_${job.exportId}.${job.format.toLowerCase()} to downloads folder!'),
                  backgroundColor: Colors.teal,
                ),
              );
            },
            child: const Text('Simulate Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exportJobs = ref.watch(exportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Text(
              'Export Journal Archive',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Back up your private journals by exporting them into universally accessible file formats. All exports are generated securely.',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.4),
            ),
            const SizedBox(height: 32),

            // Selection Formats Cards
            Text(
              'Choose Export Format',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width < 600 ? 1 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.8,
              children: [
                _buildFormatCard(
                  context,
                  ref,
                  format: 'PDF',
                  description: 'Ideal for reading or printing. Renders complete formatting.',
                  icon: Icons.picture_as_pdf_rounded,
                  iconColor: Colors.redAccent,
                ),
                _buildFormatCard(
                  context,
                  ref,
                  format: 'DOCX',
                  description: 'Editable Microsoft Word document. Best for text modifications.',
                  icon: Icons.description_rounded,
                  iconColor: Colors.blueAccent,
                ),
                _buildFormatCard(
                  context,
                  ref,
                  format: 'JSON',
                  description: 'Structured developer-friendly data. Perfect for custom backups.',
                  icon: Icons.code_rounded,
                  iconColor: Colors.orangeAccent,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Export Job List Queue
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Export Requests',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (exportJobs.isNotEmpty)
                  Text(
                    'Auto-refreshing status...',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (exportJobs.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No exports requested yet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select a format above to generate a new export file.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exportJobs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  // Show newer jobs first
                  final job = exportJobs[exportJobs.length - 1 - index];
                  return _buildJobTile(context, ref, job, theme);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatCard(
    BuildContext context,
    WidgetRef ref, {
    required String format,
    required String description,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => _triggerExport(context, ref, format),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.1),
                    foregroundColor: iconColor,
                    child: Icon(icon),
                  ),
                  Icon(Icons.arrow_circle_right_outlined, color: theme.colorScheme.primary.withOpacity(0.5)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Export as $format',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobTile(BuildContext context, WidgetRef ref, ExportJob job, ThemeData theme) {
    Color statusColor;
    IconData statusIcon;
    bool isProcessing = false;

    switch (job.status) {
      case 'Completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'Processing':
        statusColor = theme.colorScheme.primary;
        statusIcon = Icons.sync_rounded;
        isProcessing = true;
        break;
      case 'Failed':
        statusColor = Colors.redAccent;
        statusIcon = Icons.error_outline_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty_rounded;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.brightness == Brightness.light ? Colors.grey.shade100 : Colors.white.withOpacity(0.05),
          foregroundColor: theme.colorScheme.onSurface,
          child: Text(
            job.format,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        title: Text(
          'Export Job: journal_export_${job.exportId.substring(job.exportId.length - 5)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Requested at: ${_formatDateTime(job.requestedAt)}',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (isProcessing)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                else
                  Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  job.status,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: job.status == 'Completed'
            ? ElevatedButton.icon(
                onPressed: () => _mockDownloadFile(context, job),
                icon: const Icon(Icons.download_rounded, size: 14),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            : job.status == 'Failed'
                ? ElevatedButton.icon(
                    onPressed: () => _retryExport(context, ref, job),
                    icon: const Icon(Icons.replay_rounded, size: 14),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
