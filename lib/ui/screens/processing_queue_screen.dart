import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/document_provider.dart';
import '../../../state/queue_provider.dart';

class ProcessingQueueScreen extends ConsumerWidget {
  const ProcessingQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Queue'),
        actions: [
          if (queue.items.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Completed'),
              onPressed: () => ref.read(queueProvider.notifier).clearCompleted(),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: queue.items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checklist, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('Queue is Empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'Active, pending, and completed operations will show their live progress here.',
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Active Tasks (${queue.activeCount})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        Text('Completed: ${queue.completedCount}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: queue.items.length,
                        itemBuilder: (context, index) {
                          final item = queue.items[index];
                          final isCompleted = item.status == QueueItemStatus.completed;
                          final isFailed = item.status == QueueItemStatus.failed;
                          final isCancelled = item.status == QueueItemStatus.cancelled;
                          final isProcessing = item.status == QueueItemStatus.processing;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Leading index badge e.g. "01", "02"
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? Colors.green.withValues(alpha: 0.15)
                                              : isFailed
                                                  ? Colors.red.withValues(alpha: 0.15)
                                                  : theme.colorScheme.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${index + 1 < 10 ? "0" : ""}${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isCompleted
                                                ? Colors.green
                                                : isFailed
                                                    ? Colors.red
                                                    : theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            Text(
                                              '${item.operationName} • Started: ${item.createdAt.hour.toString().padLeft(2, "0")}:${item.createdAt.minute.toString().padLeft(2, "0")}',
                                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${(item.progress * 100).toInt()}%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isCompleted
                                              ? Colors.green
                                              : isFailed
                                                  ? Colors.red
                                                  : theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: item.progress > 0 ? item.progress : null,
                                      color: isCompleted ? Colors.green : isFailed ? Colors.red : null,
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      if (item.outputPath != null)
                                        Expanded(
                                          child: Text(
                                            'Output: ${item.outputPath}',
                                            style: const TextStyle(fontSize: 11, color: Colors.green),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      else if (item.errorMessage != null)
                                        Expanded(
                                          child: Text(
                                            'Error: ${item.errorMessage}',
                                            style: const TextStyle(fontSize: 11, color: Colors.red),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      else
                                        Text(
                                          item.status.name.toUpperCase(),
                                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                        ),
                                      const Spacer(),
                                      if (item.outputPath != null && File(item.outputPath!).existsSync()) ...[
                                        TextButton.icon(
                                          icon: const Icon(Icons.open_in_new, size: 16),
                                          label: const Text('Open File'),
                                          onPressed: () => ref.read(documentProvider.notifier).openFile(item.outputPath!),
                                        ),
                                      ],
                                      if (isProcessing)
                                        IconButton(
                                          icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                                          tooltip: 'Cancel Task',
                                          onPressed: () => ref.read(queueProvider.notifier).cancelTask(item.id),
                                        ),
                                      if (isCompleted || isFailed || isCancelled)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20),
                                          tooltip: 'Remove',
                                          onPressed: () => ref.read(queueProvider.notifier).removeItem(item.id),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
