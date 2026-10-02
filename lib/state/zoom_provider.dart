import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';

enum FitMode {
  fitWidth,
  fitPage,
  fitContent,
  actualSize,
  custom,
}

class ZoomState {
  final double scale;
  final FitMode fitMode;
  final bool trimWhiteMargins;
  final double upscaleFactor;

  const ZoomState({
    this.scale = AppConstants.defaultZoom,
    this.fitMode = FitMode.fitWidth,
    this.trimWhiteMargins = false,
    this.upscaleFactor = 1.5,
  });

  ZoomState copyWith({
    double? scale,
    FitMode? fitMode,
    bool? trimWhiteMargins,
    double? upscaleFactor,
  }) {
    return ZoomState(
      scale: scale ?? this.scale,
      fitMode: fitMode ?? this.fitMode,
      trimWhiteMargins: trimWhiteMargins ?? this.trimWhiteMargins,
      upscaleFactor: upscaleFactor ?? this.upscaleFactor,
    );
  }
}

class ZoomNotifier extends Notifier<ZoomState> {
  @override
  ZoomState build() {
    return const ZoomState();
  }

  void zoomIn() {
    final next = (state.scale + AppConstants.zoomStep).clamp(
      AppConstants.minZoom,
      AppConstants.maxZoom,
    );
    // Never force margin trimming on zoom: page must not be cut!
    state = state.copyWith(
      scale: next,
      fitMode: FitMode.custom,
    );
  }

  void zoomOut() {
    final next = (state.scale - AppConstants.zoomStep).clamp(
      AppConstants.minZoom,
      AppConstants.maxZoom,
    );
    state = state.copyWith(
      scale: next,
      fitMode: FitMode.custom,
    );
  }

  void setZoom(double scale) {
    final clamped = scale.clamp(AppConstants.minZoom, AppConstants.maxZoom);
    state = state.copyWith(
      scale: clamped,
      fitMode: FitMode.custom,
    );
  }

  void setUpscaleFactor(double factor) {
    state = state.copyWith(upscaleFactor: factor.clamp(1.0, 3.0));
  }

  void cycleUpscale() {
    final current = state.upscaleFactor;
    if (current <= 1.0) {
      state = state.copyWith(upscaleFactor: 1.5);
    } else if (current <= 1.5) {
      state = state.copyWith(upscaleFactor: 2.0);
    } else if (current <= 2.0) {
      state = state.copyWith(upscaleFactor: 3.0);
    } else {
      state = state.copyWith(upscaleFactor: 1.0);
    }
  }

  void toggleTrimWhiteMargins() {
    state = state.copyWith(trimWhiteMargins: !state.trimWhiteMargins);
  }

  void setTrimWhiteMargins(bool trim) {
    state = state.copyWith(trimWhiteMargins: trim);
  }

  void setFitMode(FitMode mode) {
    switch (mode) {
      case FitMode.actualSize:
        state = state.copyWith(scale: 1.0, fitMode: mode, trimWhiteMargins: false);
        break;
      case FitMode.fitWidth:
        state = state.copyWith(scale: 1.25, fitMode: mode, trimWhiteMargins: false);
        break;
      case FitMode.fitPage:
        state = state.copyWith(scale: 0.9, fitMode: mode, trimWhiteMargins: false);
        break;
      case FitMode.fitContent:
        // Fit content zooms directly into text content without cutting margins
        state = state.copyWith(scale: 1.4, fitMode: mode, trimWhiteMargins: false);
        break;
      case FitMode.custom:
        state = state.copyWith(fitMode: mode);
        break;
    }
  }

  void resetZoom() {
    state = state.copyWith(scale: 1.0, fitMode: FitMode.actualSize, trimWhiteMargins: false);
  }
}

final zoomProvider = NotifierProvider<ZoomNotifier, ZoomState>(ZoomNotifier.new);
