import 'package:flutter/material.dart';


import '../components/qp_button.dart';
import '../components/qp_text_field.dart';
import 'otp_verification_page.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  
  // Development mode flag
  static const bool _isDevelopmentMode = true;
  static const String _testOTP = '123456';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      String phoneNumber = _phoneController.text.trim();
      
      // Ensure phone number has India country code (+91)
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+91$phoneNumber';
      }
      
      // DEVELOPMENT MODE - Simulate OTP sending without Firebase
      if (_isDevelopmentMode) {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 2));
        
        setState(() => _isLoading = false);
        _showSnackbar('🔥 DEV MODE: OTP sent! Use: $_testOTP', isError: false);
        
        // Navigate to OTP verification page with mock verification ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              verificationId: 'DEV_MODE_${DateTime.now().millisecondsSinceEpoch}',
              phoneNumber: phoneNumber,
              resendToken: null,
            ),
          ),
        );
        return;
      }
      
      // PRODUCTION MODE - Firebase Phone Auth (commented out for development)
      /*
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          await FirebaseAuth.instance.signInWithCredential(credential);
          setState(() => _isLoading = false);
          Navigator.pushReplacementNamed(context, '/home');
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          String message = 'Verification failed. Please try again.';
          if (e.code == 'invalid-phone-number') {
            message = 'The phone number entered is invalid.';
          } else if (e.code == 'too-many-requests') {
            message = 'Too many attempts. Please try again later.';
          } else if (e.code == 'quota-exceeded') {
            message = 'SMS quota exceeded. Please try again later.';
          }
          _showSnackbar(message);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          _showSnackbar('OTP sent successfully!', isError: false);
          
          // Navigate to OTP verification page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationPage(
                verificationId: verificationId,
                phoneNumber: phoneNumber,
                resendToken: resendToken,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
        },
        timeout: const Duration(seconds: 60),
      );
      */
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Failed to send OTP. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF001524), const Color(0xFF15616D)]
                : [const Color(0xFF74F9FF), const Color(0xFF38A3A5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              child: Card(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ShaderMask(
                                shaderCallback: (r) => LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary
                                  ],
                                ).createShader(r),
                                child: const Icon(
                                  Icons.phone_android_rounded,
                                  size: 68,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Phone Verification',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Enter your phone number to receive\na verification code',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Form Section
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            QPTextField(
                              controller: _phoneController,
                              label: 'Phone Number (+91)',
                              icon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              autofocus: true,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter your phone number';
                                }
                                // Indian phone number validation (10 digits)
                                String phoneNumber = value.replaceAll(RegExp(r'[^\d]'), '');
                                if (phoneNumber.length != 10) {
                                  return 'Enter a valid 10-digit number';
                                }
                                if (!phoneNumber.startsWith(RegExp(r'[6-9]'))) {
                                  return 'Enter a valid Indian mobile number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Enter 10-digit mobile number (e.g., 9876543210)',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  if (_isDevelopmentMode) const SizedBox(height: 4),
                                  if (_isDevelopmentMode)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.orange.withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '🔥 DEV MODE: OTP will be $_testOTP',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            QPButton(
                              label: 'Send OTP',
                              loading: _isLoading,
                              onPressed: _sendOTP,
                              icon: Icons.send_rounded,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Footer Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      
                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Alternative login button
                      QPButton(
                        label: 'Continue with Email',
                        filled: false,
                        icon: Icons.email_outlined,
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
