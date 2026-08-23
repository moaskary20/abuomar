# تطبيق الموبايل — Abo Omar Pastry

## المسار
`/media/mohamed/d1/omar/store_mobile`

## الهدف
تطبيق Flutter للعملاء مرتبط بلوحة تحكم Filament (`store-admin`):
- تصفح التصنيفات والمنتجات
- السلة وإتمام الطلب
- نقاط الولاء (كسب / استبدال)
- حساب العميل

## التشغيل
```bash
cd /media/mohamed/d1/omar/store_mobile
flutter pub get
flutter run
```

## الربط مع الـ Backend
- لوحة التحكم: `store-admin` (Laravel + Filament)
- إعدادات الـ API حالياً في: `lib/core/config.dart`
- القيمة الافتراضية: `http://127.0.0.1:8000`
- على جهاز حقيقي استبدل بـ IP جهاز السيرفر (مثال: `http://192.168.1.10:8000`)

## هيكل المشروع
```
lib/
  main.dart
  app.dart
  core/          # إعدادات وثيم
  models/        # نماذج البيانات
  data/          # بيانات تجريبية / حالة السلة والولاء
  features/      # الشاشات (رئيسية، تصنيفات، سلة، ولاء)
  widgets/       # بطاقات المنتج والتصنيف
```

## الحالة الحالية
- مشروع Flutter جاهز (Android + iOS)
- واجهة عربية RTL باسم أبو عمر للحلويات
- شاشات: الرئيسية، التصنيفات، السلة، الولاء
- بيانات تجريبية محلية إلى حين تجهيز API الموبايل من Laravel

## بيانات دخول لوحة التحكم
انظر: `../store-admin/doc.text`
