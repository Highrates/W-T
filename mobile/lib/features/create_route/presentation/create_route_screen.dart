import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../ui/dialogs/app_dialog.dart';
import '../application/create_route_controller.dart';
import '../domain/create_route_step.dart';
import 'open_create_route.dart';
import 'widgets/create_route_compose_step.dart';

/// Создание события: один экран compose (как новый тред).
class CreateRouteScreen extends ConsumerStatefulWidget {
  const CreateRouteScreen({super.key});

  @override
  ConsumerState<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends ConsumerState<CreateRouteScreen> {
  String? _stepError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(createRouteControllerProvider.notifier).tryRestoreDraft(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(createRouteControllerProvider);
    final controller = ref.read(createRouteControllerProvider.notifier);
    final colors = context.appColors;
    final canProceed = _stepError == null &&
        !wizard.isPublishing &&
        controller.validateStep(CreateRouteStep.compose) == null;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton(
          onPressed: () => _confirmExit(context),
          child: Text(
            'Отмена',
            style: AppTextStyles.text15_450(color: colors.text),
          ),
        ),
        leadingWidth: 88,
        title: Text(CreateRouteStep.compose.title),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.paddingGlobal,
              AppSpacing.s8,
              AppSpacing.paddingGlobal,
              AppSpacing.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CreateRouteComposeStep(draft: wizard.draft),
                ),
                if (_stepError != null) ...[
                  Text(
                    _stepError!,
                    style: AppTextStyles.text13_400(color: colors.accent),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                ],
                _PublishBar(
                  canProceed: canProceed,
                  isLoading: wizard.isPublishing,
                  onPrimary: () => _onPublish(controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onPublish(CreateRouteController controller) async {
    final error = controller.validateStep(CreateRouteStep.compose);
    if (error != null) {
      setState(() => _stepError = error);
      return;
    }
    setState(() => _stepError = null);

    try {
      final eventId = await controller.publish();
      if (!mounted || eventId == null) return;
      openPublishedEvent(context, eventId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось опубликовать: $e')),
      );
    }
  }

  Future<void> _confirmExit(BuildContext context) async {
    final leave = await showAppDialog<bool>(
      context: context,
      title: 'Выйти из создания?',
      message:
          'Черновик сохраняется автоматически. Вы сможете продолжить '
          'из меню «Создать событие».',
      actions: const [
        AppDialogAction(
          label: 'Выйти',
          value: true,
          isPrimary: true,
        ),
        AppDialogAction(
          label: 'Остаться',
          value: false,
        ),
      ],
    );
    if (leave == true && context.mounted) {
      context.pop();
    }
  }
}

class _PublishBar extends StatelessWidget {
  const _PublishBar({
    required this.canProceed,
    required this.isLoading,
    required this.onPrimary,
  });

  final bool canProceed;
  final bool isLoading;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      child: Row(
        children: [
          const Spacer(),
          FilledButton(
            onPressed: canProceed && !isLoading ? onPrimary : null,
            style: FilledButton.styleFrom(
              backgroundColor: colors.text,
              foregroundColor: colors.background,
              disabledBackgroundColor: colors.caption.withValues(alpha: 0.35),
              disabledForegroundColor: colors.background.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s24,
                vertical: AppSpacing.s8,
              ),
              shape: const StadiumBorder(),
            ),
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.background,
                    ),
                  )
                : Text(
                    'Опубликовать',
                    style: AppTextStyles.text14_550(color: colors.background),
                  ),
          ),
        ],
      ),
    );
  }
}
