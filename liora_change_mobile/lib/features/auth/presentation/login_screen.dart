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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  String? _bannerMessage;
  Map<String, List<String>> _serverErrors = const <String, List<String>>{};

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
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
        .login(email: _email.text.trim(), password: _password.text);

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
      title: 'Welcome back',
      subtitle: 'Pick up where you left off.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text("New here?", style: theme.textTheme.bodyMedium),
          TextButton(
            onPressed: isBusy ? null : () => context.go(AppRoute.register.path),
            child: const Text('Create an account'),
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
                label: 'Email',
                controller: _email,
                validator: Validators.email,
                serverError: _serverErrors['email']?.first,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                prefixIcon: Icons.mail_outline_rounded,
                autofocus: true,
                enabled: !isBusy,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Password',
                controller: _password,
                validator: Validators.password,
                serverError: _serverErrors['password']?.first,
                obscurable: true,
                focusNode: _passwordFocus,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.password],
                prefixIcon: Icons.lock_outline_rounded,
                enabled: !isBusy,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Log in',
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
