import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import '../spacing.dart';
import '../theme.dart';

/// App logo, a local image declared under assets in pubspec.yaml.
const kLogoAsset = 'assets/images/logo.png';

/// S1 Splash.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(image: AssetImage(kLogoAsset), width: 96, height: 96),
            SizedBox(height: Spacing.lg),
            Text('Pomodoro',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kInk)),
            SizedBox(height: Spacing.xs),
            Text('Study timer and task list', style: AppText.muted),
            SizedBox(height: 48),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3, color: kMuted),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AuthPage { login, signUp, reset }

/// S2, S3 and S4. Shown while nobody is logged in; the root widget swaps it
/// for the app as soon as Firebase reports a user.
class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key, required this.auth});
  final AuthService auth;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  _AuthPage page = _AuthPage.login;
  String prefillEmail = '';

  void go(_AuthPage p, {String? email}) => setState(() {
        page = p;
        if (email != null) prefillEmail = email;
      });

  @override
  Widget build(BuildContext context) {
    switch (page) {
      case _AuthPage.login:
        return LoginScreen(
          auth: widget.auth,
          initialEmail: prefillEmail,
          onSignUp: () => go(_AuthPage.signUp),
          onForgot: (e) => go(_AuthPage.reset, email: e),
        );
      case _AuthPage.signUp:
        return SignUpScreen(auth: widget.auth, onBack: () => go(_AuthPage.login));
      case _AuthPage.reset:
        return ResetScreen(
          auth: widget.auth,
          initialEmail: prefillEmail,
          onBack: () => go(_AuthPage.login),
        );
    }
  }
}

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

Widget _errorBox(String? msg) => msg == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          const Icon(Icons.error_outline, size: 16, color: kInk),
          const SizedBox(width: 6),
          Expanded(
            child: Text(msg,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ]),
      );

Widget _linkText(String text, VoidCallback onTap) => InkWell(
      onTap: onTap,
      child: Text(text,
          style: const TextStyle(
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w700,
              color: kInk)),
    );

/// S2 Log in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.auth,
    required this.onSignUp,
    required this.onForgot,
    this.initialEmail = '',
  });
  final AuthService auth;
  final VoidCallback onSignUp;
  final void Function(String email) onForgot;
  final String initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final email = TextEditingController(text: widget.initialEmail);
  final password = TextEditingController();
  bool hide = true;
  bool busy = false;
  String? emailError;
  String? error;

  Future<void> submit() async {
    setState(() {
      emailError = _emailRe.hasMatch(email.text.trim()) ? null : 'Enter a valid email address.';
      error = null;
    });
    if (emailError != null) return;
    if (password.text.isEmpty) {
      setState(() => error = 'Wrong email or password.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.auth.logIn(email.text, password.text);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Spacing.page, 32, Spacing.page, Spacing.page),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(kLogoAsset, width: 56, height: 56),
            ),
            const SizedBox(height: Spacing.md),
            const Text('Log in',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: kInk)),
            const SizedBox(height: Spacing.xs),
            const Text('Use the email and password you signed up with.',
                style: AppText.muted),
            const SizedBox(height: Spacing.xxl),
            const Text('Email', style: AppText.label),
            const SizedBox(height: Spacing.xs),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(hintText: 'student@sabanciuniv.edu'),
            ),
            _errorBox(emailError),
            const SizedBox(height: Spacing.lg),
            const Text('Password', style: AppText.label),
            const SizedBox(height: Spacing.xs),
            TextField(
              controller: password,
              obscureText: hide,
              onSubmitted: (_) => submit(),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => hide = !hide),
                ),
              ),
            ),
            _errorBox(error),
            const SizedBox(height: Spacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: _linkText('Forgot password?', () => widget.onForgot(email.text)),
            ),
            const SizedBox(height: Spacing.xl),
            FilledButton(
              onPressed: busy ? null : submit,
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Log in'),
            ),
            const SizedBox(height: Spacing.xxxl),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('New here? ', style: AppText.muted),
              _linkText('Create an account', widget.onSignUp),
            ]),
          ],
        ),
      ),
    );
  }
}

/// S3 Sign up.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.auth, required this.onBack});
  final AuthService auth;
  final VoidCallback onBack;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  String? nameErr, emailErr, passErr, confirmErr, formErr;
  bool busy = false;

  Future<void> submit() async {
    setState(() {
      nameErr = name.text.trim().isEmpty ? 'Enter your name.' : null;
      emailErr = _emailRe.hasMatch(email.text.trim()) ? null : 'Enter a valid email address.';
      passErr = password.text.length < 6 ? 'Password must be at least 6 characters.' : null;
      confirmErr = confirm.text != password.text ? "Passwords don't match." : null;
      formErr = null;
    });
    if ([nameErr, emailErr, passErr, confirmErr].any((e) => e != null)) return;
    setState(() => busy = true);
    try {
      await widget.auth.signUp(name.text, email.text, password.text);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => formErr = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Widget _field(String label, TextEditingController c, String? err,
      {bool obscure = false, String? hint, String? helper, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.label),
        const SizedBox(height: Spacing.xs),
        TextField(
          controller: c,
          obscureText: obscure,
          keyboardType: type,
          autocorrect: false,
          decoration: InputDecoration(hintText: hint),
        ),
        if (err != null)
          _errorBox(err)
        else if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(helper, style: const TextStyle(color: kMuted, fontSize: 11)),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: widget.onBack)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Spacing.page, 0, Spacing.page, Spacing.page),
          children: [
            const Text('Create an account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kInk)),
            const SizedBox(height: Spacing.xs),
            const Text('Your tasks, settings and study history are saved to it.',
                style: AppText.muted),
            const SizedBox(height: Spacing.xl),
            _field('Name', name, nameErr, hint: 'Name Surname'),
            _field('Email', email, emailErr,
                hint: 'student@sabanciuniv.edu', type: TextInputType.emailAddress),
            _field('Password', password, passErr,
                obscure: true, helper: 'At least 6 characters'),
            _field('Confirm password', confirm, confirmErr, obscure: true),
            _errorBox(formErr),
            const SizedBox(height: Spacing.md),
            FilledButton(
              onPressed: busy ? null : submit,
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create account'),
            ),
            const SizedBox(height: Spacing.xl),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Already have an account? ', style: AppText.muted),
              _linkText('Log in', widget.onBack),
            ]),
          ],
        ),
      ),
    );
  }
}

/// S4 Reset password.
class ResetScreen extends StatefulWidget {
  const ResetScreen({
    super.key,
    required this.auth,
    required this.onBack,
    this.initialEmail = '',
  });
  final AuthService auth;
  final VoidCallback onBack;
  final String initialEmail;

  @override
  State<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen> {
  late final email = TextEditingController(text: widget.initialEmail);
  String? error;
  String? sentTo;
  bool busy = false;

  Future<void> send() async {
    if (!_emailRe.hasMatch(email.text.trim())) {
      setState(() => error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.auth.sendReset(email.text);
      if (mounted) setState(() => sentTo = email.text.trim());
    } on AuthFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: widget.onBack),
        title: const Text('Reset password',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.page),
          children: [
            const Text("Enter the email you signed up with. We'll send you a link to set a new password.",
                style: AppText.muted),
            const SizedBox(height: Spacing.lg),
            const Text('Email', style: AppText.label),
            const SizedBox(height: Spacing.xs),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(hintText: 'student@sabanciuniv.edu'),
            ),
            _errorBox(error),
            const SizedBox(height: Spacing.lg),
            FilledButton(
              onPressed: busy ? null : send,
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send reset link'),
            ),
            if (sentTo != null) ...[
              const SizedBox(height: Spacing.lg),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSoft,
                  borderRadius: BorderRadius.circular(Spacing.radius),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.mail_outline, size: 18, color: kInk),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Link sent to $sentTo',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: Spacing.xxs),
                      const Text('It can take a few minutes. Check your spam folder too.',
                          style: AppText.label),
                    ]),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: Spacing.xl),
            Center(child: _linkText('Back to log in', widget.onBack)),
          ],
        ),
      ),
    );
  }
}
