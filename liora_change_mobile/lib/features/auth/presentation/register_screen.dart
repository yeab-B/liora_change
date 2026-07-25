import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/user.dart';
import '../../../router/app_router.dart';
import '../application/auth_controller.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmationFocus = FocusNode();

  String? _bannerMessage;
  Map<String, List<String>> _serverErrors = const <String, List<String>>{};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmationFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _bannerMessage = null;
      _serverErrors = const <String, List<String>>{};
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref
        .read(authControllerProvider.notifier)
        .register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          passwordConfirmation: _confirmation.text,
        );

    if (!mounted) return;

    final AsyncValue<User?> auth = ref.read(authControllerProvider);
    if (auth.hasError) {
      _showFailure(auth.error!);
      return;
    }
    if (auth.value != null) {
      context.go(AppRoute.home.path);
    }
  }

  void _showFailure(Object error) {
    if (error is ApiException) {
      setState(() {
        _bannerMessage = error.message;
        _serverErrors = error.fieldErrors;
      });
    } else {
      setState(
        () => _bannerMessage = 'Something went wrong. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isBusy = ref.watch(authControllerProvider).isLoading;

    return AuthScaffold(
      title: 'Start your streak',
      subtitle: 'A few details and you are in.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Already have an account?', style: theme.textTheme.bodyMedium),
          TextButton(
            onPressed: isBusy ? null : () => context.go(AppRoute.login.path),
            child: const Text('Log in'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_bannerMessage != null) ...<Widget>[
                AuthErrorBanner(message: _bannerMessage!),
                const SizedBox(height: AppSpacing.md),
              ],
              AppTextField(
                label: 'Name',
                controller: _name,
                validator: (String? value) =>
                    Validators.required(value, field: 'name'),
                serverError: _serverErrors['name']?.first,
                keyboardType: TextInputType.name,
                autofillHints: const <String>[AutofillHints.name],
                prefixIcon: Icons.person_outline_rounded,
                autofocus: true,
                enabled: !isBusy,
                onSubmitted: (_) => _emailFocus.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Email',
                controller: _email,
                validator: Validators.email,
                serverError: _serverErrors['email']?.first,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                prefixIcon: Icons.mail_outline_rounded,
                focusNode: _emailFocus,
                enabled: !isBusy,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Password',
                controller: _password,
                validator: Validators.newPassword,
                serverError: _serverErrors['password']?.first,
                obscurable: true,
                focusNode: _passwordFocus,
                autofillHints: const <String>[AutofillHints.newPassword],
                prefixIcon: Icons.lock_outline_rounded,
                enabled: !isBusy,
                onSubmitted: (_) => _confirmationFocus.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Confirm password',
                controller: _confirmation,
                validator: (String? value) =>
                    Validators.passwordConfirmation(value, _password.text),
                serverError: _serverErrors['password_confirmation']?.first,
                obscurable: true,
                focusNode: _confirmationFocus,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline_rounded,
                enabled: !isBusy,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Create account',
                isLoading: isBusy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
