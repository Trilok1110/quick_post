import 'package:flutter/material.dart';

class QPButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final bool filled;
  final IconData? icon;
  final bool expanded;

  const QPButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.filled = true,
    this.icon,
    this.expanded = true,
  });

  @override
  State<QPButton> createState() => _QPButtonState();
}

class _QPButtonState extends State<QPButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget childContent = widget.loading
        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 22, color: widget.filled ? Colors.white : theme.colorScheme.primary),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: widget.filled ? Colors.white : theme.colorScheme.primary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          );
    final Widget button = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        elevation: widget.filled ? 8 : 0,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTapDown: (_) {
            if (!widget.loading) setState(() => _pressed = true);
          },
          onTapUp: (_) {
            if (!widget.loading) setState(() => _pressed = false);
          },
          onTapCancel: () {
            if (!widget.loading) setState(() => _pressed = false);
          },
          borderRadius: BorderRadius.circular(16),
          onTap: widget.loading ? null : widget.onPressed,
          child: Ink(
            decoration: BoxDecoration(
              gradient: widget.filled
                  ? const LinearGradient(
                      colors: [Color(0xFF38A3A5), Color(0xFFFF61A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.filled ? null : theme.colorScheme.surfaceVariant.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.filled
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
              border: widget.filled
                  ? null
                  : Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                      width: 1.4,
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
              child: Center(child: childContent),
            ),
          ),
        ),
      ),
    );
    return widget.expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

