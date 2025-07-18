import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/theme.dart';
import '../../../core/providers/providers.dart';
import '../../../domain/entities/user.dart';
import '../../patient/patient_home_screen.dart';
import '../../specialist/specialist_dashboard_screen.dart';
import 'patient_login_screen.dart';
import '../../../data/models/user_model.dart';

class PatientRegisterScreen extends ConsumerStatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  ConsumerState<PatientRegisterScreen> createState() =>
      _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends ConsumerState<PatientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _serialNumberController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  FlutterTts? _flutterTts;
  List<UserModel> _doctors = [];
  String? _selectedDoctorId;
  bool _loadingDoctors = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchDoctors();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts!.setLanguage('en-US');
    await _flutterTts!.setSpeechRate(0.8);
    await _flutterTts!.setVolume(1.0);

    await _flutterTts!.speak(
      'Patient registration screen. Please fill in your details.',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _serialNumberController.dispose();
    _flutterTts?.stop();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _loadingDoctors = true;
    });
    try {
      final apiService = ref.read(apiServiceProvider);
      final doctors = await apiService.getDoctors();
      setState(() {
        _doctors = doctors;
        if (_doctors.isNotEmpty) {
          _selectedDoctorId = _doctors.first.id;
        }
      });
    } catch (e) {
      // Optionally show error
    } finally {
      setState(() {
        _loadingDoctors = false;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await _flutterTts?.speak('Creating account...');

    // Test backend connection first
    try {
      final apiService = ref.read(apiServiceProvider);
      print('🔗 Testing backend connection...');
      final isConnected = await apiService.testConnection();
      if (!isConnected) {
        throw Exception('Cannot connect to backend server');
      }
      print('✅ Backend connection successful');
    } catch (e) {
      print('❌ Backend connection failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backend connection failed: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmationPassword: _confirmPasswordController.text,
      role: 'patient',
      serialNumber: _serialNumberController.text.trim(),
    );
  }

  // Test backend connectivity
  Future<void> _testBackend() async {
    try {
      await _flutterTts?.speak('Testing backend connection...');
      final apiService = ref.read(apiServiceProvider);

      print('🔗 Testing backend URL: ${apiService.baseUrl}');
      final isConnected = await apiService.testConnection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isConnected
                  ? '✅ Backend connected successfully!'
                  : '❌ Backend connection failed',
            ),
            backgroundColor: isConnected ? Colors.green : AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      await _flutterTts?.speak(
        isConnected
            ? 'Backend connected successfully'
            : 'Backend connection failed',
      );
    } catch (e) {
      print('❌ Backend test error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Backend test failed: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Comprehensive API integration test
  Future<void> _testAPIIntegration() async {
    try {
      await _flutterTts?.speak('Testing complete API integration...');
      final apiService = ref.read(apiServiceProvider);

      final testResults = await apiService.testAPIIntegration();

      final success =
          testResults['connectivity'] == true &&
          testResults['status'] == 'completed';

      if (mounted) {
        // Show detailed results in a dialog
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  success ? '✅ API Test Results' : '❌ API Test Results',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Base URL: ${testResults['base_url']}'),
                      const SizedBox(height: 8),
                      Text(
                        'Connectivity: ${testResults['connectivity'] ? 'Success' : 'Failed'}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Registration Test: ${testResults['registration_test']}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Audio Endpoints: ${testResults['audio_endpoints']}',
                      ),
                      if (testResults['error'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${testResults['error']}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      }

      await _flutterTts?.speak(
        success
            ? 'API integration test completed successfully'
            : 'API integration test failed',
      );
    } catch (e) {
      print('❌ API integration test error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ API test failed: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            if (user.isPatient) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientHomeScreen(),
                ),
                (route) => false,
              );
            } else if (user.isSpecialist) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const SpecialistDashboardScreen(),
                ),
                (route) => false,
              );
            }
          }
        },
        loading: () {},
        error: (error, stack) {
          _flutterTts?.speak('Registration failed. Please try again.');

          final errorMessage = error.toString();

          // Check if it's a duplicate registration error
          if (errorMessage.contains('email is already registered') ||
              errorMessage.contains('Email already exists')) {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Email Already Registered'),
                    content: const Text(
                      'This email is already registered. Would you like to log in instead?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PatientLoginScreen(),
                            ),
                          );
                        },
                        child: const Text('Go to Login'),
                      ),
                    ],
                  ),
            );
          } else if (errorMessage.contains('serial number is already in use') ||
              errorMessage.contains('serial number used by another user')) {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Serial Number Already Used'),
                    content: const Text(
                      'This serial number is already registered to another user. Please check your device serial number or contact support.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Registration failed: $errorMessage'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      );
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.text,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                ClipOval(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/image.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  'Create',
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Account',
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Register as Patient',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.subtitle,
                  ),
                ),

                const SizedBox(height: 32),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                          decoration: AppTheme.inputDecoration(
                            hintText: 'Full Name',
                            icon: Icons.person_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                          decoration: AppTheme.inputDecoration(
                            hintText: 'Email',
                            icon: Icons.email_outlined,
                          ),
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

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                          decoration: AppTheme.inputDecoration(
                            hintText: 'Password',
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textLight,
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                          decoration: AppTheme.inputDecoration(
                            hintText: 'Confirm Password',
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textLight,
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: TextFormField(
                          controller: _serialNumberController,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                          decoration: AppTheme.inputDecoration(
                            hintText: 'Glasses Serial Number',
                            icon: Icons.qr_code_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your glasses serial number';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 40),

                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.buttonShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _register,
                          style: AppTheme.primaryButtonStyle,
                          child:
                              authState.isLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'Register',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textLight,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const PatientLoginScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Login',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 60),
                    ],
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
