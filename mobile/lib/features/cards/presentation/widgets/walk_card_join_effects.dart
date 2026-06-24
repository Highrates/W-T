import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/walk_card_join_status.dart';

/// Раскладка блока присоединения.
enum WalkJoinSectionLayout {
  /// Полная ширина под карточкой в ленте.
  card,

  /// Дата слева, CTA справа — футер страницы мероприятия.
  eventFooter,
}

/// Кнопка присоединения, баннер успеха и «шарики» с плюсом.
class WalkCardJoinSection extends StatefulWidget {
  const WalkCardJoinSection({
    super.key,
    required this.initialStatus,
    this.onJoinSubmitted,
    this.layout = WalkJoinSectionLayout.card,
    this.whenSlot,
    this.showBalloons = true,
    this.onSuccessBannerChanged,
    this.onJoinStatusChanged,
    this.eventFooterChat,
  });

  final WalkCardJoinStatus initialStatus;
  final VoidCallback? onJoinSubmitted;
  final WalkJoinSectionLayout layout;

  /// Слот даты/времени слева ([WalkJoinSectionLayout.eventFooter]).
  final Widget? whenSlot;
  final bool showBalloons;

  /// Баннер успеха рисуется снаружи (над glass-футером на [EventScreen]).
  final ValueChanged<bool>? onSuccessBannerChanged;

  /// Смена статуса заявки (чат маршрута и др. на [EventScreen]).
  final ValueChanged<WalkCardJoinStatus>? onJoinStatusChanged;

  /// Чат перед CTA ([WalkJoinSectionLayout.eventFooter]).
  final Widget? eventFooterChat;

  static const double _ctaRadius = AppRadius.r8;

  /// Высота CTA в футере мероприятия (padding 10 + line 18 + padding 10).
  static const double eventFooterJoinHeight = 38;

  @override
  State<WalkCardJoinSection> createState() => _WalkCardJoinSectionState();
}

class _WalkCardJoinSectionState extends State<WalkCardJoinSection>
    with TickerProviderStateMixin {
  late WalkCardJoinStatus _status;
  bool _submitting = false;
  bool _showBanner = false;
  int _balloonBurstId = 0;

  late final AnimationController _pendingPulse;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _pendingPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (_status == WalkCardJoinStatus.pending) {
      _pendingPulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WalkCardJoinSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatus != widget.initialStatus &&
        _status == WalkCardJoinStatus.canJoin) {
    _status = widget.initialStatus;
    _syncPendingPulse();
    if (widget.layout == WalkJoinSectionLayout.eventFooter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifyJoinStatus(_status);
      });
    }
  }
  }

  @override
  void dispose() {
    _pendingPulse.dispose();
    super.dispose();
  }

  void _syncPendingPulse() {
    if (_status == WalkCardJoinStatus.pending) {
      if (!_pendingPulse.isAnimating) {
        _pendingPulse.repeat(reverse: true);
      }
    } else {
      _pendingPulse.stop();
      _pendingPulse.value = 1;
    }
  }

  Future<void> _onJoinTap() async {
    if (_status != WalkCardJoinStatus.canJoin || _submitting) return;

    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    _updateSuccessBanner(true);
    setState(() {
      _submitting = false;
      _status = WalkCardJoinStatus.pending;
      _showBanner = true;
      _balloonBurstId++;
    });
    _notifyJoinStatus(_status);
    _syncPendingPulse();
    widget.onJoinSubmitted?.call();

    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _updateSuccessBanner(false);
      setState(() => _showBanner = false);
    });
  }

  void _updateSuccessBanner(bool visible) {
    if (widget.layout == WalkJoinSectionLayout.eventFooter) {
      widget.onSuccessBannerChanged?.call(visible);
    }
  }

  void _notifyJoinStatus(WalkCardJoinStatus status) {
    widget.onJoinStatusChanged?.call(status);
  }

  String get _label => switch (_status) {
        WalkCardJoinStatus.canJoin => 'Присоединиться!',
        WalkCardJoinStatus.pending => 'Ожидаем организатора',
        WalkCardJoinStatus.approved => 'Вы в списке',
        WalkCardJoinStatus.full => 'Мест нет',
      };

  bool get _isEnabled =>
      _status == WalkCardJoinStatus.canJoin && !_submitting;

  Widget _joinButton(AppThemeColors colors) {
    final isEventFooter = widget.layout == WalkJoinSectionLayout.eventFooter;
    final isPending = _status == WalkCardJoinStatus.pending;

    return _JoinButton(
      label: _label,
      colors: colors,
      isLoading: _submitting,
      isPending: isPending,
      pendingPulse: _pendingPulse,
      onPressed: _isEnabled ? _onJoinTap : null,
      expand: widget.layout == WalkJoinSectionLayout.card,
      backgroundColor:
          isEventFooter ? Colors.transparent : colors.secondBackground,
      labelColor: isEventFooter
          ? Colors.white.withValues(alpha: isPending ? 0.72 : 1)
          : null,
      loadingIndicatorColor: isEventFooter ? Colors.white : null,
      border: isEventFooter
          ? Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 0.3,
            )
          : null,
      borderRadius: isEventFooter ? 100 : WalkCardJoinSection._ctaRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final showInlineBanner =
        _showBanner && widget.layout == WalkJoinSectionLayout.card;
    final banner = AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: showInlineBanner
          ? Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: WalkJoinSuccessBanner(colors: colors),
            )
          : const SizedBox.shrink(),
    );

    final joinControl = switch (widget.layout) {
      WalkJoinSectionLayout.card => _joinButton(colors),
      WalkJoinSectionLayout.eventFooter => SizedBox(
          width: 168,
          child: _joinButton(colors),
        ),
    };

    final body = switch (widget.layout) {
      WalkJoinSectionLayout.card => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [banner, joinControl],
        ),
      WalkJoinSectionLayout.eventFooter => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.whenSlot != null) Expanded(child: widget.whenSlot!),
            if (widget.eventFooterChat != null) ...[
              widget.eventFooterChat!,
              const SizedBox(width: AppSpacing.s8),
            ],
            joinControl,
          ],
        ),
    };

    if (!widget.showBalloons || _balloonBurstId == 0) {
      return body;
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        body,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 120,
          child: IgnorePointer(
            child: _JoinBalloonBurst(
              key: ValueKey(_balloonBurstId),
              accent: colors.green,
              secondary: colors.secondBackground,
            ),
          ),
        ),
      ],
    );
  }
}

/// Баннер «Заявка отправлена».
class WalkJoinSuccessBanner extends StatelessWidget {
  const WalkJoinSuccessBanner({
    super.key,
    required this.colors,
    this.borderRadius = WalkCardJoinSection._ctaRadius,
    this.hugContent = false,
    this.textColor,
  });

  final AppThemeColors colors;
  final double borderRadius;
  /// Ширина по контенту (не на всю строку).
  final bool hugContent;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.text14_550(
      color: textColor ?? colors.text,
    );
    final label = Text('Заявка отправлена', style: labelStyle);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: colors.green.withValues(alpha: 0.28),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        child: Row(
          mainAxisSize: hugContent ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(Icons.check_circle_rounded, color: colors.green, size: 20),
            const SizedBox(width: AppSpacing.s8),
            if (hugContent) label else Expanded(child: label),
          ],
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({
    required this.label,
    required this.colors,
    this.isLoading = false,
    this.isPending = false,
    this.pendingPulse,
    this.onPressed,
    this.expand = true,
    this.backgroundColor,
    this.labelColor,
    this.loadingIndicatorColor,
    this.border,
    this.borderRadius,
  });

  final String label;
  final AppThemeColors colors;
  final bool isLoading;
  final bool isPending;
  final AnimationController? pendingPulse;
  final VoidCallback? onPressed;
  final bool expand;
  final Color? backgroundColor;
  final Color? labelColor;
  final Color? loadingIndicatorColor;
  final Border? border;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? WalkCardJoinSection._ctaRadius;
    final borderRadiusShape = BorderRadius.circular(radius);
    final enabled = onPressed != null && !isLoading;

    Widget child = isLoading
        ? SizedBox(
            height: 20,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: loadingIndicatorColor ??
                      colors.text.withValues(alpha: 0.7),
                ),
              ),
            ),
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: AppTextStyles.text14_550(
                color: labelColor ??
                    (isPending ? colors.caption : colors.text),
              ),
            ),
          );

    if (isPending && pendingPulse != null) {
      child = FadeTransition(
        opacity: Tween<double>(begin: 0.72, end: 1).animate(
          CurvedAnimation(parent: pendingPulse!, curve: Curves.easeInOut),
        ),
        child: child,
      );
    }

    Widget button = Material(
      color: backgroundColor ?? colors.secondBackground,
      borderRadius: borderRadiusShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: borderRadiusShape,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: 10,
          ),
          child: child,
        ),
      ),
    );

    if (border != null) {
      button = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadiusShape,
          border: border,
        ),
        child: button,
      );
    }

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Несколько «шариков» с «+», улетающих вверх от кнопки.
class _JoinBalloonBurst extends StatefulWidget {
  const _JoinBalloonBurst({
    super.key,
    required this.accent,
    required this.secondary,
  });

  final Color accent;
  final Color secondary;

  @override
  State<_JoinBalloonBurst> createState() => _JoinBalloonBurstState();
}

class _JoinBalloonBurstState extends State<_JoinBalloonBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _particleCount = 4;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final centerX = constraints.maxWidth / 2;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < _particleCount; i++)
                  _BalloonParticle(
                    index: i,
                    progress: Curves.easeOutCubic.transform(
                      ((_controller.value - i * 0.1) / 0.9).clamp(0.0, 1.0),
                    ),
                    centerX: centerX,
                    fill: i.isEven ? widget.accent : widget.secondary,
                    stroke: widget.accent,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BalloonParticle extends StatelessWidget {
  const _BalloonParticle({
    required this.index,
    required this.progress,
    required this.centerX,
    required this.fill,
    required this.stroke,
  });

  final int index;
  final double progress;
  final double centerX;
  final Color fill;
  final Color stroke;

  static const _size = 40.0;
  static const _horizontalOffsets = [-36.0, -10.0, 14.0, 42.0];
  static const _wobblePhase = [0.0, 0.7, 1.4, 2.1];

  @override
  Widget build(BuildContext context) {
    final rise = progress * 130;
    final wobble =
        math.sin(progress * math.pi * 2 + _wobblePhase[index]) * 10 * progress;
    final opacity = (1 - progress * 1.15).clamp(0.0, 1.0);
    final scale = 0.55 + progress * 0.55;

    final isAccent = index.isEven;
    final plusColor = isAccent ? Colors.white : stroke;

    return Positioned(
      left: centerX + _horizontalOffsets[index] - _size / 2 + wobble,
      bottom: 8 + rise,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(
                color: stroke.withValues(alpha: isAccent ? 0.35 : 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: stroke.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SizedBox(
              width: _size,
              height: _size,
              child: Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: plusColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
