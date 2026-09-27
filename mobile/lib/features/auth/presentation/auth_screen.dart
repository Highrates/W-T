import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../data/auth_repository.dart';

enum _AuthStep { contact, code }

/// OTP-вход по email или телефону.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _contactController = TextEditingController();
  final _codeController = TextEditingController();

  AuthContactChannel _channel = AuthContactChannel.email;
  _AuthStep _step = _AuthStep.contact;
  var _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _contactController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _contact => _contactController.text.trim();

  Future<void> _requestCode() async {
    if (_contact.isEmpty) {
      setState(() => _error = 'Введите ${_channelLabel()}');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).requestOtp(
            channel: _channel,
            contact: _contact,
          );
      if (!mounted) return;
      setState(() {
        _step = _AuthStep.code;
        _codeController.clear();
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Введите код из письма или SMS');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await ref.read(authRepositoryProvider).verifyOtp(
            channel: _channel,
            contact: _contact,
            code: code,
          );
      await ref.read(authSessionProvider.notifier).setSession(session);
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _backToContact() {
    setState(() {
      _step = _AuthStep.contact;
      _codeController.clear();
      _error = null;
    });
  }

  String _channelLabel() {
    return switch (_channel) {
      AuthContactChannel.email => 'email',
      AuthContactChannel.phone => 'номер телефона',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.text),
          onPressed: () {
            if (_step == _AuthStep.code) {
              _backToContact();
            } else {
              context.pop(false);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.paddingGlobal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _step == _AuthStep.contact ? 'Вход' : 'Код подтверждения',
                style: AppTextStyles.text18_600(color: colors.text),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                _step == _AuthStep.contact
                    ? 'Получите одноразовый код на email или телефон'
                    : 'Код отправлен на ${_channel == AuthContactChannel.email ? _contact : _contact}',
                style: AppTextStyles.text15_450(color: colors.caption),
              ),
              const SizedBox(height: AppSpacing.s24),
              if (_step == _AuthStep.contact) ...[
                _ChannelPicker(
                  channel: _channel,
                  onChanged: _isLoading
                      ? null
                      : (value) => setState(() => _channel = value),
                ),
                const SizedBox(height: AppSpacing.s16),
                TextField(
                  controller: _contactController,
                  keyboardType: _channel == AuthContactChannel.email
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _requestCode(),
                  decoration: _fieldDecoration(
                    colors: colors,
                    hint: _channel == AuthContactChannel.email
                        ? 'you@example.com'
                        : '+7 900 123-45-67',
                  ),
                  style: AppTextStyles.text15_450(color: colors.text),
                ),
              ] else ...[
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onSubmitted: (_) => _verifyCode(),
                  decoration: _fieldDecoration(
                    colors: colors,
                    hint: '123456',
                  ),
                  style: AppTextStyles.text15_450(color: colors.text),
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.s12),
                TextButton(
                  onPressed: _isLoading ? null : _requestCode,
                  child: Text(
                    'Отправить код повторно',
                    style: AppTextStyles.text14_550(color: colors.text),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(
                  _error!,
                  style: AppTextStyles.text13_400(color: Colors.red.shade700),
                ),
              ],
              const Spacer(),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading
                      ? null
                      : (_step == _AuthStep.contact ? _requestCode : _verifyCode),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.text,
                    foregroundColor: colors.background,
                    disabledBackgroundColor: colors.caption.withValues(alpha: 0.35),
                    shape: const StadiumBorder(),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.background,
                          ),
                        )
                      : Text(
                          _step == _AuthStep.contact ? 'Получить код' : 'Войти',
                          style: AppTextStyles.text14_550(color: colors.background),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required AppThemeColors colors,
    required String hint,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.text15_450(
        color: colors.caption.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: colors.secondBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.br12,
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _ChannelPicker extends StatelessWidget {
  const _ChannelPicker({
    required this.channel,
    required this.onChanged,
  });

  final AuthContactChannel channel;
  final ValueChanged<AuthContactChannel>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SegmentedButton<AuthContactChannel>(
      segments: const [
        ButtonSegment(
          value: AuthContactChannel.email,
          label: Text('Email'),
        ),
        ButtonSegment(
          value: AuthContactChannel.phone,
          label: Text('Телефон'),
        ),
      ],
      selected: {channel},
      onSelectionChanged: onChanged == null
          ? null
          : (selection) => onChanged!(selection.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.background;
          }
          return colors.text;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.text;
          }
          return colors.secondBackground;
        }),
      ),
    );
  }
}
