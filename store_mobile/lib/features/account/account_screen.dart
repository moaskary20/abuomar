import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../widgets/brand_hero_panel.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../loyalty/loyalty_screen.dart';
import '../orders/orders_screen.dart';
import '../settings/settings_screen.dart';
import 'addresses_screen.dart';
import 'contact_us_screen.dart';
import 'info_page_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loyalty = context.watch<LoyaltyController>();
    final auth = context.watch<AuthController>();
    final addressesCount = context.watch<AddressesController>().count;
    final ordersCount = context.watch<OrdersController>().orders.length;
    final user = auth.user;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        _ProfileHero3D(
          isLoggedIn: auth.isLoggedIn,
          name: auth.isLoggedIn ? user!.name : 'زائر',
          subtitle: auth.isLoggedIn
              ? user!.email
              : 'سجّل الدخول لإدارة طلباتك ونقاطك',
          avatarBytes: user?.avatarBytes,
          onLoginTap: auth.isLoggedIn ? null : () => _openLogin(context),
          onAvatarTap: auth.isLoggedIn
              ? () => _changeAvatar(context, auth)
              : () => _openLogin(context),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatCube3D(
                icon: Icons.stars_rounded,
                label: 'نقاط الولاء',
                value: '${loyalty.points}',
                hint: '≈ ${loyalty.valueInEgp.toStringAsFixed(0)} ${AppConfig.currency}',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoyaltyScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCube3D(
                icon: Icons.receipt_long_rounded,
                label: 'طلباتي',
                value: auth.isLoggedIn ? '$ordersCount' : '—',
                hint: auth.isLoggedIn ? 'طلب' : 'سجّل الدخول',
                onTap: () {
                  if (!auth.isLoggedIn) {
                    _openLogin(context);
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _SectionTitle3D(title: 'حسابي'),
        const SizedBox(height: 10),
        _MenuTile3D(
          icon: Icons.location_on_rounded,
          title: 'عناوين التوصيل',
          subtitle: auth.isLoggedIn
              ? (addressesCount > 0
                  ? '$addressesCount عنوان محفوظ'
                  : 'أضف عنوان توصيل لحسابك')
              : 'إدارة العناوين المحفوظة',
          depth: 1,
          onTap: () {
            if (!auth.isLoggedIn) {
              _openLogin(context);
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddressesScreen()),
            );
          },
        ),
        _MenuTile3D(
          icon: Icons.settings_rounded,
          title: 'الإعدادات',
          subtitle: 'الإشعارات، المظهر والمزيد',
          depth: 2,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        const SizedBox(height: 18),
        _SectionTitle3D(title: 'المساعدة'),
        const SizedBox(height: 10),
        _MenuTile3D(
          icon: Icons.support_agent_rounded,
          title: 'تواصل معنا',
          subtitle: 'هاتف، واتساب، بريد، موقع',
          depth: 1,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ContactUsScreen()),
            );
          },
        ),
        _MenuTile3D(
          icon: Icons.ios_share_rounded,
          title: 'مشاركة التطبيق',
          subtitle: 'أرسل التطبيق لأصدقائك',
          depth: 2,
          onTap: () => _shareApp(context),
        ),
        _MenuTile3D(
          icon: Icons.privacy_tip_rounded,
          title: 'سياسة الخصوصية',
          subtitle: 'كيف نحمي بياناتك',
          depth: 3,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const InfoPageScreen(
                  title: 'سياسة الخصوصية',
                  sections: LegalContent.privacySections,
                  variant: InfoPageVariant.privacy,
                ),
              ),
            );
          },
        ),
        _MenuTile3D(
          icon: Icons.description_rounded,
          title: 'الشروط والأحكام',
          subtitle: 'شروط الاستخدام والطلب',
          depth: 4,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const InfoPageScreen(
                  title: 'الشروط والأحكام',
                  sections: LegalContent.termsSections,
                  variant: InfoPageVariant.terms,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        if (auth.isLoggedIn)
          _LogoutButton3D(
            onTap: () {
              auth.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم تسجيل الخروج', style: AppFonts.tajawal()),
                ),
              );
            },
          )
        else ...[
          _PrimaryButton3D(
            label: 'تسجيل الدخول',
            onTap: () => _openLogin(context),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: Text(
                'إنشاء حساب جديد',
                style: AppFonts.tajawal(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _changeAvatar(BuildContext context, AuthController auth) async {
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.cocoa.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'الصورة الشخصية',
                      style: AppFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
                  title: Text('اختيار من المعرض', style: AppFonts.tajawal(fontWeight: FontWeight.w700)),
                  onTap: () => Navigator.pop(ctx, _AvatarAction.gallery),
                ),
                if (!kIsWeb)
                  ListTile(
                    leading: const Icon(Icons.photo_camera_rounded, color: AppTheme.primary),
                    title: Text('التقاط صورة', style: AppFonts.tajawal(fontWeight: FontWeight.w700)),
                    onTap: () => Navigator.pop(ctx, _AvatarAction.camera),
                  ),
                if (auth.user?.avatarBytes != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.primary),
                    title: Text('إزالة الصورة', style: AppFonts.tajawal(fontWeight: FontWeight.w700)),
                    onTap: () => Navigator.pop(ctx, _AvatarAction.remove),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (action == null || !context.mounted) {
      return;
    }

    if (action == _AvatarAction.remove) {
      await auth.clearAvatar();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إزالة الصورة', style: AppFonts.tajawal())),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final source = action == _AvatarAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    try {
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null || !context.mounted) {
        return;
      }
      final bytes = await file.readAsBytes();
      await auth.updateAvatar(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث الصورة الشخصية', style: AppFonts.tajawal())),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر اختيار الصورة. تأكد من صلاحيات المعرض/الكاميرا',
              style: AppFonts.tajawal(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: AppConfig.appShareMessage,
        subject: AppConfig.appNameAr,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}

enum _AvatarAction { gallery, camera, remove }

class _ProfileHero3D extends StatelessWidget {
  const _ProfileHero3D({
    required this.isLoggedIn,
    required this.name,
    required this.subtitle,
    this.avatarBytes,
    this.onLoginTap,
    this.onAvatarTap,
  });

  final bool isLoggedIn;
  final String name;
  final String subtitle;
  final Uint8List? avatarBytes;
  final VoidCallback? onLoginTap;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return BrandHeroPanel3D(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      borderRadius: 28,
      child: Row(
        children: [
          _EditableAvatar(
            isLoggedIn: isLoggedIn,
            avatarBytes: avatarBytes,
            onTap: onAvatarTap,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppFonts.tajawal(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.tajawal(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.35,
                  ),
                ),
                if (onLoginTap != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onLoginTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'تسجيل الدخول',
                        style: AppFonts.tajawal(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.isLoggedIn,
    this.avatarBytes,
    this.onTap,
  });

  final bool isLoggedIn;
  final Uint8List? avatarBytes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = avatarBytes != null && avatarBytes!.isNotEmpty;

    return Tooltip(
      message: isLoggedIn ? 'تغيير الصورة الشخصية' : 'سجّل الدخول لتغيير الصورة',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        hasPhoto ? MemoryImage(avatarBytes!) : null,
                    child: hasPhoto
                        ? null
                        : Icon(
                            isLoggedIn
                                ? Icons.person_rounded
                                : Icons.person_outline_rounded,
                            color: AppTheme.primary,
                            size: 34,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  left: 2,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFFFF0EA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 13,
                      color: AppTheme.primary,
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

class _StatCube3D extends StatefulWidget {
  const _StatCube3D({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final VoidCallback onTap;

  @override
  State<_StatCube3D> createState() => _StatCube3DState();
}

class _StatCube3DState extends State<_StatCube3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_pressed ? 0.02 : -0.03)
          ..translateByDouble(0, _pressed ? 4 : 0, 0, 1),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF4EF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: _pressed ? 0.12 : 0.22),
              blurRadius: _pressed ? 10 : 18,
              offset: Offset(0, _pressed ? 4 : 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.16),
                    AppTheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              widget.label,
              style: AppFonts.tajawal(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.value,
              style: AppFonts.tajawal(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.cocoa,
              ),
            ),
            Text(
              widget.hint,
              style: AppFonts.tajawal(
                color: AppTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle3D extends StatelessWidget {
  const _SectionTitle3D({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppFonts.tajawal(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.cocoa,
          ),
        ),
      ],
    );
  }
}

class _MenuTile3D extends StatefulWidget {
  const _MenuTile3D({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.depth = 1,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int depth;

  @override
  State<_MenuTile3D> createState() => _MenuTile3DState();
}

class _MenuTile3DState extends State<_MenuTile3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final lift = 8.0 + (widget.depth % 3);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0011)
            ..rotateX(_pressed ? 0.01 : -0.02)
            ..rotateY(_pressed ? 0 : 0.012)
            ..translateByDouble(0, _pressed ? 3 : 0, 0, 1),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Color.lerp(Colors.white, AppTheme.cream, 0.55)!,
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cocoa.withValues(alpha: _pressed ? 0.08 : 0.14),
                blurRadius: _pressed ? 8 : lift + 6,
                offset: Offset(0, _pressed ? 3 : lift),
              ),
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(-2, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateY(-0.18)
                  ..rotateX(-0.08),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryDark, AppTheme.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppFonts.tajawal(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.cocoa,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: AppFonts.tajawal(
                        color: AppTheme.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.rotate(
                angle: math.pi,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.primary,
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

class _PrimaryButton3D extends StatefulWidget {
  const _PrimaryButton3D({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryButton3D> createState() => _PrimaryButton3DState();
}

class _PrimaryButton3DState extends State<_PrimaryButton3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: _pressed ? 0.2 : 0.4),
              blurRadius: _pressed ? 8 : 16,
              offset: Offset(0, _pressed ? 4 : 10),
            ),
          ],
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: AppFonts.tajawal(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _LogoutButton3D extends StatefulWidget {
  const _LogoutButton3D({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_LogoutButton3D> createState() => _LogoutButton3DState();
}

class _LogoutButton3DState extends State<_LogoutButton3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: AppTheme.primary, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: _pressed ? 0.1 : 0.18),
              blurRadius: _pressed ? 6 : 12,
              offset: Offset(0, _pressed ? 3 : 7),
            ),
          ],
        ),
        child: Text(
          'تسجيل الخروج',
          textAlign: TextAlign.center,
          style: AppFonts.tajawal(
            color: AppTheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
