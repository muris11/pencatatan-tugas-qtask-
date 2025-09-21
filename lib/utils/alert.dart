import 'package:flutter/material.dart';

Future<void> showModernAlert(BuildContext context, String title, String message, {bool success = false, VoidCallback? onOk}) async {
  final Color bgColor = success ? Colors.green.shade50 : Colors.red.shade50;
  final Color iconColor = success ? Colors.green : Colors.red;
  final Color btnColor = success ? Colors.green : Colors.red;
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(success ? Icons.check_circle : Icons.error, color: iconColor, size: 40),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: iconColor)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size(80, 40),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              if (onOk != null) onOk();
            },
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    ),
  );
}
