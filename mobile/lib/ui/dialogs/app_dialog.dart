import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme_colors.dart';
import '../buttons/secondary_button.dart';

enum DialogButtonVariant {
  primary,
  filled,
  outlined,
  text,
}

class AppDialogAction<T> {
  const AppDialogAction({
    required this.label,
    this.value,
    this.isPrimary = false,
    this.variant,
  });

  final String label;
  final T? value;
  final bool isPrimary;

  /// Если не задан: [isPrimary] → primary, иначе outlined.
  final DialogButtonVariant? variant;
}

class AppDialogChoice<T> {
  const AppDialogChoice({
    required this.label,
    required this.value,
  });

  final String label;
  final T value;
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  List<AppDialogAction<T>> actions = const [],
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => _AppDialog<T>(
      title: title,
      message: message,
      content: content,
      actions: actions,
    ),
  );
}

Future<T?> showAppChoiceDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  required List<AppDialogChoice<T>> choices,
  String cancelLabel = 'Отмена',
}) {
  return showAppDialog<T>(
    context: context,
    title: title,
    message: message,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final choice in choices) ...[
          _DialogActionButton(
            label: choice.label,
            variant: DialogButtonVariant.filled,
            onPressed: () => Navigator.pop(context, choice.value),
          ),
          if (choice != choices.last) const SizedBox(height: AppSpacing.s8),
        ],
      ],
    ),
    actions: [
      AppDialogAction<T>(
        label: cancelLabel,
        variant: DialogButtonVariant.text,
      ),
    ],
  );
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    required this.label,
    this.onPressed,
    this.primary = false,
    this.variant,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final DialogButtonVariant? variant;

  static const double _height = 44;

  DialogButtonVariant _resolveVariant() {
    if (variant != null) return variant!;
    if (primary) return DialogButtonVariant.primary;
    return DialogButtonVariant.outlined;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final resolved = _resolveVariant();

    if (resolved == DialogButtonVariant.primary) {
      return SizedBox(
        width: double.infinity,
        height: _height,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colors.text,
            foregroundColor: colors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SecondaryButton.radius),
            ),
            textStyle: AppTextStyles.text14_550(color: colors.background),
          ),
          child: Text(label),
        ),
      );
    }

    if (resolved == DialogButtonVariant.text) {
      return SizedBox(
        width: double.infinity,
        height: _height,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: colors.text,
            textStyle: AppTextStyles.text14_550(color: colors.text),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SecondaryButton.radius),
            ),
          ),
          child: Text(label),
        ),
      );
    }

    if (resolved == DialogButtonVariant.filled) {
      return SizedBox(
        width: double.infinity,
        height: _height,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.brightSnow,
            foregroundColor: colors.text,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SecondaryButton.radius),
            ),
            textStyle: AppTextStyles.text14_550(color: colors.text),
          ),
          child: Text(label),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: _height,
      child: SecondaryButton(
        label: label,
        expanded: true,
        style: SecondaryButtonStyle.whiteOutlined,
        labelColor: colors.text,
        onPressed: onPressed,
      ),
    );
  }
}

class _AppDialog<T> extends StatelessWidget {
  const _AppDialog({
    required this.title,
    this.message,
    this.content,
    required this.actions,
  });

  final String title;
  final String? message;
  final Widget? content;
  final List<AppDialogAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingGlobal,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: colors.borderSubtle, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: colors.shadowSubtle,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: AppTextStyles.text18_600(color: colors.text),
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  message!,
                  style: AppTextStyles.text15_450(color: colors.caption),
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: AppSpacing.s16),
                content!,
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s24),
                for (final action in actions) ...[
                  _DialogActionButton(
                    label: action.label,
                    primary: action.isPrimary,
                    variant: action.variant,
                    onPressed: action.value == null && !action.isPrimary
                        ? () => Navigator.pop(context)
                        : () => Navigator.pop(context, action.value),
                  ),
                  if (action != actions.last)
                    const SizedBox(height: AppSpacing.s8),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
