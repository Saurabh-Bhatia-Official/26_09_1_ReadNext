import 'package:flutter/material.dart';
import '../../../data/models/annotation_model.dart';

class SignaturePadDialog extends StatefulWidget {
  const SignaturePadDialog({super.key});

  static Future<List<DrawingPoint>?> show(BuildContext context) {
    return showDialog<List<DrawingPoint>>(
      context: context,
      builder: (context) => const SignaturePadDialog(),
    );
  }

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  final List<DrawingPoint> _points = [];
  Color _penColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.draw_outlined),
          SizedBox(width: 8),
          Text('Digital Signature Pad'),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 280,
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final local = details.localPosition;
                      setState(() {
                        _points.add(DrawingPoint(local.dx, local.dy));
                      });
                    }
                  },
                  child: CustomPaint(
                    painter: _SignaturePainter(_points, _penColor),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Ink Color: ', style: TextStyle(fontSize: 12)),
                _colorChip(Colors.black),
                _colorChip(const Color(0xFF0D47A1)),
                _colorChip(const Color(0xFFB71C1C)),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _points.clear();
                    });
                  },
                  icon: const Icon(Icons.delete_sweep, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _points.isEmpty ? null : () => Navigator.of(context).pop(_points),
          child: const Text('Apply Signature'),
        ),
      ],
    );
  }

  Widget _colorChip(Color color) {
    final isSelected = _penColor == color;
    return GestureDetector(
      onTap: () => setState(() => _penColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<DrawingPoint> points;
  final Color color;

  _SignaturePainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (int i = 0; i < points.length - 1; i++) {
      // Draw line between consecutive points within proximity
      final p1 = points[i].toOffset();
      final p2 = points[i + 1].toOffset();
      if ((p1 - p2).distance < 25) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
