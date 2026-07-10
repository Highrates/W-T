import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../event/presentation/widgets/event_glass_icon_button.dart';
import '../../domain/create_route_step.dart';

class CreateRouteStepShell extends StatelessWidget {
  const CreateRouteStepShell({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.stepCount,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.primaryEnabled = true,
    this.isPrimaryLoading = false,
    this.errorText,
  });

  final CreateRouteStep step;
  final int stepIndex;
  final int stepCount;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final bool primaryEnabled;
  final bool isPrimaryLoading;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final progress = (stepIndex + 1) / stepCount;
    final canProceed = primaryEnabled && !isPrimaryLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.r4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: colors.caption.withValues(alpha: 0.15),
            color: colors.text,
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        Text(
          'Шаг ${stepIndex + 1} из $stepCount',
          style: AppTextStyles.text13_400(color: colors.caption),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(step.title, style: AppTextStyles.text18_600(color: colors.text)),
        if (step.subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            step.subtitle,
            style: AppTextStyles.text15_450(color: colors.caption),
          ),
        ],
        const SizedBox(height: AppSpacing.s24),
        Expanded(child: child),
        if (errorText != null) ...[
          Text(
            errorText!,
            style: AppTextStyles.text13_400(color: colors.accent),
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (onBack != null)
              _WizardBackButton(onPressed: onBack!)
            else
              const SizedBox(width: EventGlassIconButton.size),
            _WizardNextButton(
              label: primaryLabel,
              onPressed: canProceed ? onPrimary : null,
              isLoading: isPrimaryLoading,
            ),
          ],
        ),
      ],
    );
  }
}

class _WizardBackButton extends StatelessWidget {
  const _WizardBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const size = EventGlassIconButton.size;

    return Material(
      color: colors.secondBackground,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.chevron_left_rounded,
            size: EventGlassIconButton.iconSize,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}

class _WizardNextButton extends StatelessWidget {
  const _WizardNextButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const height = EventGlassIconButton.size;

    return Material(
      color: colors.secondBackground,
      borderRadius: BorderRadius.circular(height / 2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(height / 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: SizedBox(
            height: height,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.text,
                      ),
                    )
                  : Text(
                      label,
                      style: AppTextStyles.text14_550(color: colors.text),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
