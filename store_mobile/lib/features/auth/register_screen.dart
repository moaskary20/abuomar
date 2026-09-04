import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/api_client.dart';
import '../../data/app_state.dart';
import '../../widgets/auth_widgets.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthController>();
    try {
      await auth.register(
        name: _nameController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء الحساب بنجاح', style: AppFonts.tajawal()),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : 'تعذر إنشاء الحساب';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: AppFonts.tajawal()),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text('إنشاء حساب', style: AppFonts.tajawal(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(
                  title: 'انضم إلينا',
                  subtitle: 'أنشئ حسابك للاستمتاء بالطلبات ونقاط الولاء في حلوانى ابوعمر',
                ),
                const SizedBox(height: 28),
                AuthTextField(
                  controller: _nameController,
                  label: 'الاسم الكامل',
                  hint: 'اكتب اسمك',
                  validator: (value) {
                    if ((value ?? '').trim().length < 3) {
                      return 'أدخل اسماً صالحاً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _phoneController,
                  label: 'رقم الجوال',
                  hint: '01xxxxxxxxx',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    final digits = text.replaceAll(RegExp(r'\D'), '');
                    if (!RegExp(r'^01[0125]\d{8}$').hasMatch(digits) &&
                        !RegExp(r'^201[0125]\d{8}$').hasMatch(digits)) {
                      return 'أدخل رقم جوال مصري صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور',
                  hint: '••••••••',
                  obscureText: _obscure,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppTheme.muted,
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').length < 6) {
                      return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _confirmController,
                  label: 'تأكيد كلمة المرور',
                  hint: '••••••••',
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppTheme.muted,
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'إنشاء الحساب',
                          style: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'لديك حساب بالفعل؟',
                      style: AppFonts.tajawal(color: AppTheme.muted),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        'تسجيل الدخول',
                        style: AppFonts.tajawal(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
