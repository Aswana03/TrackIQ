
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../navigation/main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isCreatingAccount = false;

  static bool _googleInitialized = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ==========================================
  // COMMON FUNCTIONS
  // ==========================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigation(),
      ),
    );
  }

  // ==========================================
  // EMAIL / PASSWORD LOGIN
  // ==========================================

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-not-found':
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password authentication is not enabled.';
          break;
        default:
          message = e.message ?? 'Login failed. Please try again.';
      }

      _showMessage(message);
      debugPrint('Login error: ${e.code} ${e.message}');
    } catch (e) {
      debugPrint('Login error: $e');
      _showMessage('An unexpected error occurred.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================
  // CREATE NEW ACCOUNT
  // ==========================================

  Future<void> _createAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Please fill in all the fields.');
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Password must contain at least 6 characters.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      _showMessage('Account created successfully!');
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Please choose a stronger password.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password registration is not enabled.';
          break;
        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';
          break;
        default:
          message = e.message ?? 'Account creation failed.';
      }

      _showMessage(message);
      debugPrint('Registration error: ${e.code} ${e.message}');
    } catch (e) {
      debugPrint('Registration error: $e');
      _showMessage('An unexpected error occurred.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================
  // FORGOT PASSWORD
  // ==========================================

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Enter your email address first.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      _showMessage(
        'Password reset link sent. Check your email.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.code}');
      _showMessage(
        e.message ?? 'Could not send password reset email.',
      );
    } catch (e) {
      debugPrint('Password reset error: $e');
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================
  // GOOGLE SIGN-IN
  // ==========================================

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final googleSignIn = GoogleSignIn.instance;

      if (!_googleInitialized) {
        await googleSignIn.initialize();
        _googleInitialized = true;
      }

      final googleUser = await googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;

      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Google ID token was not received.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      if (!mounted) return;

      _showMessage('Google sign-in successful!');
      _navigateToHome();
    } on GoogleSignInException catch (e) {
      debugPrint(
        'Google Sign-In error: ${e.code} ${e.description}',
      );

      _showMessage(
        e.code == GoogleSignInExceptionCode.canceled
            ? 'Google sign-in cancelled.'
            : 'Google sign-in failed: ${e.description ?? e.code.name}',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase Google authentication error: ${e.code}',
      );

      _showMessage(
        e.message ?? 'Firebase authentication failed.',
      );
    } catch (e) {
      debugPrint('Google Sign-In error: $e');

      _showMessage(
        'Unable to sign in with Google. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================
  // BUILD UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            child: Column(
              children: [
                // APP LOGO
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 28),

                // TITLE
                Text(
                  _isCreatingAccount
                      ? 'Create Account'
                      : 'Welcome Back',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _isCreatingAccount
                      ? 'Create your TrackIQ account to get started.'
                      : 'Log in to continue to TrackIQ.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 32),

                // EMAIL
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 14),

                // PASSWORD
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),

                // CONFIRM PASSWORD
                if (_isCreatingAccount) ...[
                  const SizedBox(height: 14),

                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                ],

                // FORGOT PASSWORD
                if (!_isCreatingAccount)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed:
                          _isLoading ? null : _forgotPassword,
                      child: const Text('Forgot Password?'),
                    ),
                  ),

                const SizedBox(height: 12),

                // LOGIN / SIGN-UP BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_isCreatingAccount
                            ? _createAccount
                            : _login),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isCreatingAccount
                                ? 'Create Account'
                                : 'Log in',
                            style: AppTextStyles.button,
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // SWITCH LOGIN / SIGN-UP
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isCreatingAccount =
                                !_isCreatingAccount;

                            _passwordController.clear();
                            _confirmPasswordController.clear();
                          });
                        },
                  child: Text(
                    _isCreatingAccount
                        ? 'Already have an account? Log in'
                        : "Don't have an account? Sign up",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // OR DIVIDER
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 12),

                // GOOGLE SIGN-IN BUTTON
                OutlinedButton.icon(
                  onPressed:
                      _isLoading ? null : _googleSignIn,
                  icon: const Icon(
                    Icons.g_mobiledata,
                    size: 28,
                  ),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      48,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
