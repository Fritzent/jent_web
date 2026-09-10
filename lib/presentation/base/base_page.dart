import 'package:flutter/material.dart';
import 'package:jent_web/l10n/app_localizations.dart';

abstract class BasePage extends StatefulWidget {
  const BasePage({super.key});
}

abstract class BasePageState<T extends BasePage> extends State<T> {
  bool _isLoading = false;

  // ----------------------------
  // Loading
  // ----------------------------
  void showLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  void hideLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  // ----------------------------
  // Bottom Sheet
  // ----------------------------
  Future<void> showBaseBottomSheet({
    required Widget child,
    bool isDismissible = true,
  }) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: true,
      builder: (_) => child,
    );
  }

  // ----------------------------
  // Permission Dialog
  // ----------------------------
  Future<bool> showPermissionPrompt({
    required String title,
    required String message,
  }) async {
    final strings = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.dialogDeny),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.dialogAllow),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ----------------------------
  // Common Scaffold
  // ----------------------------
  Widget buildPage(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildPage(context),

        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}