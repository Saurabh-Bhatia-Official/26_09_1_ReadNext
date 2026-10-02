import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/file_service.dart';
import '../../../services/pdf/pdf_security_service.dart';
import '../../../state/document_provider.dart';

class SecurityToolView extends ConsumerStatefulWidget {
  const SecurityToolView({super.key});

  @override
  ConsumerState<SecurityToolView> createState() => _SecurityToolViewState();
}

class _SecurityToolViewState extends ConsumerState<SecurityToolView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Protect State
  String? _protectFilePath;
  final TextEditingController _userPasswordController = TextEditingController();
  final TextEditingController _ownerPasswordController = TextEditingController();
  bool _allowPrinting = true;
  bool _allowCopying = true;
  bool _allowModifying = false;
  bool _isProtecting = false;

  // Unlock State
  String? _unlockFilePath;
  final TextEditingController _unlockPasswordController = TextEditingController();
  bool _isUnlocking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userPasswordController.dispose();
    _ownerPasswordController.dispose();
    _unlockPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Security & Encryption'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Password Protect & Restrict', icon: Icon(Icons.lock_outline)),
            Tab(text: 'Unlock Protected PDF', icon: Icon(Icons.lock_open_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProtectTab(theme),
          _buildUnlockTab(theme),
        ],
      ),
    );
  }

  Widget _buildProtectTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // File selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.security, color: Colors.red, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _protectFilePath != null ? FileService.getFileName(_protectFilePath!) : 'No PDF selected',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _protectFilePath ?? 'Choose a PDF to encrypt with passwords and restrictions',
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.folder_open),
                      label: Text(_protectFilePath == null ? 'Select PDF' : 'Change'),
                      onPressed: () async {
                        final p = await FileService.pickPdfFile();
                        if (p != null) setState(() => _protectFilePath = p);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Passwords
            TextField(
              controller: _userPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'User / Document Open Password *',
                hintText: 'Required to open and view the document',
                prefixIcon: Icon(Icons.password),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ownerPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Owner / Permissions Password (Optional)',
                hintText: 'Required to modify security settings or permissions',
                prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            Text('Permissions & Document Restrictions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            CheckboxListTile(
              title: const Text('Allow Printing'),
              subtitle: const Text('Permit users to print high or low resolution copies'),
              value: _allowPrinting,
              onChanged: (v) => setState(() => _allowPrinting = v ?? true),
            ),
            CheckboxListTile(
              title: const Text('Allow Content Copying'),
              subtitle: const Text('Permit text and image copying to clipboard'),
              value: _allowCopying,
              onChanged: (v) => setState(() => _allowCopying = v ?? true),
            ),
            CheckboxListTile(
              title: const Text('Allow Modifying Contents'),
              subtitle: const Text('Permit page alterations, form filling, and editing'),
              value: _allowModifying,
              onChanged: (v) => setState(() => _allowModifying = v ?? false),
            ),

            const SizedBox(height: 24),

            if (_isProtecting) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
            ],

            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: const Icon(Icons.lock),
              label: const Text('Encrypt & Protect PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: (_protectFilePath != null && !_isProtecting) ? _handleProtect : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_open, color: Colors.green, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _unlockFilePath != null ? FileService.getFileName(_unlockFilePath!) : 'No PDF selected',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _unlockFilePath ?? 'Choose a password-protected PDF to permanently remove security',
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Browse'),
                      onPressed: _isUnlocking ? null : _pickUnlockPdf,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _unlockPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Document Password *',
                hintText: 'Enter authorized password to remove protection',
                prefixIcon: Icon(Icons.key),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            if (_isUnlocking) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: const Icon(Icons.lock_open),
              label: const Text('Unlock & Save Decrypted PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: (_unlockFilePath != null && !_isUnlocking) ? _handleUnlock : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickUnlockPdf() async {
    final p = await FileService.pickPdfFile();
    if (p != null) setState(() => _unlockFilePath = p);
  }

  Future<void> _handleProtect() async {
    if (_protectFilePath == null) return;
    final password = _userPasswordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a password')));
      return;
    }

    setState(() => _isProtecting = true);

    try {
      final bytes = await File(_protectFilePath!).readAsBytes();
      final permissions = SecurityPermissions(
        allowPrinting: _allowPrinting,
        allowCopying: _allowCopying,
        allowModifying: _allowModifying,
        allowAnnotating: true,
      );

      final protectedBytes = await PdfSecurityService.protectPdf(
        pdfBytes: bytes,
        password: password,
        ownerPassword: _ownerPasswordController.text.trim().isNotEmpty ? _ownerPasswordController.text.trim() : null,
        permissions: permissions,
      );

      final savePath = await FileService.savePdfFile(
        fileName: '${FileService.getFileName(_protectFilePath!).replaceAll('.pdf', '')}_protected.pdf',
        bytes: protectedBytes,
        dialogTitle: 'Save Protected PDF',
      );

      if (savePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Protected PDF saved to $savePath')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isProtecting = false);
    }
  }

  Future<void> _handleUnlock() async {
    if (_unlockFilePath == null) return;
    final pass = _unlockPasswordController.text.trim();
    if (pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the document password')));
      return;
    }

    setState(() => _isUnlocking = true);

    try {
      final bytes = await File(_unlockFilePath!).readAsBytes();
      final unlockedBytes = await PdfSecurityService.removePassword(protectedBytes: bytes, password: pass);

      final savePath = await FileService.savePdfFile(
        fileName: '${FileService.getFileName(_unlockFilePath!).replaceAll('.pdf', '')}_unlocked.pdf',
        bytes: unlockedBytes,
        dialogTitle: 'Save Unlocked PDF',
      );

      if (savePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unlocked PDF saved to $savePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => ref.read(documentProvider.notifier).openFile(savePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unlock failed: $e')));
    } finally {
      if (mounted) setState(() => _isUnlocking = false);
    }
  }
}
