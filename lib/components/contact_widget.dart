import 'package:flutter/material.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isSaved
                  ? const Color.fromARGB(255, 106, 206, 245).withOpacity(0.4)
                  : const Color.fromARGB(255, 106, 206, 245).withOpacity(0.2),
              isSaved
                  ? const Color.fromARGB(255, 0, 56, 147).withOpacity(0.2)
                  : const Color.fromARGB(255, 0, 56, 147).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact['displayName'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 0, 56, 147),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (contact['phones'] as List).isNotEmpty
                          ? (contact['phones'] as List).first.toString()
                          : 'No number',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSaved)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.red.shade400,
                  tooltip: 'Remove from SOS',
                )
              else
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.green.shade600,
                  tooltip: 'Add to SOS',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
