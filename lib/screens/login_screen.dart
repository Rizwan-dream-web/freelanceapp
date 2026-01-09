import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withOpacity(0.05),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     // 1. Brand Identity
                     const Spacer(flex: 2),
                     Hero(
                       tag: 'app_logo',
                       child: Container(
                         padding: const EdgeInsets.all(20),
                         decoration: BoxDecoration(
                           color: Colors.white,
                           shape: BoxShape.circle,
                           boxShadow: [
                             BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 40, spreadRadius: 10),
                           ],
                         ),
                         child: Image.asset('assets/images/logo.png', width: 80, height: 80),
                       ),
                     ),
                     const SizedBox(height: 30),
                     Text(
                       'COMMAND CENTER',
                       style: GoogleFonts.poppins(
                         fontSize: 24,
                         fontWeight: FontWeight.bold,
                         letterSpacing: 4,
                         color: isDark ? Colors.white : Colors.black87,
                       ),
                     ),
                     const SizedBox(height: 10),
                     Text(
                       'Your Agency, Everywhere.',
                       style: GoogleFonts.poppins(
                         fontSize: 14,
                         color: Colors.grey,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                     
                     const Spacer(flex: 1),
                     
                     // 2. Trust Message
                     Container(
                       padding: const EdgeInsets.all(20),
                       decoration: BoxDecoration(
                         color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                         borderRadius: BorderRadius.circular(20),
                       ),
                       child: Column(
                         children: [
                           Icon(Icons.lock_person_outlined, color: primaryColor, size: 28),
                           const SizedBox(height: 12),
                           Text(
                             'Your data stays safe on your device.',
                             textAlign: TextAlign.center,
                             style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                           ),
                           const SizedBox(height: 4),
                           Text(
                             'Login is only used to sync your data across devices.',
                             textAlign: TextAlign.center,
                             style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                           ),
                         ],
                       ),
                     ),

                    const SizedBox(height: 40),

                    // 3. Action Buttons
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else ...[
                      _buildLoginButton(
                         context,
                         label: 'Continue with Google',
                         icon: Icons.g_mobiledata,
                         isPrimary: true,
                         onTap: () async {
                           setState(() => _isLoading = true);
                           HapticService.medium();
                           final result = await _auth.signInWithGoogle();
                           if (mounted) {
                             setState(() => _isLoading = false);
                             if (result['success'] != true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['error'] ?? 'Sign-in failed'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                             }
                           }
                         },
                       ),
                       const SizedBox(height: 16),
                       _buildLoginButton(
                         context,
                         label: 'Email Login',
                         icon: Icons.email_outlined,
                         isPrimary: false,
                         onTap: () => _showEmailAuthSheet(context),
                       ),
                       const SizedBox(height: 16),
                       _buildLoginButton(
                         context,
                         label: 'Phone Login',
                         icon: Icons.phone_iphone_outlined,
                         isPrimary: false,
                       onTap: () => _showPhoneAuthSheet(context),
                       ),
                     ],

                    const Spacer(flex: 2),
                    // reCAPTCHA safe area / footer clearance
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, {
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : Colors.grey[700], size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isPrimary ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailAuthSheet(BuildContext context) {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AuthBottomSheet(
        title: 'Email Login',
        child: _EmailForm(),
      ),
    );
  }

  void _showPhoneAuthSheet(BuildContext context) {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AuthBottomSheet(
        title: 'Phone Login',
        child: _PhoneForm(),
      ),
    );
  }
}

class _AuthBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _AuthBottomSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 30,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Enter your details for secure access.', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 30),
          child,
        ],
      ),
    );
  }
}

class _EmailForm extends StatefulWidget {
  @override
  State<_EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends State<_EmailForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isRegister) ...[
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () async {
              setState(() => _isLoading = true);
              final auth = AuthService();
              final result = _isRegister
                  ? await auth.registerWithEmail(
                      _emailController.text,
                      _passwordController.text,
                      _nameController.text,
                    )
                  : await auth.signInWithEmail(
                      _emailController.text,
                      _passwordController.text,
                    );
              
              if (mounted) {
                if (result['success'] == true) {
                  if (result['needsVerification'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verification email sent! Please check your inbox and then login.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  Navigator.pop(context);
                } else {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['needsVerification'] == true
                          ? 'Please verify your email. We have sent you a new verification link.'
                          : (result['error'] ?? 'Authentication failed'),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_isRegister ? 'Create Account' : 'Login Now', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _isRegister = !_isRegister),
          child: Text(_isRegister ? 'Already have an account? Login' : 'Need an account? Register'),
        ),
      ],
    );
  }
}

class _PhoneForm extends StatefulWidget {
  @override
  State<_PhoneForm> createState() => _PhoneFormState();
}

class _PhoneFormState extends State<_PhoneForm> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId;
  bool _isLoading = false;
  bool _codeSent = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_codeSent) ...[
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+91 98765 43210',
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                final auth = AuthService();
                await auth.verifyPhone(
                  phoneNumber: _phoneController.text,
                  verificationCompleted: (cred) async {
                    final result = await auth.signInWithPhoneCredential(cred);
                    if (mounted && result['success'] == true) {
                      Navigator.pop(context);
                    }
                  },
                  verificationFailed: (e) {
                     if (mounted) {
                       setState(() => _isLoading = false);
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                           content: Text('Verification failed: ${e.message}'),
                           behavior: SnackBarBehavior.floating,
                         ),
                       );
                     }
                  },
                  codeSent: (vid, resend) {
                    if (mounted) {
                      setState(() {
                        _verificationId = vid;
                        _codeSent = true;
                        _isLoading = false;
                      });
                    }
                  },
                  codeAutoRetrievalTimeout: (vid) {
                    if (mounted) {
                      setState(() => _verificationId = vid);
                    }
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Send Verification Code', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ),
        ] else ...[
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Enter OTP',
              prefixIcon: const Icon(Icons.sms_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                final auth = AuthService();
                final cred = PhoneAuthProvider.credential(
                  verificationId: _verificationId!,
                  smsCode: _otpController.text,
                );
                final result = await auth.signInWithPhoneCredential(cred);
                
                if (mounted) {
                  if (result['success'] == true) {
                    Navigator.pop(context);
                  } else {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['error'] ?? 'Invalid OTP')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Verify & Continue', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
    );
  }
}
