import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/models.dart';

class ItemAvatar extends StatelessWidget {
  final MenuItem item;
  final double? width;
  final double height;
  final double radius;

  const ItemAvatar({
    super.key,
    required this.item,
    this.width,
    required this.height,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'menu-item-${item.id}',
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.peach, Color(0xFFFFDCC4)],
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: FractionallySizedBox(
            heightFactor: 0.55,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                item.name.isEmpty ? '?' : item.name[0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
