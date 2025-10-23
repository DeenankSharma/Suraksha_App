import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_setup/theme/app_theme.dart';

class ContactWidget extends StatelessWidget {
  final Map<String, dynamic> contact;
  final Function()? onAdd;
  final Function()? onRemove;

  const ContactWidget({
    super.key,
    required this.contact,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSaved = contact['isSaved'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSaved 
              ? AppTheme.primary.withOpacity(0.5)
              : AppTheme.accent.withOpacity(0.5),
          width: isSaved ? 2 : 1,
        ),
      ),
      color: isSaved 
          ? AppTheme.primary.withOpacity(0.05)
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSaved 
                    ? AppTheme.primary
                    : AppTheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  () {
                    final name = (contact['displayName'] ?? 'U').toString();
                    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
                  }(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact['displayName'] ?? 'No Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (contact['isManual'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.pencil,
                                size: 10,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Manual',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.phone,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          (contact['phones'] as List).isNotEmpty
                              ? (contact['phones'] as List).first.toString()
                              : 'No number',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (contact['callCount'] != null &&
                          contact['callCount'] > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.phone_fill,
                                size: 10,
                                color: AppTheme.secondary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${contact['callCount']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSaved)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(CupertinoIcons.minus_circle),
                color: AppTheme.error,
                tooltip: 'Remove from Emergency',
              )
            else
              IconButton(
                onPressed: onAdd,
                icon: const Icon(CupertinoIcons.add_circled),
                color: AppTheme.success,
                tooltip: 'Add to Emergency',
              ),
          ],
        ),
      ),
    );
  }
}
