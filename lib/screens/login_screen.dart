import 'package:flutter/material.dart';
import 'package:grocermate/screens/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Login successful! Welcome back.'),
              backgroundColor: Colors.green[600],
            ),
          );
          // Navega para a home e remove a tela de login da pilha.
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('An unexpected error occurred.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/images/loginbackground.avif'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value * 50),
                  child: Opacity(
                    opacity: 1 - _slideAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo e título modernos
                            Image.asset(
                              'lib/assets/images/grocermatelogo.png',
                              height: 200,
                              width: 200,
                            ),
                            const SizedBox(height: 24),
                            
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.white, Color(0xFF81C784)],
                              ).createShader(bounds),
                              child: const Text(
                                'GrocerMate',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            Text(
                              'Welcome back! Sign in to continue',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w300,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),

                            // Container para os campos de input
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Campo de email moderno
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.all(16),
                                        labelStyle: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Campo de senha moderno
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _passwordController,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: Icon(
                                          Icons.lock_outline,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Colors.grey[600],
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible = !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.all(16),
                                        labelStyle: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      obscureText: !_isPasswordVisible,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Botão de login moderno
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF81C784), Color(0xFF388E3C)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF388E3C).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Link para criar conta
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => SignUpScreen(onSignUp: () {
                                            // TODO: Handle successful sign-up navigation
                                            Navigator.of(context).pop(); // Volta para a tela de login por enquanto
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Account created successfully! Please sign in.')),
                                            );
                                          }),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        text: "Don't have an account? ",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Sign Up',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
