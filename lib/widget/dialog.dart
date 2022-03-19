import 'package:flutter/material.dart';

/// 彈出一個確認對話框 以便用戶確認操作
Future<bool?> showConfirmationDialog(
  BuildContext context, {
  Widget? title,
  Widget? child,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: title,
        content: SingleChildScrollView(
          child: child,
        ),
        actions: <Widget>[
          TextButton(
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
            onPressed: () => Navigator.of(context).pop(true),
          ),
          TextButton(
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    },
  );
}

/// 彈出一個文本輸入框 以便用戶輸入文本
Future<String?> showInputDialog(
  BuildContext context, {
  Widget? title,
  Widget? text,
  String? initialValue,
  Widget? prefixIcon,
  String? labelText,
  TextInputType? keyboardType,
}) {
  final controller = TextEditingController(text: initialValue);
  final decoration = prefixIcon == null && labelText == null
      ? null
      : InputDecoration(
          prefixIcon: prefixIcon,
          labelText: labelText,
        );
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      final textFormField = TextFormField(
        controller: controller,
        decoration: decoration,
      );
      return AlertDialog(
        title: title,
        content: SingleChildScrollView(
          child: text == null
              ? textFormField
              : Column(
                  children: [
                    text,
                    textFormField,
                  ],
                ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
            onPressed: () => Navigator.of(context).pop(controller.text),
          ),
          TextButton(
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            onPressed: () => Navigator.of(context).pop(null),
          ),
        ],
      );
    },
  );
}
