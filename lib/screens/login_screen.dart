import 'package:flutter/material.dart';
import 'package:listy/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  // A helper function to handle form submission and loading state
  Future<void> _submitForm(Future<void> Function() authAction) async {
    // Validate the form fields
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      try {
        await authAction();
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Listy',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => (value?.isEmpty ?? true) ? 'Please enter an email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) => (value?.length ?? 0) < 6 ? 'Password must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () => _submitForm(() async {
                            final user = await _authService.signInWithEmailAndPassword(
                              _emailController.text,
                              _passwordController.text,
                            );
                            if (user == null && mounted) {
                              setState(() => _errorMessage = 'Could not sign in with those credentials.');
                            }
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => _submitForm(() async {
                            final user = await _authService.registerWithEmailAndPassword(
                              _emailController.text,
                              _passwordController.text,
                            );
                            if (user == null && mounted) {
                              setState(() => _errorMessage = 'Could not create an account. The email might already be in use.');
                            }
                          }),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Sign Up', style: TextStyle(color: Colors.blue, fontSize: 16)),
                        ),
                      ],
                    ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}