# ReadNext — Advanced Professional PDF Viewer

> A production-ready, feature-rich, high-performance cross-platform PDF document reading and annotation application built with **Flutter**, **Riverpod 3**, native **PDFium**, and **SQLite**.

Conforms to the 46 sections of the Product Requirements Document (`prd.md`).

---

## Key Highlights & Features

### 1. Core PDF Viewing & Navigation
- **High-Performance Native PDF Rendering**: Backed by PDFium via `pdfx` for sub-pixel vector rendering and instant page rendering.
- **Multiple Page Layouts**:
  - Single Page mode
  - Continuous Vertical scrolling
  - Two-Page Book Spread mode
- **Dynamic Zoom Controls**:
  - Smooth zoom from 50% to 500% with preset increments (50%, 75%, 100%, 125%, 150%, 200%, 300%)
  - Fit Width, Fit Page, and Actual Size (100%) modes
  - Mouse-wheel zoom and pinch-to-zoom support
- **Page Rotation**: Clockwise rotation in 90° steps (0°, 90°, 180°, 270°).
- **Page Navigation**: First page, Previous page, Next page, Last page, and interactive **Go-to-Page** dialog.

### 2. Multi-Tab Navigation Sidebar
- **Thumbnails**: Real-time high-resolution page preview tiles with current-page indicator badges and click-to-navigate.
- **Document Outline / TOC**: Expandable table of contents tree with page jump targets.
- **User Bookmarks**: Add, name, list, and delete custom bookmarks per document.
- **Annotations Index**: Complete list of all document annotations, filterable by type, with jump-to-annotation.
- **Search Panel**: Live query input with match count, previous/next match jump, case-sensitive toggle, and whole-word matching.

### 3. Full Annotation Suite with Undo / Redo
- **Markups**:
  - Text Highlights (Yellow, Green, Blue, Pink, Orange)
  - Underline & Strikethrough
  - Text Boxes with custom font colors and positioning
  - Freehand Pen / Ink with customizable stroke width
  - Sticky Notes / Comments
  - Geometric Shapes: Rectangles, Circles, Arrows, Lines
  - Status Stamps: APPROVED, DRAFT, CONFIDENTIAL, REJECTED
  - Digital Signature Pad: Interactive signature drawing canvas with color options and stamping
- **Non-Destructive History**: 30-level Undo and Redo stack (`Ctrl+Z`, `Ctrl+Y`).
- **Export & Print**: Embedded vector and flattened PDF export via `PdfExportService` and native print dialog integration via `Printing`.

### 4. Local Persistence (SQLite + FFI)
- Transparent local database across Windows desktop and mobile devices:
  - `recent_documents`: Tracks reading progress percentage, last opened timestamp, page count, and favorites.
  - `bookmarks`: Custom user bookmarks per document.
  - `annotations`: Persisted annotation geometry, types, and author metadata.
  - `search_history`: Recent query suggestions.
  - `preferences`: User theme and viewer settings.

### 5. Desktop-Grade UX & Theming
- **Adaptive Material 3 Design**:
  - **Light Theme**: Clean, high-contrast professional palette.
  - **Dark Theme**: Eye-strain reducing deep charcoal and slate palette.
  - **Sepia / Eye-Care Theme**: Warm parchment tones for comfortable prolonged reading.
- **Drag & Drop**: Direct drag-and-drop of PDF files from the desktop file explorer into the viewer.
- **Presentation Mode (`F5`)**: Distraction-free presentation view hiding toolbars and sidebars.
- **Document Properties Modal**: Inspects Title, Author, Subject, Keywords, Creator, Creation Date, Page Count, File Size, and PDF Version.
- **Bundled Sample Document**: Self-contained `assets/sample.pdf` enabling zero-friction initial evaluation.

---

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl + O` | Open PDF File dialog |
| `Ctrl + S` | Save / Export annotated document |
| `Ctrl + Shift + S` | Save As dialog |
| `Ctrl + P` | Print document |
| `Ctrl + F` | Search within document |
| `Ctrl + Z` | Undo last annotation |
| `Ctrl + Y` / `Ctrl + Shift + Z` | Redo annotation |
| `Ctrl + +` / `Ctrl + =` | Zoom In |
| `Ctrl + -` | Zoom Out |
| `Ctrl + 0` | Fit Page |
| `Ctrl + R` | Rotate page clockwise (90°) |
| `Page Up` / `Arrow Left` | Previous Page |
| `Page Down` / `Arrow Right` | Next Page |
| `F5` | Toggle Presentation Mode |
| `F11` | Toggle Fullscreen Mode |

---

## Architectural Structure

```text
lib/
├── main.dart                          # App entry point, ProviderScope, SQLite FFI setup
├── app.dart                           # Root MaterialApp, dynamic theme switcher
│
├── core/
│   ├── constants/app_constants.dart   # Zoom limits, annotation colors, presets
│   ├── shortcuts/app_shortcuts.dart   # Global shortcut intents and key bindings
│   ├── theme/app_theme.dart           # Light, Dark, Sepia Material 3 themes
│   └── utils/formatters.dart          # File size and date/time formatters
│
├── data/
│   ├── database/app_database.dart     # SQLite database service with FFI desktop support
│   └── models/
│       ├── annotation_model.dart      # Annotation data models & JSON serialization
│       ├── bookmark_model.dart        # User bookmarks and outline hierarchy
│       ├── form_field_model.dart      # Interactive PDF form field definitions
│       ├── pdf_document_meta.dart     # Document metadata model
│       └── recent_document.dart       # Recent file records with progress tracking
│
├── services/
│   ├── file_service.dart              # File picking, drag-and-drop, and asset loading
│   ├── print_service.dart             # Native printing integration
│   └── pdf/
│       ├── i_pdf_engine.dart          # PDF engine interface (abstraction layer)
│       ├── pdfx_engine_impl.dart      # Native PDFium-backed engine implementation
│       └── pdf_export_service.dart    # Export annotated PDF vector/flattened streams
│
├── state/
│   ├── annotation_provider.dart       # Riverpod 3 Notifier for annotations & undo/redo
│   ├── bookmark_provider.dart         # Bookmarks & TOC outline provider
│   ├── document_provider.dart         # Document loading & lifecycle provider
│   ├── form_provider.dart             # Interactive form inputs provider
│   ├── navigation_provider.dart       # Page index, layout mode, rotation provider
│   ├── search_provider.dart           # Document query search & match navigation provider
│   ├── settings_provider.dart         # Appearance themes, sidebar, recents provider
│   └── zoom_provider.dart             # Zoom scale & fit mode provider
│
└── ui/
    ├── screens/
    │   ├── viewer_screen.dart         # Main application shell with keyboard shortcuts
    │   └── welcome_screen.dart        # Empty state with drag-and-drop & recent files
    └── widgets/
        ├── annotation_ribbon/         # Annotation tools, shapes, color chips, undo/redo
        ├── canvas/                    # Multi-layer PDF viewport (raster + annotations + drawing)
        ├── dialogs/                   # Document Properties, Signature Pad, Go To Page, Password
        ├── sidebar/                   # Collapsible 5-tab navigation sidebar
        └── toolbar/                   # Top toolbar with page, zoom, layout, search controls
```

---

## Running the Application

### Prerequisites
- Flutter SDK `>= 3.44.8`
- Dart SDK `>= 3.12.2`
- Desktop development tools (Visual Studio 2022/2026 with C++ on Windows)

### Commands

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run on Windows Desktop**:
   ```bash
   flutter run -d windows
   ```

3. **Run on Web (Chrome)**:
   ```bash
   flutter run -d chrome
   ```

4. **Execute Automated Tests**:
   ```bash
   flutter test
   ```

5. **Static Code Analysis**:
   ```bash
   flutter analyze
   ```
