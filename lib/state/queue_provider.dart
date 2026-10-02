import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

enum QueueItemStatus {
  queued,
  processing,
  paused,
  completed,
  failed,
  cancelled,
}

class QueueItem {
  final String id;
  final String title;
  final String operationName;
  final double progress; // 0.0 to 1.0
  final QueueItemStatus status;
  final String? outputPath;
  final String? errorMessage;
  final String? detailedLog;
  final DateTime createdAt;
  final DateTime? completedAt;

  const QueueItem({
    required this.id,
    required this.title,
    required this.operationName,
    this.progress = 0.0,
    this.status = QueueItemStatus.queued,
    this.outputPath,
    this.errorMessage,
    this.detailedLog,
    required this.createdAt,
    this.completedAt,
  });

  QueueItem copyWith({
    String? title,
    String? operationName,
    double? progress,
    QueueItemStatus? status,
    String? outputPath,
    String? errorMessage,
    String? detailedLog,
    DateTime? completedAt,
  }) {
    return QueueItem(
      id: id,
      title: title ?? this.title,
      operationName: operationName ?? this.operationName,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
      detailedLog: detailedLog ?? this.detailedLog,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class QueueState {
  final List<QueueItem> items;
  final String? lastNotification;
  final bool isErrorNotification;

  const QueueState({
    this.items = const [],
    this.lastNotification,
    this.isErrorNotification = false,
  });

  int get activeCount => items.where((i) => i.status == QueueItemStatus.processing || i.status == QueueItemStatus.queued).length;
  int get completedCount => items.where((i) => i.status == QueueItemStatus.completed).length;

  QueueState copyWith({
    List<QueueItem>? items,
    String? lastNotification,
    bool? isErrorNotification,
  }) {
    return QueueState(
      items: items ?? this.items,
      lastNotification: lastNotification,
      isErrorNotification: isErrorNotification ?? this.isErrorNotification,
    );
  }
}

class QueueNotifier extends Notifier<QueueState> {
  final _uuid = const Uuid();

  @override
  QueueState build() {
    return const QueueState();
  }

  String enqueueTask({required String title, required String operationName}) {
    final id = _uuid.v4();
    final item = QueueItem(
      id: id,
      title: title,
      operationName: operationName,
      progress: 0.0,
      status: QueueItemStatus.queued,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(items: [item, ...state.items]);
    return id;
  }

  void startProcessing(String id) {
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.id == id) {
          return i.copyWith(status: QueueItemStatus.processing, progress: 0.05);
        }
        return i;
      }).toList(),
    );
  }

  void updateProgress(String id, double progress) {
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.id == id) {
          return i.copyWith(
            progress: progress.clamp(0.0, 1.0),
            status: progress >= 1.0 ? QueueItemStatus.completed : QueueItemStatus.processing,
          );
        }
        return i;
      }).toList(),
    );
  }

  void completeTask(String id, {required String outputPath, String? successMessage}) {
    state = state.copyWith(
      lastNotification: successMessage ?? 'Operation completed successfully.',
      isErrorNotification: false,
      items: state.items.map((i) {
        if (i.id == id) {
          return i.copyWith(
            progress: 1.0,
            status: QueueItemStatus.completed,
            outputPath: outputPath,
            completedAt: DateTime.now(),
          );
        }
        return i;
      }).toList(),
    );
  }

  void failTask(String id, {required String error, String? detailedLog}) {
    state = state.copyWith(
      lastNotification: 'Failed: $error',
      isErrorNotification: true,
      items: state.items.map((i) {
        if (i.id == id) {
          return i.copyWith(
            status: QueueItemStatus.failed,
            errorMessage: error,
            detailedLog: detailedLog,
            completedAt: DateTime.now(),
          );
        }
        return i;
      }).toList(),
    );
  }

  void cancelTask(String id) {
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.id == id && (i.status == QueueItemStatus.queued || i.status == QueueItemStatus.processing)) {
          return i.copyWith(status: QueueItemStatus.cancelled, completedAt: DateTime.now());
        }
        return i;
      }).toList(),
    );
  }

  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((i) => i.id != id).toList(),
    );
  }

  void clearCompleted() {
    state = state.copyWith(
      items: state.items.where((i) => i.status != QueueItemStatus.completed && i.status != QueueItemStatus.cancelled).toList(),
    );
  }

  void clearNotification() {
    state = state.copyWith(lastNotification: null);
  }
}

final queueProvider = NotifierProvider<QueueNotifier, QueueState>(() {
  return QueueNotifier();
});
