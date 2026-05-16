import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AlbumCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData placeholderIcon;

  const AlbumCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.placeholderIcon = Icons.music_note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.surface,
              gradient: const LinearGradient(
                colors: [Color(0xFF2C1045), Color(0xFF100824)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(placeholderIcon, size: 48, color: AppColors.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
