#!/usr/bin/env bash
# تركيب نظام Vehicle Operations على سيرفر العميل.
# الاستخدام:  bash install.sh
set -euo pipefail
cd "$(dirname "$0")"

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
die() { printf '\n\033[1;31mخطأ: %s\033[0m\n' "$1" >&2; exit 1; }

command -v docker >/dev/null 2>&1 || die "Docker غير مثبّت. ثبّت Docker Engine أولاً."
docker compose version >/dev/null 2>&1 || die "Docker Compose plugin غير موجود."

# 1) ملف الإعدادات
if [ ! -f .env ]; then
    say "إنشاء ملف .env من المثال"
    cp .env.example .env
    chmod 600 .env
    echo "تم إنشاء .env — افتحه وعدّل APP_URL و LICENSOR_PRODUCT_ID ثم أعد تشغيل هذا السكربت."
fi

# 2) توليد الأسرار الناقصة (مرة واحدة)
gen() { openssl rand -hex 24; }
set_env() { # key value
    if grep -q "^$1=$" .env; then
        sed -i "s|^$1=.*|$1=$2|" .env
        echo "  • تم توليد $1"
    fi
}
say "توليد الأسرار الناقصة"
set_env DB_PASSWORD "$(gen)"
set_env DB_ROOT_PASSWORD "$(gen)"

# APP_KEY يُولّد بواسطة التطبيق نفسه
if grep -q "^APP_KEY=$" .env; then
    say "توليد APP_KEY"
    KEY="$(docker compose run --rm --no-deps app php artisan key:generate --show 2>/dev/null | tr -d '\r')"
    [ -n "$KEY" ] || die "تعذّر توليد APP_KEY — تأكد أنك سجّلت الدخول لسحب الصورة (docker login ghcr.io)."
    sed -i "s|^APP_KEY=.*|APP_KEY=${KEY}|" .env
    echo "  • تم"
fi

# 3) التحقق من الإعدادات الإلزامية
grep -q "^LICENSOR_PRODUCT_ID=.\+" .env || die "LICENSOR_PRODUCT_ID فارغ في .env — ضع الكود الذي زوّدك به المزوّد."

# 4) سحب الصورة والتشغيل
say "سحب صورة النظام"
docker compose pull || die "تعذّر سحب الصورة. سجّل الدخول أولاً: docker login ghcr.io"

say "تشغيل النظام"
docker compose up -d

# 5) انتظار الجاهزية
say "انتظار جاهزية النظام (قد تستغرق دقيقة)"
PORT="$(grep '^APP_PORT=' .env | cut -d= -f2)"; PORT="${PORT:-8098}"
for i in $(seq 1 60); do
    code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}/up" || true)"
    [ "$code" = "200" ] && break
    sleep 3
done
[ "${code:-}" = "200" ] && echo "  • النظام يعمل (HTTP 200)" || echo "  • لم يرد بعد — راجع: docker compose logs -f app"

cat <<EOF

\033[1;32mتم التركيب.\033[0m

الخطوة الأخيرة — أنشئ حساب المدير الأول:

  docker compose exec app php artisan vos:create-admin

ثم افتح النظام على: $(grep '^APP_URL=' .env | cut -d= -f2)
(لازم يكون خلف HTTPS — Cloudflare Tunnel أو reverse proxy)

أوامر مفيدة:
  docker compose logs -f app      متابعة السجلات
  bash update.sh                  تحديث لإصدار جديد
  bash backup.sh                  نسخة احتياطية لقاعدة البيانات
EOF
