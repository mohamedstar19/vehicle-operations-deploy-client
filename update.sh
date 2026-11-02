#!/usr/bin/env bash
# تحديث النظام لإصدار جديد.
# 1) عدّل APP_IMAGE في .env للإصدار الجديد (أو اتركه :latest)
# 2) شغّل: bash update.sh
set -euo pipefail
cd "$(dirname "$0")"

echo "==> نسخة احتياطية قبل التحديث"
bash backup.sh || echo "  (تم تخطي النسخ الاحتياطي)"

echo "==> سحب الإصدار الجديد"
docker compose pull

echo "==> إعادة التشغيل"
docker compose up -d

echo "==> تنظيف الصور القديمة"
docker image prune -f >/dev/null 2>&1 || true

echo "تم التحديث. تابع السجلات: docker compose logs -f app"
