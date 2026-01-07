import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:meddiet/constants/api_config.dart';
import 'package:meddiet/constants/api_endpoints.dart';
import 'package:meddiet/screens/main_layout.dart';
import 'package:meddiet/services/auth_service.dart';
import '../constants/app_colors.dart';

class SignInScreen extends StatefulWidget {
  static const String routeName = '/login';
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController resetEmailController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool isLoading = false;
  bool showPassword = false;
  bool isForgotPassword = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    resetEmailController.dispose();
    super.dispose();
  }

  void handleAuth() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        final response = await http.post(
          Uri.parse(ApiConfig.baseUrl + ApiEndpoints.login),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': emailController.text.trim(),
            'password': passwordController.text.trim(),
          }),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          if (!mounted) return;
          
          // Save token and doctor data
          if (data['data'] != null && data['data']['token'] != null) {
            await AuthService.setToken(data['data']['token']);
            await AuthService.setDoctorData(data['data']);
          }

          _showSnackBar("Login successful");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MainLayout(showLoginSuccess: true)),
          );
        } else {
          _showSnackBar(data['message'] ?? "Login failed", isError: true);
        }
      } catch (e) {
        debugPrint('Login Error: $e');
        _showSnackBar("Connection error. Please check your internet.", isError: true);
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void handleForgotPassword() async {
    if (resetEmailController.text.isEmpty) {
      _showSnackBar('Please enter your email');
      return;
    }

    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoading = false);
    
    _showSnackBar("Password reset link sent to your email");
    setState(() => isForgotPassword = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4DB8A8), // Teal
              Color(0xFF7B68B8), // Purple
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative shapes
            Positioned(
              top: -100,
              right: -100,
              child: _buildDecorativeCircle(300, Colors.white.withValues(alpha: 0.1)),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: _buildDecorativeCircle(200, Colors.white.withValues(alpha: 0.1)),
            ),
            
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: isDesktop ? 1000 : size.width * 0.9,
                  height: isDesktop ? 600 : null,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isDesktop ? _buildDesktopContent() : _buildMobileContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildDesktopContent() {
    return Row(
      children: [
        // Left Side: Image & Branding
        Expanded(
          flex: 1,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  "https://images.unsplash.com/photo-1576091160550-2173dba999ef?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80",
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF4DB8A8).withValues(alpha: 0.7),
                    const Color(0xFF7B68B8).withValues(alpha: 0.8),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.health_and_safety, color: Colors.white, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    "MedDiet Admin",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Empowering healthcare with advanced dietary management solutions.",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
        // Right Side: Login/Forgot Form
        Expanded(
          flex: 1,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isForgotPassword 
              ? _buildForgotPasswordForm() 
              : _buildAuthForm(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.health_and_safety, color: Color(0xFF4DB8A8), size: 60),
          const SizedBox(height: 20),
          const Text(
            "MedDiet Admin",
            style: TextStyle(
              color: Color(0xFF4DB8A8),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isForgotPassword 
              ? _buildForgotPasswordForm() 
              : _buildAuthForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthForm() {
    return KeyedSubtree(
      key: const ValueKey('login'),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sign in to access your dashboard",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  controller: emailController,
                  label: "Email Address",
                  icon: Icons.email_outlined,
                  hint: "admin@demo.com",
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please enter your email";
                    if (!value.contains('@')) return "Please enter a valid email";
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: passwordController,
                  label: "Password",
                  icon: Icons.lock_outline,
                  hint: "••••••••",
                  isPassword: true,
                  showPassword: showPassword,
                  onPasswordToggle: () => setState(() => showPassword = !showPassword),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please enter your password";
                    if (value.length < 6) return "Password must be at least 6 characters";
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => isForgotPassword = true),
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Color(0xFF4DB8A8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4DB8A8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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

  Widget _buildForgotPasswordForm() {
    return KeyedSubtree(
      key: const ValueKey('forgot'),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Forgot Password",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your email to receive a reset link",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              _buildTextField(
                controller: resetEmailController,
                label: "Email Address",
                icon: Icons.email_outlined,
                hint: "Enter your registered email",
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter your email";
                  if (!value.contains('@')) return "Please enter a valid email";
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleForgotPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4DB8A8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Send Reset Link",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => isForgotPassword = false),
                  icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF4DB8A8)),
                  label: const Text(
                    "Back to Login",
                    style: TextStyle(
                      color: Color(0xFF4DB8A8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onPasswordToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !showPassword,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF4DB8A8), size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: onPasswordToggle,
                  )
                : null,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4DB8A8), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 12, color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

