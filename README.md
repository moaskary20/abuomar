# حلوانى ابوعمر

مشروع متجر حلويات يضم لوحة التحكم وتطبيق الموبايل.

## المجلدات

- `store-admin` — لوحة التحكم (Laravel / Filament)
- `store_mobile` — تطبيق أندرويد (Flutter)

## لوحة التحكم

```bash
cd store-admin
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate --seed
php artisan storage:link
php artisan serve
```

لوحة الإدارة: http://127.0.0.1:8000/admin

## تطبيق الموبايل

```bash
cd store_mobile
flutter pub get
flutter run
```

حزمة Google Play:

```bash
cd store_mobile
./tool/build_play.sh
```
