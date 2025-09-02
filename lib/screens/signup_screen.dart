import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback onSignUp;

  const SignUpScreen({super.key, required this.onSignUp});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
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
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {
            'username': _usernameController.text.trim(),
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'phone': _phoneController.text.trim(),
          },
        );

        final user = result.user;

        if (user != null) {
          // O gatilho no Supabase (função handle_new_user) agora cuida da criação do perfil.
          // Este bloco de inserção manual foi removido para evitar conflitos.
        }

        if (mounted) {
          // Se o cadastro precisar de confirmação de e-mail, o usuário não estará logado imediatamente.
          if (user != null) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('You have successfully registered!'),
                backgroundColor: Colors.green[600],
              ),
            );
            // Navega para a home e remove a tela de cadastro da pilha.
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
        }
      } on AuthException catch (e) {
        if (mounted) {
          String message = 'An unexpected error occurred.';
          if (e.message.contains('profiles_username_key')) {
            message = 'This username is already taken. Please choose another one.';
          } else if (e.message.contains('users_email_key')) {
            message = 'This email is already registered. Please log in.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          debugPrint('>>> SUPABASE ERROR: $e');
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Image.asset(
                                'lib/assets/images/grocermatelogo.png',
                                height: 150,
                                width: 150,
                              ),
                              const SizedBox(height: 24),
                              
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Colors.white, Color(0xFF81C784)],
                                ).createShader(bounds),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              Text(
                                'Join GrocerMate today!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w300,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 48),

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
                                    TextFormField(
                                      controller: _usernameController,
                                      maxLength: 15,
                                      decoration: InputDecoration(
                                        labelText: 'Username',
                                        counterText: "", // Oculta o contador
                                        prefixIcon: Icon(
                                          Icons.person_outline,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Please enter a username';
                                        if (value.length < 3) return 'Username must be at least 3 characters';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _firstNameController,
                                            maxLength: 20,
                                            decoration: InputDecoration(
                                              labelText: 'First Name',
                                              counterText: "", // Oculta o contador
                                              prefixIcon: Icon(
                                                Icons.person_outline,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                            textCapitalization: TextCapitalization.words,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) return 'Please enter your first name';
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _lastNameController,
                                            maxLength: 20,
                                            decoration: InputDecoration(
                                              labelText: 'Last Name',
                                              counterText: "", // Oculta o contador
                                              prefixIcon: Icon(
                                                Icons.person_outline,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                            textCapitalization: TextCapitalization.words,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) return 'Please enter your last name';
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _phoneController,
                                      decoration: InputDecoration(
                                        labelText: 'Phone (Optional)',
                                        prefixIcon: Icon(
                                          Icons.phone_outlined,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        MaskTextInputFormatter(
                                          mask: '(##) #####-####', 
                                          filter: { "#": RegExp(r'[0-9]') }
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Please enter your email';
                                        if (!value.contains('@')) return 'Please enter a valid email';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _passwordController,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: Icon(
                                          Icons.lock_outline,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                        ),
                                      ),
                                      obscureText: !_isPasswordVisible,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Please enter a password';
                                        if (value.length < 6) return 'Password must be at least 6 characters';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      decoration: InputDecoration(
                                        labelText: 'Confirm Password',
                                        prefixIcon: Icon(
                                          Icons.lock_outline,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      obscureText: !_isPasswordVisible,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Please confirm your password';
                                        if (value != _passwordController.text) return 'Passwords do not match';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
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
                                        onPressed: _isLoading ? null : _handleSignUp,
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
                                                'Sign Up',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
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
