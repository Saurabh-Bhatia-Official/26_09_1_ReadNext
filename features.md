# ReadNext — Feature Catalog & Architecture Matrix

> **ReadNext** is a production-ready, enterprise-grade PDF reader and utility suite engineered with **Flutter**, **Riverpod 3**, native **PDFium**, and **SQLite (FFI)**. It combines high-performance reading capabilities with 20 standalone utility tools, a 100% client-side privacy architecture, and executive corporate aesthetics.

---

## 🌟 Executive Overview & Highlights

- **100% Offline & Private**: Zero cloud uploads. All document rendering, annotations, conversions, OCR, encryption, and compression occur strictly on the user's local hardware.
- **Enterprise Corporate Theme**: Executive Navy (`#090E17`, `#0F172A`, `#131F37`, `#1E2E4A`, `#2563EB`) paired with clean white splash screen and adaptive light, dark, and eye-care sepia modes.
- **Sub-Pixel PDFium Engine**: Vector-accurate rendering with continuous vertical scrolling, single page, and two-page book spread views.
- **20 Integrated PDF Tools**: Centralized in the Tools Hub for organizing, optimizing, converting, editing, securing, and batch processing documents.
- **Desktop-Optimized Experience**: Drag-and-drop intake, collapsible navigation rail (`Ctrl+B`), 30-level non-destructive Undo/Redo stack, and comprehensive keyboard shortcuts.

---

## 📋 Comprehensive Feature Catalog

### 1. Splash Screen & Brand Identity
- **White Background Corporate Splash**: Clean, professional initial loading view with the official ReadNext software logo and ambient blue highlight.
- **Tagline & Enterprise Badge**: Features *"Read. Manage. Move Forward."* alongside the *"Enterprise Edition • 100% Client-Side Privacy"* trust badge.
- **Animated Progress & Dynamic Status**: Smooth curved linear progress bar reflecting real-time engine initialization steps:
  - *Initializing secure PDF engine...*
  - *Loading client-side toolchain & workspace...*
  - *Applying corporate security policies...*
  - *Ready*
- **Instant Skip Access**: Dedicated **"Skip to App"** button and tap-anywhere shortcut for instant access to the workspace.

---

### 2. Theming & Visual Aesthetics
ReadNext includes an adaptive theming engine with real-time switching:

| Theme Mode | Palette & Visual Tone | Intended Use Case |
|---|---|---|
| **Corporate Executive (Default)** | Midnight Slate (`#090E17`), Executive Navy (`#0F172A`), Cobalt Accents (`#2563EB`) | Default enterprise workspace, executive dashboards |
| **Dark Theme** | Slate Charcoal (`#0F172A`), Elevated Slate (`#1E293B`), Sky Blue (`#60A5FA`) | Low-light environments, reduced eye fatigue |
| **Light Theme** | Clean Snow (`#F8FAFC`), Slate Canvas (`#E2E8F0`), Deep Royal (`#0D47A1`) | High-contrast daytime reading and office environments |
| **Sepia / Eye-Care** | Parchment Warm (`#F5EBE1`), Sand Canvas (`#EADBCE`), Walnut (`#8B5E3C`) | Prolonged document study, eBook reading, reduced blue light |

- **Quick-Access Toolbar Selector**: Instant theme switching from the main viewer toolbar popup or the Settings hub.

---

### 3. Application Navigation & Workspace Shell
- **Collapsible Left Panel (Navigation Rail)**:
  - Global toggle button with indicator badge.
  - Shortcut: `Ctrl + B` for instant show/hide.
  - Responsive layout builder ensuring zero overflow across small laptop and large desktop screens.
- **6 Primary Hubs**:
  1. **Home Dashboard**: Quick action buttons, drag-and-drop intake box, recent files carousel with progress bars, favorites list, and workspace statistics.
  2. **Tools Hub**: Responsive grid presenting all 20 professional PDF tools with category filters.
  3. **Viewer**: The document reading canvas, annotation ribbon, multi-tab navigation sidebar, and toolbar.
  4. **Processing Queue**: Asynchronous background task manager with live progress bars, status indicators, and notification toasts.
  5. **Recent Files**: Full-page document history with file size, page count, last opened date, favorite star toggles, and deletion.
  6. **Settings**: Appearance mode radio selectors, privacy & security architecture transparency, and licensing status management.

---

### 4. Core PDF Viewing Engine
- **PDFium Rendering Core**: Native C++ vector rasterization for rapid multi-threaded page rendering.
- **Page Layout Modes**:
  - **Single Page View**: Isolates one page at a time with smooth page flipping.
  - **Continuous Vertical Scroll**: Fluid continuous page stream with inertia scrolling.
  - **Two-Page Book Spread**: Side-by-side presentation mimicking open print publications.
- **Precision Zoom Controls**:
  - Zoom range from **50% to 500%**.
  - Preset increments: 50%, 75%, 100%, 125%, 150%, 175%, 200%, 250%, 300%, 400%, 500%.
  - **Fit to Width** mode.
  - **Fit to Page** mode (`Ctrl + 0`).
  - **Actual Size (100%)** mode.
  - Mouse-wheel zoom (`Ctrl + Wheel`) and trackpad pinch-to-zoom.
- **Page Rotation**: 90° clockwise rotation steps (0°, 90°, 180°, 270°) with immediate canvas orientation update (`Ctrl + R`).
- **Page Navigation**:
  - First Page (`Home` / Toolbar).
  - Previous Page (`Page Up` / `Left Arrow`).
  - Next Page (`Page Down` / `Right Arrow`).
  - Last Page (`End` / Toolbar).
  - Interactive **Go-to-Page** dialog with direct numerical input and validation.
- **Presentation Mode (`F5`)**: Distraction-free full-screen presentation hiding all toolbars and navigation chrome.
- **Fullscreen Mode (`F11`)**: Expands the reading window to borderless display.

---

### 5. Multi-Tab Navigation Sidebar
The collapsible left sidebar in the Viewer provides 5 specialized exploration panels:

1. **Page Thumbnails**: High-resolution thumbnail previews of every document page with current-page indicator badges, page numbering, and instant jump-on-click.
2. **Document Outline / TOC**: Interactive hierarchical tree representing the internal PDF table of contents with collapsible chapter branches.
3. **User Bookmarks**: User-created custom bookmarks stored locally in SQLite with custom labels and page targets.
4. **Annotations Index**: Live inventory of all markup elements across the document, filterable by type (Highlights, Notes, Shapes, Signatures), with jump-to-element.
5. **Document Search**:
   - In-document text query scanning.
   - Total match count indicator.
   - Previous and Next match navigation buttons.
   - Match highlighting overlay.
   - Case-sensitive and whole-word match toggles.

---

### 6. Annotation, Markup & Signing Suite
A full non-destructive annotation system overlaid onto the PDF canvas:

- **Text Highlights**: Multi-color translucent highlighter (Yellow, Green, Blue, Pink, Orange, Purple).
- **Text Markups**: Underline and Strikethrough for editorial review.
- **Custom Text Boxes**: Free-floating text containers with adjustable font size, text color, and positioning.
- **Freehand Pen / Ink**: Smooth path drawing with custom stroke thickness and color palette.
- **Sticky Notes / Comments**: Collapsible comment markers with expandable note text popups.
- **Geometric Shapes**:
  - Rectangles / Bounding Boxes
  - Circles / Ovals
  - Arrows (directional annotations)
  - Straight Lines
- **Status Stamps**: Built-in executive business stamps:
  - `APPROVED`
  - `DRAFT`
  - `CONFIDENTIAL`
  - `REJECTED`
  - `FINAL`
  - `REVIEWED`
- **Interactive Signature Pad**:
  - Dedicated vector signature drawing canvas.
  - Ink color selection (Black, Blue, Red).
  - Clear, preview, and stamp signature directly onto any page at desired coordinates.
- **Undo / Redo Engine**: 30-level non-destructive history stack (`Ctrl+Z`, `Ctrl+Y`).
- **Export & Print**:
  - Export annotated PDF as vector stream.
  - Flatten annotations permanently into the PDF.
  - Native system printing via the print service (`Ctrl+P`).

---

### 7. The 20 Built-In PDF Tools Catalog

ReadNext features a dedicated **Tools Hub** comprising 20 standalone utility tools divided into 6 operational categories:

#### Category A: Organize
1. **Merge PDF**: Select multiple PDF files, drag to reorder their sequence, and merge them into a single consolidated PDF document.
2. **Split PDF**: Divide a document into distinct files using custom page ranges (e.g., `1-3, 5, 7-10`), equal page chunks, or individual pages.
3. **Page Manager**: Interactive visual grid of all document pages allowing drag-and-drop reordering, single-page deletion, page duplication, and page reversal.
4. **Rotate Pages**: Rotate all pages or specific page subsets permanently by 90°, 180°, or 270°.
5. **Extract Pages**: Extract chosen pages into a standalone, clean PDF file.

#### Category B: Optimize
6. **Compress PDF**: Multi-level file size reduction engine:
   - *Low Compression* (Preserves high image quality).
   - *Medium Compression* (Balanced for email sharing).
   - *High Compression* (Maximum size reduction for web archiving).
   - *Custom Compression* (Configurable DPI and image quality percentage).
7. **Repair PDF**: Scans and rebuilds damaged cross-reference (`xref`) tables and broken stream dictionaries to restore unreadable documents.

#### Category C: Convert
8. **PDF to Images**: Convert PDF pages into high-resolution bitmap graphics (`PNG`, `JPG`, `WEBP`) with adjustable rendering DPI.
9. **Images to PDF**: Import collections of photos, scans, and raster graphics (`PNG`, `JPG`, `BMP`, `WEBP`) and compile them into a unified PDF with customizable margins and page orientation.
10. **PDF to Word**: Extract paragraphs, headings, and formatting flow into editable Microsoft Word (`.docx`) files.
11. **PDF to Excel**: Identify table structures and cell data to export into structured Microsoft Excel (`.xlsx`) spreadsheets.
12. **PDF to PowerPoint**: Convert visual pages and slides into editable Microsoft PowerPoint (`.pptx`) presentations.

#### Category D: Edit & Security
13. **Annotate & Draw**: Instant shortcut into the in-canvas annotation suite with full toolbar.
14. **Watermark PDF**: Add customized watermarks across document pages:
    - Text watermarks (custom string, font size, angle, opacity, color).
    - Image watermarks (corporate logos, seal stamps).
15. **Password & Security**:
    - Encrypt document with User (Open) password.
    - Encrypt document with Owner (Permissions) password.
    - Set granular permission flags: prevent printing, prevent text/graphics copying, prevent modifications.
    - Decrypt and unlock password-protected documents with authorization.
16. **Document Properties (Metadata)**: Inspect and edit embedded document metadata fields: Title, Author, Subject, Keywords, Creator, Producer, Creation Date, and PDF Version specification.
17. **Compare PDFs**: Side-by-side split screen visual comparison highlighting textual and layout variations between two PDF document revisions.

#### Category E: OCR (Optical Character Recognition)
18. **OCR Text Extraction**: On-device machine-learning optical character recognition extracting raw selectable text from scanned paper PDFs and images. Supports **English**, **Hindi**, and **Marathi**.
19. **Searchable PDF Generator**: Injects an invisible, selectable text layer directly above scanned raster pages, enabling full `Ctrl+F` document indexing and text selection without altering the underlying scan visual.

#### Category F: Batch Operations
20. **Batch Processing Queue**: Queue dozens of documents simultaneously for automated batch operations:
    - Batch Compression
    - Batch Format Conversion
    - Batch Watermarking
    - Batch OCR Text Extraction
    - Asynchronous worker queue with live progress percentage indicators and cancellation support.

---

### 8. Persistence & Data Architecture (SQLite + FFI)

ReadNext uses a local SQLite relational database powered by `sqflite_common_ffi` on Windows/Desktop:

| Table Name | Purpose | Fields Tracked |
|---|---|---|
| `recent_documents` | Document history & resume | File path, file name, total pages, last read page, progress percentage, last opened timestamp, favorite status |
| `bookmarks` | User-defined page markers | Document path, page index, bookmark title, creation timestamp |
| `annotations` | Persisted annotations | Document path, page index, annotation type, JSON-serialized coordinates, color, stroke, content |
| `search_history` | Query suggestions | Search query string, search timestamp |
| `preferences` | App settings & layout state | Active theme mode, left panel visibility state, sidebar active tab, default zoom level |

---

### 9. Keyboard Shortcuts Reference Table

| Shortcut | Context | Function |
|---|---|---|
| `Ctrl + O` | Global | Open PDF File dialog |
| `Ctrl + B` | Global | Toggle Left Panel (Navigation Rail) |
| `Ctrl + S` | Viewer | Save / Export annotated document |
| `Ctrl + Shift + S` | Viewer | Save As dialog |
| `Ctrl + P` | Viewer | Print document |
| `Ctrl + F` | Viewer | Open Document Search panel |
| `Ctrl + Z` | Viewer | Undo last annotation markup |
| `Ctrl + Y` / `Ctrl + Shift + Z` | Viewer | Redo annotation markup |
| `Ctrl + +` / `Ctrl + =` | Viewer | Zoom In (+25%) |
| `Ctrl + -` | Viewer | Zoom Out (-25%) |
| `Ctrl + 0` | Viewer | Fit Page to view |
| `Ctrl + R` | Viewer | Rotate page 90° clockwise |
| `Page Up` / `Arrow Left` | Viewer | Previous Page |
| `Page Down` / `Arrow Right` | Viewer | Next Page |
| `Home` | Viewer | Jump to First Page |
| `End` | Viewer | Jump to Last Page |
| `F5` | Viewer | Toggle Presentation Mode |
| `F11` | Global | Toggle Fullscreen Mode |

---

### 10. Licensing & Feature Tiers

ReadNext incorporates a tiered freemium architecture:

| Feature / Capability | Free Tier | Pro Tier (₹199/mo · ₹1,499/yr) | Enterprise Tier (₹3,999 Lifetime) |
|---|:---:|:---:|:---:|
| Core PDF Viewing & Zoom | ✅ | ✅ | ✅ |
| Navigation Sidebar & Thumbnails | ✅ | ✅ | ✅ |
| Text Search & Highlighting | ✅ | ✅ | ✅ |
| Basic Annotation (Pen, Notes) | ✅ | ✅ | ✅ |
| Digital Signature Pad | ✅ | ✅ | ✅ |
| Export Annotated PDF | ✅ | ✅ | ✅ |
| Organize Tools (Merge, Split) | 3 files/day | Unlimited | Unlimited |
| Conversion Tools (Office, Images) | 3 files/day | Unlimited | Unlimited |
| PDF Compression & Optimization | Standard | High / Custom DPI | High / Custom DPI |
| OCR Text Extraction | English | English, Hindi, Marathi | Multi-Language + Searchable PDF |
| Batch Queue Processing | — | Up to 10 files | Unlimited Concurrent Queue |
| Document Encryption & Security | — | ✅ | ✅ |
| Priority Enterprise Support | — | — | ✅ |

---

## 🛠️ Technology Stack & Dependencies

```text
Language:        Dart 3.x
Framework:       Flutter 3.x (Desktop & Mobile)
State Management: Riverpod 3 (Notifier & ConsumerWidget architecture)
PDF Engine:      PDFium via pdfx & dart_pdf (pdf 3.13)
Local Database:  SQLite via sqflite_common_ffi
Printing:        printing 5.15
File Services:   file_picker, desktop_drop, cross_file
UI Components:   Material 3, custom vector icons, Google Fonts (Segoe UI / Roboto)
```

---

*Document compiled for the ReadNext Engineering & Product Team • Complex Innovators.*
