import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/errors/error_logger.dart';
import '../../core/errors/error_types.dart';

class ErrorDialog {
  static Future<void> show(
    BuildContext context,
    AppError error, {
    String? shopName,
    String? developerPhone,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('⚠ સમસ્યા આવી'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error.userMessage),
              const SizedBox(height: 12),
              Text(
                '[${error.code}]',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ઠીક છે'),
            ),
            if (error.isCritical)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDeveloperContactSheet(
                    context,
                    error,
                    shopName: shopName,
                    developerPhone: developerPhone,
                  );
                },
                child: const Text('Developer નો સંપર્ક કરો'),
              ),
          ],
        );
      },
    );
  }

  static void _showDeveloperContactSheet(
    BuildContext context,
    AppError error, {
    String? shopName,
    String? developerPhone,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final contact = developerPhone?.trim();
        final shop = shopName?.trim() ?? 'મારી દુકાન';
        final message =
            'નમસ્તે, $shop ની એપ માં સમસ્યા આવી છે. Error Code: ${error.code}. કૃપા સહાય કરો.';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Developer સંપર્ક',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('WhatsApp: ${contact ?? 'આગામી સંખ્યા'}'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.whatsapp),
                  label: const Text('WhatsApp મોકલો'),
                  onPressed: contact == null || contact.isEmpty
                      ? null
                      : () async {
                          final uri = Uri.parse(
                            'https://wa.me/$contact?text=${Uri.encodeComponent(message)}',
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Error Log શેર કરો'),
                  onPressed: () async {
                    await ErrorLogger.shareLog();
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'આ લખાણ શેર કરો જયારે તમે લોગ મોકલતા હોય ત્યારે. જો WhatsApp ન હોય તો તો શૅર બટનનો ઉપયોગ કરો.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
