import 'package:flutter/material.dart';
import 'package:meddiet/screens/main_layout.dart';
import '../constants/app_colors.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;
  bool showEmailField = true;


  // static user
  final String staticEmail = "admin@demo.com";
  final String staticPassword = "123456";

  void handleSignin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoading = false);

    if (emailController.text.trim() == staticEmail && passwordController.text.trim() == staticPassword) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayout(showLoginSuccess: true)),);
    } else {
      _showSnackBar("Incorrect email or password");
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Main UI
        Container( 
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4DB8A8), Color(0xFF7B68B8)],
            ),
          ),
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Ellipse 1 (top-left of container)
              Positioned(
                top: -50, // adjust as needed
                left: -50, // adjust as needed
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x4D1FB198),
                  ),
                ),
              ),
        
              // Ellipse 2 (slightly different position for layering effect)
              Positioned(
                top: 20, // adjust as needed
                left: -40, // adjust as needed
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x4D1FB198),
                  ),
                ),
              ),
              Container(
                width: 1420,
                height: 580,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.black.withOpacity(0.08),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 530.0, right: 530),
                  child: Column(
                    children: [
                      Text(
                        "MedDiet Admin",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        "Healthcare Management System",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w100,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "Welcome Back!",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 32),
                        
                      // Email Fiel
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                      ),
                      const SizedBox(height: 16),
                        
                      // Password Field
                      Visibility(
                        visible: showEmailField,
                        child: TextField(
                          controller: passwordController,
                          obscureText: !showPassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: AppColors.primary, width: 2),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() => showPassword = !showPassword);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                        
                      // Signin Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleSignin,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Sign in"),
                        ),
                      ),
                          const SizedBox(height: 20),

                          // Forgot Password → shows only during login
                          if (showEmailField)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  showEmailField = false; // Hide password field
                                });
                              },
                              child: const Text(
                                "Forgot Password",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ),

                          // Back button → appears only when password is hidden
                          if (!showEmailField)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  showEmailField = true; // Show password field again
                                });
                              },
                              child: const Text(
                                "Back",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                          const SizedBox(height: 95),
                          Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              _showSnackBar('Term of use Coming Soon!');
                              }, 
                            child: Text("Term of use",
                              style: TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),),
                          ),
                          Text(
                            "|",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _showSnackBar('Privacy Policy Coming Soon!');
                              }, 
                            child: Text("Privacy Policy",
                              style: TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
        ),

        // Floating buttons
        Positioned(
          bottom: 105,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  _showSnackBar('Request An Account Coming Soon!');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text("Request An Account"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _showSnackBar('Need Help? Coming Soon!');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: const Text("Need Help?"),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

}
