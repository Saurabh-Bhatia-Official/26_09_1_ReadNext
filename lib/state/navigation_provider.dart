import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PageLayoutMode {
  singlePage,
  continuousVertical,
  twoPageSpread,
}

class NavigationState {
  final int currentPage; // 1-indexed
  final int totalPages;
  final PageLayoutMode layoutMode;
  final int rotation; // 0, 90, 180, 270

  const NavigationState({
    required this.currentPage,
    required this.totalPages,
    this.layoutMode = PageLayoutMode.singlePage,
    this.rotation = 0,
  });

  NavigationState copyWith({
    int? currentPage,
    int? totalPages,
    PageLayoutMode? layoutMode,
    int? rotation,
  }) {
    return NavigationState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      layoutMode: layoutMode ?? this.layoutMode,
      rotation: rotation ?? this.rotation,
    );
  }
}

class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() {
    return const NavigationState(
      currentPage: 1,
      totalPages: 1,
    );
  }

  void setTotalPages(int total) {
    state = state.copyWith(
      totalPages: total > 0 ? total : 1,
      currentPage: state.currentPage.clamp(1, total > 0 ? total : 1),
    );
  }

  void setPage(int page) {
    if (page >= 1 && page <= state.totalPages) {
      state = state.copyWith(currentPage: page);
    }
  }

  void nextPage() {
    if (state.currentPage < state.totalPages) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  void prevPage() {
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void firstPage() {
    state = state.copyWith(currentPage: 1);
  }

  void lastPage() {
    state = state.copyWith(currentPage: state.totalPages);
  }

  void setLayoutMode(PageLayoutMode mode) {
    state = state.copyWith(layoutMode: mode);
  }

  void rotateClockwise() {
    state = state.copyWith(rotation: (state.rotation + 90) % 360);
  }

  void rotateCounterClockwise() {
    state = state.copyWith(rotation: (state.rotation - 90 + 360) % 360);
  }
}

final navigationProvider = NotifierProvider<NavigationNotifier, NavigationState>(NavigationNotifier.new);
