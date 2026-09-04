import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/api_client.dart';
import '../../data/app_state.dart';
import '../../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await context.read<AuthController>().sendPasswordReset(_phoneController.text);
      if (!mounted) return;

      setState(() => _sent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'إذا كان رقم الجوال مسجّلاً، تواصل مع المتجر لإعادة تعيين كلمة المرور',
            style: AppFonts.tajawal(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : 'تعذر إرسال الطلب';
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
        title: Text('نسيت كلمة المرور', style: AppFonts.tajawal(fontWeight: FontWeight.w700)),
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
                  title: 'استعادة الحساب',
                  subtitle: 'أدخل رقم جوالك المسجّل وتواصل مع المتجر لإعادة تعيين كلمة المرور',
                ),
                const SizedBox(height: 28),
                if (_sent)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      'تم استلام طلبك. تواصل مع المتجر برقم الجوال لإعادة تعيين كلمة المرور.',
                      style: AppFonts.tajawal(height: 1.5, color: AppTheme.cocoa),
                    ),
                  ),
                AuthTextField(
                  controller: _phoneController,
                  label: 'رقم الجوال',
                  hint: '01xxxxxxxxx',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    final digits = text.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10) {
                      return 'أدخل رقم جوال صحيح';
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
                          _sent ? 'إعادة الإرسال' : 'إرسال طلب الاستعادة',
                          style: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'العودة لتسجيل الدخول',
                    style: AppFonts.tajawal(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
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
}
