import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/super_admin_theme.dart';

class GeofenceWarningDialog extends StatefulWidget {
  final DateTime expiryTime;
  final VoidCallback onTurnOnBreak;
  final VoidCallback onDismiss;

  const GeofenceWarningDialog({
    super.key,
    required this.expiryTime,
    required this.onTurnOnBreak,
    required this.onDismiss,
  });

  @override
  State<GeofenceWarningDialog> createState() => _GeofenceWarningDialogState();
}

class _GeofenceWarningDialogState extends State<GeofenceWarningDialog> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    if (widget.expiryTime.isAfter(now)) {
      setState(() {
        _remaining = widget.expiryTime.difference(now);
      });
    } else {
      setState(() {
        _remaining = Duration.zero;
      });
      _timer.cancel();
      // If time expires, the parent will handle checkout through its 30s timer,
      // but we can dismiss the dialog so it doesn't linger forever.
      if (mounted) {
        widget.onDismiss();
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SuperAdminTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: SuperAdminTheme.primaryOrange, size: 28),
          SizedBox(width: 8),
          Expanded(
            child: Text('Outside Geofence', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'You have left the 100m office radius. Please turn on your break or return to the office within 15 minutes, otherwise you will be automatically checked out.',
            style: TextStyle(color: SuperAdminTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: SuperAdminTheme.backgroundBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SuperAdminTheme.primaryOrange.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text('CHECK-OUT IN', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(_remaining),
                  style: const TextStyle(
                    color: SuperAdminTheme.primaryOrange,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onDismiss,
          child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onTurnOnBreak();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: SuperAdminTheme.primaryOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Turn On Break', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
