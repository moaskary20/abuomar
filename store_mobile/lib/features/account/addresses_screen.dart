import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../widgets/brand_hero_panel.dart';
import '../../data/app_state.dart';
import '../../models/store_models.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      context.read<AddressesController>().syncUser(auth.user);
    });
  }

  Future<void> _openEditor({DeliveryAddress? existing}) async {
    final auth = context.read<AuthController>();
    final result = await showModalBottomSheet<DeliveryAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressEditorSheet(
        initial: existing,
        fallbackName: auth.user?.name ?? '',
        fallbackPhone: auth.user?.phone ?? '',
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    final addresses = context.read<AddressesController>();
    if (existing == null) {
      await addresses.add(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة العنوان', style: AppFonts.tajawal())),
        );
      }
    } else {
      await addresses.update(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث العنوان', style: AppFonts.tajawal())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final addresses = context.watch<AddressesController>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF6F1),
        body: Center(
          child: Text(
            'سجّل الدخول لإدارة عناوينك',
            style: AppFonts.tajawal(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F1),
      floatingActionButton: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateX(-0.08),
        child: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.add_location_alt_rounded),
          label: Text(
            'عنوان جديد',
            style: AppFonts.tajawal(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    _TopBar(
                      onBack: () => Navigator.of(context).maybePop(),
                      count: addresses.count,
                    ),
                    const SizedBox(height: 14),
                    _AddressesHero3D(
                      userName: auth.user!.name,
                      count: addresses.count,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (addresses.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyAddresses3D(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
              sliver: SliverList.separated(
                itemCount: addresses.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final address = addresses.items[index];
                  return _AddressCard3D(
                    address: address,
                    onEdit: () => _openEditor(existing: address),
                    onDelete: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('حذف العنوان؟', style: AppFonts.tajawal(fontWeight: FontWeight.w800)),
                          content: Text(
                            'سيتم حذف «${address.label}» من حسابك',
                            style: AppFonts.tajawal(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('إلغاء', style: AppFonts.tajawal()),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text('حذف', style: AppFonts.tajawal(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await context.read<AddressesController>().remove(address.id);
                      }
                    },
                    onSetDefault: address.isDefault
                        ? null
                        : () => addresses.setDefault(address.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.count});

  final VoidCallback onBack;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundBack3D(onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'عناوين التوصيل',
                style: AppFonts.tajawal(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                count == 0 ? 'أضف عنوانك الأول' : '$count عنوان محفوظ',
                style: AppFonts.tajawal(color: AppTheme.muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundBack3D extends StatefulWidget {
  const _RoundBack3D({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_RoundBack3D> createState() => _RoundBack3DState();
}

class _RoundBack3DState extends State<_RoundBack3D> {
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
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.cocoa.withValues(alpha: _pressed ? 0.06 : 0.12),
              blurRadius: _pressed ? 6 : 14,
              offset: Offset(0, _pressed ? 2 : 6),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.cocoa),
      ),
    );
  }
}

class _AddressesHero3D extends StatelessWidget {
  const _AddressesHero3D({required this.userName, required this.count});

  final String userName;
  final int count;

  @override
  Widget build(BuildContext context) {

    return BrandHeroPanel3D(
      borderRadius: 26,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Row(
                  children: [
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(-0.28)
                        ..rotateY(0.32),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withValues(alpha: 0.16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'عناوين $userName',
                            style: AppFonts.tajawal(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'مرتبطة بحسابك وتُستخدم عند إتمام الطلب',
                            style: AppFonts.tajawal(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$count',
                            style: AppFonts.tajawal(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'عنوان',
                            style: AppFonts.tajawal(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _EmptyAddresses3D extends StatelessWidget {
  const _EmptyAddresses3D();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(-0.06)
            ..rotateY(0.04),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFFFF4EF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateX(-0.25)
                    ..rotateY(0.35),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.18),
                          AppTheme.primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: const Icon(Icons.add_location_alt_outlined, size: 38, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد عناوين بعد',
                  style: AppFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'أضف عنوان توصيل مرتبط بحسابك لتسهيل الطلبات القادمة',
                  textAlign: TextAlign.center,
                  style: AppFonts.tajawal(color: AppTheme.muted, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressCard3D extends StatefulWidget {
  const _AddressCard3D({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final DeliveryAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  @override
  State<_AddressCard3D> createState() => _AddressCard3DState();
}

class _AddressCard3DState extends State<_AddressCard3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.address;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onEdit();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0011)
          ..rotateX(_pressed ? 0.01 : -0.03)
          ..rotateY(_pressed ? 0 : 0.015)
          ..translateByDouble(0, _pressed ? 3 : 0, 0, 1),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF8F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: a.isDefault
                ? AppTheme.primary.withValues(alpha: 0.35)
                : Colors.white,
            width: a.isDefault ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: _pressed ? 0.1 : 0.18),
              blurRadius: _pressed ? 10 : 18,
              offset: Offset(0, _pressed ? 5 : 10),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(0.2)
                    ..rotateX(-0.1),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.18),
                          AppTheme.primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Icon(
                      a.label.contains('عمل')
                          ? Icons.work_rounded
                          : Icons.home_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              a.label,
                              style: AppFonts.tajawal(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (a.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'افتراضي',
                                style: AppFonts.tajawal(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        a.recipientName,
                        style: AppFonts.tajawal(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              a.fullAddress,
              style: AppFonts.tajawal(
                height: 1.45,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            if (a.phone != null && a.phone!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                a.phone!,
                style: AppFonts.tajawal(color: AppTheme.muted, fontSize: 12.5),
              ),
            ],
            if (a.notes != null && a.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                a.notes!,
                style: AppFonts.tajawal(color: AppTheme.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.onSetDefault != null)
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      widget.onSetDefault!();
                    },
                    child: Text(
                      'تعيين افتراضي',
                      style: AppFonts.tajawal(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: 'تعديل',
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_rounded, color: AppTheme.cocoa),
                ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressEditorSheet extends StatefulWidget {
  const _AddressEditorSheet({
    this.initial,
    required this.fallbackName,
    required this.fallbackPhone,
  });

  final DeliveryAddress? initial;
  final String fallbackName;
  final String fallbackPhone;

  @override
  State<_AddressEditorSheet> createState() => _AddressEditorSheetState();
}

class _AddressEditorSheetState extends State<_AddressEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  late final TextEditingController _area;
  late final TextEditingController _street;
  late final TextEditingController _building;
  late final TextEditingController _floor;
  late final TextEditingController _apartment;
  late final TextEditingController _notes;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _label = TextEditingController(text: i?.label ?? 'المنزل');
    _name = TextEditingController(text: i?.recipientName ?? widget.fallbackName);
    _phone = TextEditingController(text: i?.phone ?? widget.fallbackPhone);
    _city = TextEditingController(text: i?.city ?? 'القاهرة');
    _area = TextEditingController(text: i?.area ?? '');
    _street = TextEditingController(text: i?.street ?? '');
    _building = TextEditingController(text: i?.building ?? '');
    _floor = TextEditingController(text: i?.floor ?? '');
    _apartment = TextEditingController(text: i?.apartment ?? '');
    _notes = TextEditingController(text: i?.notes ?? '');
    _isDefault = i?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _area.dispose();
    _street.dispose();
    _building.dispose();
    _floor.dispose();
    _apartment.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.pop(
      context,
      DeliveryAddress(
        id: widget.initial?.id ?? 0,
        label: _label.text.trim(),
        recipientName: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        city: _city.text.trim(),
        area: _area.text.trim().isEmpty ? null : _area.text.trim(),
        street: _street.text.trim(),
        building: _building.text.trim().isEmpty ? null : _building.text.trim(),
        floor: _floor.text.trim().isEmpty ? null : _floor.text.trim(),
        apartment: _apartment.text.trim().isEmpty ? null : _apartment.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        isDefault: _isDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.cocoa.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.initial == null ? 'إضافة عنوان' : 'تعديل العنوان',
                  style: AppFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                _field(_label, 'التسمية (المنزل / العمل)', requiredField: true),
                _field(_name, 'اسم المستلم', requiredField: true),
                _field(_phone, 'جوال التواصل', keyboard: TextInputType.phone),
                _field(_city, 'المدينة', requiredField: true),
                _field(_area, 'المنطقة / الحي'),
                _field(_street, 'الشارع', requiredField: true),
                Row(
                  children: [
                    Expanded(child: _field(_building, 'المبنى')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(_floor, 'الدور')),
                    const SizedBox(width: 8),
                    Expanded(child: _field(_apartment, 'الشقة')),
                  ],
                ),
                _field(_notes, 'ملاحظات التوصيل', maxLines: 2),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isDefault,
                  activeThumbColor: AppTheme.primary,
                  title: Text(
                    'تعيين كعنوان افتراضي',
                    style: AppFonts.tajawal(fontWeight: FontWeight.w700),
                  ),
                  onChanged: (v) => setState(() => _isDefault = v),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'حفظ العنوان',
                    style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool requiredField = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: AppFonts.tajawal(fontWeight: FontWeight.w600),
        validator: requiredField
            ? (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppFonts.tajawal(color: AppTheme.muted),
          filled: true,
          fillColor: const Color(0xFFFFF6F1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppTheme.cocoa.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}
