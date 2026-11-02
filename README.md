# Vehicle Operations — ملفات التشغيل

نظام إدارة حركات تشغيل العربيات والآليات (Hydraulic / Light / Heavy)، مع إدارة العملاء
والموظفين وأوامر البيع والفواتير، ولوحات تحليلية وتصدير Excel.

> هذا المستودع يحتوي على **ملفات التشغيل فقط** (إعدادات Docker وسكربتات).
> النظام نفسه يعمل من **صورة جاهزة** يوفّرها Darwish Tech. راجع [LICENSE.md](LICENSE.md).

---

## المتطلبات
- سيرفر Linux (يُفضّل Ubuntu 24.04)، 2 vCPU و4GB RAM و40GB SSD.
- Docker Engine + Docker Compose plugin.
- دومين يشير للسيرفر، خلفه HTTPS (Cloudflare Tunnel أو reverse proxy).
- **كود التفعيل (Product ID)** وبيانات الدخول لسحب الصورة — يوفّرهما Darwish Tech.

## التركيب (خطوة بخطوة)

```bash
# 1) سجّل الدخول لسحب الصورة الخاصة (بالبيانات التي زوّدك بها المزوّد)
docker login ghcr.io -u <USERNAME>

# 2) نزّل ملفات التشغيل
git clone https://github.com/mohamedstar19/vehicle-operations-deploy-client.git vehicle-ops
cd vehicle-ops

# 3) جهّز الإعدادات
cp .env.example .env
nano .env          # عدّل APP_URL و LICENSOR_PRODUCT_ID (والباقي يتولّد تلقائياً)

# 4) ركّب وشغّل
bash install.sh

# 5) أنشئ حساب المدير الأول
docker compose exec app php artisan vos:create-admin
```

ثم وجّه الدومين (مثلاً عبر Cloudflare Tunnel) إلى `http://localhost:8098`.

## التفعيل
النظام لا يعمل قبل تفعيله. عند أول تشغيل يُرسل طلب تفعيل تلقائي، ويظهر النظام صفحة
"في انتظار الموافقة" مع رقم الطلب ومعرّف الجهاز. يوافق المزوّد على الطلب من لوحة
التفعيل، ويعمل النظام خلال دقيقة. التفعيل محدود بعدد أجهزة ومدة يحددهما المزوّد.

للتحقق من حالة التفعيل:
```bash
docker compose exec app php artisan license:status
```

## التشغيل اليومي

| الأمر | الغرض |
|---|---|
| `docker compose ps` | حالة الخدمات |
| `docker compose logs -f app` | متابعة السجلات |
| `bash backup.sh` | نسخة احتياطية لقاعدة البيانات (في `backups/`) |
| `bash update.sh` | تحديث لإصدار جديد |
| `docker compose exec app php artisan vos:create-admin` | إضافة/إعادة ضبط مدير |

### نسخة احتياطية يومية تلقائية
```bash
crontab -e
# أضف السطر التالي (الساعة 2 فجراً):
0 2 * * * cd /path/to/vehicle-ops && bash backup.sh >> backups/backup.log 2>&1
```
> احرص على نقل النسخ من مجلد `backups/` إلى مكان خارج السيرفر دورياً.

## التحديث
يصدر المزوّد إصدارات جديدة كصور بأرقام (مثل `:1.2.0`). للتحديث: عدّل `APP_IMAGE`
في `.env` للإصدار الجديد ثم:
```bash
bash update.sh
```
تُحفظ البيانات في volumes منفصلة ولا تتأثر بالتحديث.

## الدعم
Darwish Tech — Eng. Mohamed Khaled Darwish.
