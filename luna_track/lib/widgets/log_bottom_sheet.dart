import 'package:flutter/material.dart';
import '../models/cycle_entry.dart';
import '../screens/log_screen.dart';

class LogBottomSheet extends StatelessWidget {
  final DateTime? date;
  final CycleEntry? existingLog;
  final VoidCallback? onSaved;

  const LogBottomSheet({
    super.key,
    this.date,
    this.existingLog,
    this.onSaved,
  });

  // Static method to show the bottom sheet easily
  static Future<void> show(
    BuildContext context, {
    DateTime? date,
    CycleEntry? existingLog,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => LogBottomSheet(
        date: date,
        existingLog: existingLog,
        onSaved: onSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(date ?? DateTime.now()),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Close button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Log content — reuse existing LogScreen body
              Expanded(
                child: LogScreenBody(
                  date: date,
                  existingLog: existingLog,
                  scrollController: scrollController,
                  onSaved: () {
                    Navigator.pop(context);
                    onSaved?.call();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}
