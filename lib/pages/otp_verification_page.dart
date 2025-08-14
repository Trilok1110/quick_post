import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';

import '../components/qp_button.dart';

class OTPVerificationPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;

  const OTPVerificationPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage>
    with TickerProviderStateMixin {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isResending = false;
  String? _currentText;
  
  // Development mode flag
  static const bool _isDevelopmentMode = true;
  static const String _testOTP = '123456';
  
  // Timer for resend functionality
  Timer? _timer;
  int _countDown = 60;
  bool _canResend = false;
  
  // Animation controllers
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _setupAnimations();
    
    // Auto-focus on OTP field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _setupAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _startTimer() {
    _canResend = false;
    _countDown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countDown > 0) {
            _countDown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _verifyOTP() async {
    if (_currentText?.length != 6) {
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
      _showSnackbar('Please enter a complete 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    // DEVELOPMENT MODE - Simulate OTP verification
    if (_isDevelopmentMode) {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      if (_currentText == _testOTP) {
        // Success case
        setState(() => _isLoading = false);
        _showSnackbar('🔥 DEV MODE: Phone verification successful!', isError: false);
        
        // Navigate to home page
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        // Invalid OTP case
        setState(() => _isLoading = false);
        
        _shakeController.forward().then((_) {
          _shakeController.reverse();
        });
        
        _showSnackbar('Invalid OTP. Use: $_testOTP');
        
        // Clear the OTP field
        _otpController.clear();
        setState(() => _currentText = '');
      }
      return;
    }

    // PRODUCTION MODE - Firebase Phone Auth (commented out for development)
    /*
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _currentText!,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      
      setState(() => _isLoading = false);
      _showSnackbar('Phone verification successful!', isError: false);
      
      // Navigate to home page
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      
      String message = 'Invalid OTP. Please try again.';
      if (e.code == 'invalid-verification-code') {
        message = 'The verification code is invalid.';
      } else if (e.code == 'session-expired') {
        message = 'The verification session has expired.';
      }
      
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
      
      _showSnackbar(message);
      
      // Clear the OTP field
      _otpController.clear();
      setState(() => _currentText = '');
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Verification failed. Please try again.');
    }
    */
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);

    // DEVELOPMENT MODE - Simulate resend OTP
    if (_isDevelopmentMode) {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() => _isResending = false);
      _showSnackbar('🔥 DEV MODE: OTP resent! Use: $_testOTP', isError: false);
      _startTimer();
      return;
    }

    // PRODUCTION MODE - Firebase resend OTP (commented out for development)
    /*
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isResending = false);
          _showSnackbar('Failed to resend OTP. Please try again.');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isResending = false);
          _showSnackbar('OTP resent successfully!', isError: false);
          _startTimer();
          
          // Update verification ID for the new code
          // Note: In a real app, you might want to create a new instance or update the current one
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        forceResendingToken: widget.resendToken,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => _isResending = false);
      _showSnackbar('Failed to resend OTP. Please try again.');
    }
    */
  }

  String get _maskedPhoneNumber {
    if (widget.phoneNumber.length > 6) {
      return '${widget.phoneNumber.substring(0, 3)}****${widget.phoneNumber.substring(widget.phoneNumber.length - 4)}';
    }
    return widget.phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Verify OTP',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth > 600 ? 40 : 24,
                      vertical: 20,
                    ),
                    child: AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: Card(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                            elevation: 16,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(
                                maxWidth: 450, // Max width for larger screens
                              ),
                              padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Header with icon
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Container(
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
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                                blurRadius: 20,
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
                                              Icons.lock_outline_rounded,
                                              size: 64,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Title and description
                                  Text(
                                    'Enter Verification Code',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: isSmallScreen ? 24 : 28,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'We have sent a 6-digit verification code to',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _maskedPhoneNumber,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 40),
                                  
                                  // OTP Input Field
                                  Container(
                                    child: PinCodeTextField(
                                      appContext: context,
                                      length: 6,
                                      controller: _otpController,
                                      focusNode: _focusNode,
                                      keyboardType: TextInputType.number,
                                      textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: isSmallScreen ? 18 : 24,
                                      ),
                                      pinTheme: PinTheme(
                                        shape: PinCodeFieldShape.box,
                                        borderRadius: BorderRadius.circular(16),
                                        fieldHeight: isSmallScreen ? 50 : 60,
                                        fieldWidth: isSmallScreen ? 40 : 50,
                                        activeFillColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        inactiveFillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                        selectedFillColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                        activeColor: Theme.of(context).colorScheme.primary,
                                        inactiveColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                        selectedColor: Theme.of(context).colorScheme.primary,
                                        borderWidth: 2,
                                        fieldOuterPadding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 2 : 4,
                                        ),
                                      ),
                                      enableActiveFill: true,
                                      cursorColor: Theme.of(context).colorScheme.primary,
                                      animationDuration: const Duration(milliseconds: 300),
                                      animationType: AnimationType.fade,
                                      onChanged: (value) {
                                        setState(() {
                                          _currentText = value;
                                        });
                                      },
                                      onCompleted: (value) {
                                        _currentText = value;
                                        _verifyOTP();
                                      },
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Verify Button
                                  QPButton(
                                    label: 'Verify Code',
                                    loading: _isLoading,
                                    onPressed: _verifyOTP,
                                    icon: Icons.verified_user_rounded,
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Resend section
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        "Didn't receive the code? ",
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                      if (_canResend)
                                        TextButton(
                                          onPressed: _isResending ? null : _resendOTP,
                                          child: _isResending
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Text(
                                                  'Resend',
                                                  style: TextStyle(fontWeight: FontWeight.w600),
                                                ),
                                        )
                                      else
                                        Text(
                                          'Resend in ${_countDown}s',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Change number option
                                  TextButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.edit_rounded, size: 18),
                                    label: const Text(
                                      'Change Phone Number',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
}
