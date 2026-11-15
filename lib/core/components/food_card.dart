import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/nutrition_model.dart';

class FoodCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final Widget? trailing;
  final String? heroTagPrefix;

  const FoodCard({
    super.key,
    required this.food,
    this.onTap,
    this.onAdd,
    this.trailing,
    this.heroTagPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 58,
        height: 58,
        color: isDark ? FormaColors.charcoal : FormaColors.warmCream,
        child: food.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: food.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(Icons.restaurant,
                    color: FormaColors.concreteGrey),
              )
            : const Icon(Icons.restaurant, color: FormaColors.primaryAccent),
      ),
    );

    if (heroTagPrefix != null) {
      imageWidget = Hero(
        tag: '${heroTagPrefix}_food_img_${food.id}',
        child: imageWidget,
      );
    }

    Widget nameWidget = Text(
      food.name,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color:
            isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (heroTagPrefix != null) {
      nameWidget = Hero(
        tag: '${heroTagPrefix}_food_name_${food.id}',
        child: Material(
          color: Colors.transparent,
          child: nameWidget,
        ),
      );
    }

    final effectiveTrailing = trailing ??
        (onAdd != null
            ? IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: FormaColors.primaryAccent, size: 24),
                onPressed: onAdd,
                tooltip: 'Add to diary',
              )
            : null);

    return FormaBounceable(
      onTap: onTap ?? onAdd,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? FormaColors.darkCardBackground
              : FormaColors.lightCardBackground,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            imageWidget,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: nameWidget),
                      if (food.isBranded) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: FormaColors.goldenYellow
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            food.brandName ?? 'Branded',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? FormaColors.goldenYellow
                                  : const Color(0xFF7A5400),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${food.calories.toInt()} kcal • ${food.protein.toStringAsFixed(1)}g protein',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${food.servingWeight.toInt()} ${food.servingUnit} • ${food.category}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: FormaColors.concreteGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (effectiveTrailing != null) effectiveTrailing,
          ],
        ),
      ),
    );
  }
}
