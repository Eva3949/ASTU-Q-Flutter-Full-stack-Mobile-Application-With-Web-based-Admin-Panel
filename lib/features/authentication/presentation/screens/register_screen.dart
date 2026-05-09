import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/authentication_provider.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/modern_dialog.dart';

/// Register Screen
/// Modern registration interface with comprehensive validation
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isCheckingUsername = false;
  String? _usernameError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(188, 105, 73, 167),
              const Color.fromARGB(188, 105, 73, 167).withOpacity(0.9),
              Colors.white,
            ],
            stops: [0.0, 0.4, 0.4],
          ),
        ),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Consumer<AuthenticationProvider>(
                builder: (context, authProvider, child) {
                  return _buildBody(context, authProvider);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AuthenticationProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        _buildHeader(),
        SizedBox(height: 32),
        _buildRegisterForm(context, authProvider),
        SizedBox(height: 24),
        _buildTermsCheckbox(),
        SizedBox(height: 32),
        _buildRegisterButton(context, authProvider),
        SizedBox(height: 32),
        _buildDivider(),
        SizedBox(height: 32),
        _buildLoginLink(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Icon with modern design
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Icon(Icons.person_add_rounded, color: Colors.white, size: 45),
        ),
        SizedBox(height: 32),

        // Welcome Text
        Text(
          'Create Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Join ASTU-Q community and start solving doubts',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(
    BuildContext context,
    AuthenticationProvider authProvider,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Name Fields Row
          Row(
            children: [
              // First Name
              Expanded(
                child: CustomTextField(
                  controller: _firstNameController,
                  labelText: 'First Name',
                  hintText: 'Enter first name',
                  keyboardType: TextInputType.name,
                  prefixIcon: Icons.person_rounded,
                  validator: _validateFirstName,
                  textInputAction: TextInputAction.next,
                ),
              ),
              SizedBox(width: 16),
              // Last Name
              Expanded(
                child: CustomTextField(
                  controller: _lastNameController,
                  labelText: 'Last Name',
                  hintText: 'Enter last name',
                  keyboardType: TextInputType.name,
                  prefixIcon: Icons.person_rounded,
                  validator: _validateLastName,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Username Field
          CustomTextField(
            controller: _usernameController,
            labelText: 'Username',
            hintText: 'Enter username',
            keyboardType: TextInputType.text,
            prefixIcon: Icons.alternate_email_rounded,
            validator: _validateUsername,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              if (_usernameError != null) {
                setState(() {
                  _usernameError = null;
                });
              }
            },
          ),
          if (_usernameError != null) ...[
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                _usernameError!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.errorColor,
                ),
              ),
            ),
          ],
          SizedBox(height: 20),

          // Email Field
          CustomTextField(
            controller: _emailController,
            labelText: 'Email Address',
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_rounded,
            validator: _validateEmail,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 20),

          // Password Field
          CustomTextField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Create a strong password',
            obscureText: !_isPasswordVisible,
            prefixIcon: Icons.lock_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            validator: _validatePassword,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 20),

          // Confirm Password Field
          CustomTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            hintText: 'Confirm your password',
            obscureText: !_isConfirmPasswordVisible,
            prefixIcon: Icons.lock_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            validator: _validateConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleRegister(context, authProvider),
          ),

          // Password Requirements
          _buildPasswordRequirements(),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.infoColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: AppTextStyles.bodyText2.copyWith(
              color: Color.fromARGB(188, 105, 73, 167),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          ..._getPasswordRequirements().map(
            (requirement) => Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    _isPasswordValid(requirement['pattern']!)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: _isPasswordValid(requirement['pattern']!)
                        ? AppColors.successColor
                        : AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      requirement['text']!,
                      style: AppTextStyles.caption.copyWith(
                        color: _isPasswordValid(requirement['pattern']!)
                            ? AppColors.successColor
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getPasswordRequirements() {
    return [
      {'text': 'At least 8 characters', 'pattern': r'.{8,}'},
      {'text': 'Contains uppercase letter', 'pattern': r'[A-Z]'},
      {'text': 'Contains lowercase letter', 'pattern': r'[a-z]'},
      {'text': 'Contains number', 'pattern': r'[0-9]'},
      {
        'text': 'Contains special character',
        'pattern': r'[!@#$%^&*(),.?":{}|<>]',
      },
    ];
  }

  bool _isPasswordValid(String pattern) {
    if (_passwordController.text.isEmpty) return false;
    return RegExp(pattern).hasMatch(_passwordController.text);
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() {
              _agreeToTerms = value ?? false;
            });
          },
          activeColor: const Color.fromARGB(188, 105, 73, 167),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: const Color.fromARGB(188, 105, 73, 167),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: const Color.fromARGB(188, 105, 73, 167),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(
    BuildContext context,
    AuthenticationProvider authProvider,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Consumer<AuthenticationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingWidget();
          }

          return CustomButton(
            text: 'Create Account',
            onPressed: _agreeToTerms
                ? () => _handleRegister(context, authProvider)
                : null,
            isLoading: _isLoading,
            isEnabled: _agreeToTerms,
            backgroundColor: AppColors.primaryColor,
            textColor: Colors.white,
            borderRadius: 12,
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.dividerColor, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: AppTextStyles.bodyText2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.dividerColor, thickness: 1)),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: AppTextStyles.bodyText2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: _handleLogin,
          child: Text(
            'Sign In',
            style: AppTextStyles.bodyText2.copyWith(
              color: Color.fromARGB(188, 105, 73, 167),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Form Validators
  String? _validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your first name';
    }

    if (value.length < 2) {
      return 'First name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'First name must not exceed 50 characters';
    }

    // Name validation - letters and spaces only
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'First name can only contain letters';
    }

    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your last name';
    }

    if (value.length < 2) {
      return 'Last name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Last name must not exceed 50 characters';
    }

    // Name validation - letters and spaces only
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Last name can only contain letters';
    }

    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }

    // Username validation: alphanumeric, underscores, and hyphens only
    // Must be 3-20 characters
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (value.length > 20) {
      return 'Username must not exceed 20 characters';
    }

    // Only allow letters, numbers, underscores, and hyphens
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, underscores, and hyphens';
    }

    // Cannot start with a number or special character
    if (RegExp(r'^[0-9_-]').hasMatch(value)) {
      return 'Username must start with a letter';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }

    // Email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (value.length > 128) {
      return 'Password must not exceed 128 characters';
    }

    // Check all password requirements
    final requirements = _getPasswordRequirements();
    for (final requirement in requirements) {
      if (!RegExp(requirement['pattern']!).hasMatch(value)) {
        return 'Password does not meet all requirements';
      }
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Event Handlers
  Future<void> _handleRegister(
    BuildContext context,
    AuthenticationProvider authProvider,
  ) async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check terms agreement
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the terms and conditions'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Perform registration through provider
    final success = await authProvider.register(
      name:
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (success && mounted) {
      _showSuccessDialog(context);
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _showSuccessDialog(BuildContext context) {
    ModernDialog.showSuccess(
      context: context,
      title: 'Registration Successful!',
      message:
          'Your account has been created successfully. Please check your email to verify your account.\n\nEmail: ${_emailController.text}',
      buttonText: 'Go to Login',
      onButtonPressed: () {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(
          context,
        ).pushReplacementNamed('/login'); // Navigate to login
      },
    );
  }

  void _handleLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }
}

/// Registration Success Dialog Widget
class RegistrationSuccessDialog extends StatelessWidget {
  final String email;
  final VoidCallback onContinue;

  const RegistrationSuccessDialog({
    Key? key,
    required this.email,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.successColor,
                size: 40,
              ),
            ),
            SizedBox(height: 24),

            // Success Message
            Text(
              'Account Created Successfully!',
              textAlign: TextAlign.center,
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Email Info
            Text(
              'We\'ve sent a verification email to:',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                email,
                style: AppTextStyles.bodyText2.copyWith(
                  color: AppColors.infoColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 24),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Continue to Login',
                onPressed: onContinue,
                backgroundColor: AppColors.primaryColor,
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
