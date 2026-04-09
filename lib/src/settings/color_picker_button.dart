import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerButton extends StatefulWidget {
  const ColorPickerButton({
    super.key,
    required this.current,
    required this.onColorSelected,
    required this.label,
  });

  final Color current;
  final ValueChanged<Color> onColorSelected;
  final String label;

  @override
  State<ColorPickerButton> createState() => _ColorPickerButtonState();
}

class _ColorPickerButtonState extends State<ColorPickerButton> {
  Color? _windowsColor;

  static const List<Color> _swatches = [
    Color(0xFF6750A4), // Deep Purple (default)
    Color(0xFF1565C0), // Blue
    Color(0xFF00695C), // Teal
    Color(0xFFE65100), // Orange
    Color(0xFFAD1457), // Pink
    Color(0xFF2E7D32), // Green
    Color(0xFFFFC107), // Yellow/Amber
  ];

  @override
  void initState() {
    super.initState();
    _loadWindowsAccentColor();
  }

  Future<void> _loadWindowsAccentColor() async {
    try {
      final color = await DynamicColorPlugin.getAccentColor();
      if (mounted && color != null) {
        setState(() => _windowsColor = color);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: widget.current,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.label),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (_windowsColor != null)
              _buildSwatch(ctx, _windowsColor!, isWindows: true),
            ..._swatches.map((c) => _buildSwatch(ctx, c)),
            _buildCustomButton(ctx, context),
          ],
        ),
      ),
    );
  }

  Widget _buildSwatch(BuildContext ctx, Color color, {bool isWindows = false}) {
    final isSelected = color.toARGB32() == widget.current.toARGB32();
    final circle = InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.of(ctx).pop();
        widget.onColorSelected(color);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(ctx).colorScheme.onSurface
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );

    if (!isWindows) return circle;

    return Tooltip(
      message: 'Windows',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          circle,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.desktop_windows,
                size: 12,
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomButton(BuildContext ctx, BuildContext widgetContext) {
    return Tooltip(
      message: 'Custom',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(ctx).pop();
          _showCustomPicker(widgetContext);
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(ctx).colorScheme.outline,
              width: 2,
            ),
            gradient: const SweepGradient(
              colors: [
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.cyan,
                Colors.blue,
                Colors.purple,
                Colors.red,
              ],
            ),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  void _showCustomPicker(BuildContext context) {
    Color tempColor = widget.current;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(widget.label),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) =>
                  setDialogState(() => tempColor = color),
              enableAlpha: false,
              hexInputBar: true,
              pickerAreaHeightPercent: 0.7,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onColorSelected(tempColor);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
