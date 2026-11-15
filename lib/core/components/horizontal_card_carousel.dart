import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forma/core/theme/app_colors.dart';

class CarouselPillarItem {
  final String title;
  final String subtitle;
  final List<String> tags;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final VoidCallback onTap;

  const CarouselPillarItem({
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.onTap,
  });
}

/// Horizontal Card Carousel (Reference Image 2 Fidelity)
///
/// Provides a horizontal collection of colourful, content-rich cards
/// with balanced typography and metadata pills.
class HorizontalCardCarousel extends StatelessWidget {
  final List<CarouselPillarItem> items;

  const HorizontalCardCarousel({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = items[index];

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              item.onTap();
            },
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: item.backgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: item.backgroundColor.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: item.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(item.icon, size: 18, color: item.textColor),
                    ],
                  ),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: item.textColor.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: item.tags.map((tag) {
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: FormaColors.charcoal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
