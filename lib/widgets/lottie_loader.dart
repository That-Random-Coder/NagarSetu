import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Reusable Lottie loading widget using Sandy Loading animation
class LottieLoader extends StatelessWidget {
  final double size;
  final String? message;

  const LottieLoader({super.key, this.size = 120, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Lottie.asset(
              'assets/Sandy Loading.json',
              fit: BoxFit.contain,
              repeat: true,
              frameRate: FrameRate.max,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Success dialog with Order Completed lottie animation
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onDismiss;

  const SuccessDialog({
    super.key,
    this.title = 'Success!',
    this.message = 'Operation completed successfully.',
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Issue Reported!',
    String message =
        'Your issue has been reported successfully. You will be notified once it is acknowledged.',
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          SuccessDialog(title: title, message: message, onDismiss: onDismiss),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Lottie.asset(
                'assets/Order completed.json',
                fit: BoxFit.contain,
                repeat: false,
                frameRate: FrameRate.max,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDismiss?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline loading indicator for buttons
class ButtonLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const ButtonLoader({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/Sandy Loading.json',
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}
