import 'package:flutter/material.dart';

// Intents
class OpenFileIntent extends Intent {
  const OpenFileIntent();
}

class SaveFileIntent extends Intent {
  const SaveFileIntent();
}

class PrintFileIntent extends Intent {
  const PrintFileIntent();
}

class SearchFileIntent extends Intent {
  const SearchFileIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class ZoomInIntent extends Intent {
  const ZoomInIntent();
}

class ZoomOutIntent extends Intent {
  const ZoomOutIntent();
}

class ZoomResetIntent extends Intent {
  const ZoomResetIntent();
}

class FitWidthIntent extends Intent {
  const FitWidthIntent();
}

class FitContentIntent extends Intent {
  const FitContentIntent();
}

class TrimMarginsIntent extends Intent {
  const TrimMarginsIntent();
}

class NextPageIntent extends Intent {
  const NextPageIntent();
}

class PrevPageIntent extends Intent {
  const PrevPageIntent();
}

class RotateClockwiseIntent extends Intent {
  const RotateClockwiseIntent();
}

class FullscreenToggleIntent extends Intent {
  const FullscreenToggleIntent();
}

class PresentationToggleIntent extends Intent {
  const PresentationToggleIntent();
}

class UpscaleToggleIntent extends Intent {
  const UpscaleToggleIntent();
}

class CloseFileIntent extends Intent {
  const CloseFileIntent();
}

class ToggleLeftPanelIntent extends Intent {
  const ToggleLeftPanelIntent();
}
