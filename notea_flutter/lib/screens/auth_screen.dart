import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/database_manager.dart';
import '../theme/app_theme.dart';

/// Port of AuthenticationView.swift (shown as a sheet).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool isSignUp = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _handleAuthentication() async {
    setState(() => isLoading = true);
    final db = context.read<DatabaseManager>();
    try {
      if (isSignUp) {
        await db.signUp(_email.text.trim(), _password.text);
      } else {
        await db.signIn(_email.text.trim(), _password.text);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    }
    if (mounted) setState(() => isLoading = false);
  }

  InputDecoration _field(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || _email.text.isEmpty || _password.text.isEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/images/notea_logo.png', width: 100, height: 100),
            ),
            const SizedBox(height: 20),
            const Text('Welcome to Notea',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(isSignUp ? 'Create your account' : 'Sign in to continue',
                style: const TextStyle(fontSize: 15, color: IOSColors.gray)),
            const SizedBox(height: 20),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: _field('Email'),
            ),
            const SizedBox(height: 15),
            TextField(controller: _password, obscureText: true, decoration: _field('Password')),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NC.plum,
                  disabledBackgroundColor: IOSColors.gray,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: disabled ? null : _handleAuthentication,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isSignUp ? 'Sign Up' : 'Sign In'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => isSignUp = !isSignUp),
              child: Text(
                isSignUp ? 'Already have an account? Sign In' : "Don't have an account? Sign Up",
                style: const TextStyle(fontSize: 13, color: NC.plum),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue without account',
                  style: TextStyle(fontSize: 13, color: IOSColors.gray)),
            ),
          ],
        ),
      ),
    );
  }
}
