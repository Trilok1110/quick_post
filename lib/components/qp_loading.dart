import 'package:flutter/material.dart';

class QPLoading extends StatelessWidget {
  final double size;
  final String? label;
  const QPLoading({super.key, this.size = 36, this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3.5,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 16),
          Text(label!, style: Theme.of(context).textTheme.bodyMedium),
        ]
      ],
    );
  }
}

