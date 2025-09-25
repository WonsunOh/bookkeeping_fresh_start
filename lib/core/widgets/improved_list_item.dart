import 'package:flutter/material.dart';

class ImprovedListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? leadingIcon;
  final Color? trailingColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const ImprovedListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leadingIcon,
    this.trailingColor,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: leadingIcon,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : trailing != null
                ? Text(
                    trailing!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: trailingColor ?? Theme.of(context).colorScheme.primary,
                    ),
                  )
                : null,
        onTap: isLoading ? null : onTap,
      ),
    );
  }
}