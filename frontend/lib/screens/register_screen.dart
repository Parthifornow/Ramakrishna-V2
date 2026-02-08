import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _designationController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showOtpField = false;
  bool _phoneVerified = false;
  bool _isSendingOtp = false;
  
  String _userType = 'student';
  String? _selectedClass;
  String? _selectedSection;
  List<String> _selectedSubjects = [];
  
  String? _verificationId;
  String _lastVerifiedPhone = '';
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  final List<String> _classes = ['6', '7', '8', '9', '10', '11', '12'];
  final List<String> _sections = ['A', 'B', 'C', 'D'];
  final List<String> _subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'Hindi',
    'Computer Science',
    'History',
    'Geography',
    'Economics',
  ];

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneNumberChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneNumberChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _rollNumberController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  void _onPhoneNumberChanged() {
    final currentPhone = _phoneController.text.trim();
    
    if (_phoneVerified && currentPhone != _lastVerifiedPhone) {
      setState(() {
        _phoneVerified = false;
        _showOtpField = false;
        _verificationId = null;
        _otpController.clear();
      });
      
      if (currentPhone.isNotEmpty && currentPhone.length == 10) {
        _showInfoSnackbar('Phone number changed. Please verify the new number.');
      }
    }
  }

  Future<void> _sendOTP() async {
    if (_nameController.text.trim().length < 3) {
      _showErrorSnackbar('Name must be at least 3 characters');
      return;
    }
    
    if (_phoneController.text.trim().length != 10) {
      _showErrorSnackbar('Please enter a valid 10-digit phone number');
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      final phoneNumber = '+91${_phoneController.text.trim()}';
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
          try {
            await _verifyCredentialSafely(credential);
          } catch (e) {
            setState(() => _isSendingOtp = false);
          }
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          setState(() => _isSendingOtp = false);
          
          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many attempts. Try later';
          } else if (e.message != null) {
            errorMessage = e.message!;
          }
          
          _showErrorSnackbar(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _showOtpField = true;
            _isSendingOtp = false;
          });
          _showSuccessSnackbar('OTP sent successfully!');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _verificationId = verificationId);
        },
      );
    } catch (e) {
      setState(() => _isSendingOtp = false);
      _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().length != 6) {
      _showErrorSnackbar('Please enter 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      
      await _verifyCredentialSafely(credential);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Invalid OTP. Please try again.');
    }
  }

  Future<void> _verifyCredentialSafely(firebase_auth.PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await _auth.signOut();

        setState(() {
          _phoneVerified = true;
          _lastVerifiedPhone = _phoneController.text.trim();
          _isLoading = false;
          _showOtpField = false;
          _otpController.clear();
        });
        
        _showSuccessSnackbar('Phone verified successfully!');
      } else {
        throw Exception('Verification failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('List<Object?>')) {
        setState(() {
          _phoneVerified = true;
          _lastVerifiedPhone = _phoneController.text.trim();
          _showOtpField = false;
          _otpController.clear();
        });
        _showSuccessSnackbar('Phone verified successfully!');
      } else {
        _showErrorSnackbar('Verification error. Please try again.');
      }
    }
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_phoneController.text.trim() != _lastVerifiedPhone) {
      _showErrorSnackbar('Phone number was changed. Please verify the new number.');
      return;
    }
    
    if (!_phoneVerified) {
      _showErrorSnackbar('Please verify your phone number first');
      return;
    }

    // Validate user type specific fields
    if (_userType == 'student') {
      if (_selectedClass == null || _selectedSection == null) {
        _showErrorSnackbar('Please select class and section');
        return;
      }
    } else if (_userType == 'staff') {
      if (_designationController.text.trim().isEmpty) {
        _showErrorSnackbar('Please enter designation');
        return;
      }
    }

    setState(() => _isLoading = true);

    final preRegResult = await ApiService.preRegister(
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      userType: _userType,
      className: _selectedClass,
      section: _selectedSection,
      rollNumber: _rollNumberController.text.trim(),
      designation: _designationController.text.trim(),
      subjects: _selectedSubjects,
    );

    if (!preRegResult['success']) {
      setState(() => _isLoading = false);
      _showErrorSnackbar(preRegResult['message']);
      return;
    }

    final result = await ApiService.completeRegistration(
      phoneNumber: _phoneController.text.trim(),
      firebaseUid: 'verified_${_phoneController.text.trim()}',
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      _showSuccessDialog();
    } else {
      _showErrorSnackbar(result['message']);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text('Success!', textAlign: TextAlign.center),
          ],
        ),
        content: const Text(
          'Your account has been created successfully.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('GO TO LOGIN', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.person_add, size: 80, color: Colors.blue),
                  const SizedBox(height: 20),
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign up to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  
                  // User Type Selection
                  const Text('I am a:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Student'),
                          value: 'student',
                          groupValue: _userType,
                          onChanged: (value) {
                            setState(() => _userType = value!);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Staff'),
                          value: 'staff',
                          groupValue: _userType,
                          onChanged: (value) {
                            setState(() => _userType = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your name';
                      if (value.trim().length < 3) return 'Name must be at least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone Number Field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone),
                      suffixIcon: _phoneVerified 
                        ? const Icon(Icons.verified, color: Colors.green)
                        : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your phone number';
                      if (value.length != 10) return 'Phone number must be 10 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Verify Phone Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: (_phoneVerified && _phoneController.text.trim() == _lastVerifiedPhone) || _isSendingOtp 
                        ? null 
                        : _sendOTP,
                      child: _isSendingOtp
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Sending OTP...'),
                              ],
                            )
                          : Text(
                              (_phoneVerified && _phoneController.text.trim() == _lastVerifiedPhone)
                                ? 'Phone Verified ✓' 
                                : 'Verify Phone Number',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: (_phoneVerified && _phoneController.text.trim() == _lastVerifiedPhone)
                                  ? Colors.green 
                                  : Colors.blue,
                              ),
                            ),
                    ),
                  ),
                  
                  // OTP Field
                  if (_showOtpField && !_phoneVerified) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Enter OTP',
                              prefixIcon: const Icon(Icons.sms),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOTP,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Verify'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Student-specific fields
                  if (_userType == 'student') ...[
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Class',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            value: _selectedClass,
                            items: _classes.map((c) => DropdownMenuItem(value: c, child: Text('Class $c'))).toList(),
                            onChanged: (value) => setState(() => _selectedClass = value),
                            validator: (value) => value == null ? 'Please select class' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Section',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            value: _selectedSection,
                            items: _sections.map((s) => DropdownMenuItem(value: s, child: Text('Section $s'))).toList(),
                            onChanged: (value) => setState(() => _selectedSection = value),
                            validator: (value) => value == null ? 'Please select section' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _rollNumberController,
                      decoration: InputDecoration(
                        labelText: 'Roll Number (Optional)',
                        prefixIcon: const Icon(Icons.numbers),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Staff-specific fields
                  if (_userType == 'staff') ...[
                    TextFormField(
                      controller: _designationController,
                      decoration: InputDecoration(
                        labelText: 'Designation',
                        prefixIcon: const Icon(Icons.work),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter designation' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Subjects (Optional):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _subjects.map((subject) {
                        final isSelected = _selectedSubjects.contains(subject);
                        return FilterChip(
                          label: Text(subject),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSubjects.add(subject);
                              } else {
                                _selectedSubjects.remove(subject);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Password Fields
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter password';
                      if (value.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please confirm password';
                      if (value != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Register Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _completeRegistration,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('REGISTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? '),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
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