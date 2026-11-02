#!/usr/bin/env bash
# نسخة احتياطية مضغوطة لقاعدة البيانات في مجلد backups/.
# للجدولة اليومية:  (crontab -e)  0 2 * * *  cd /path/to/this && bash backup.sh
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p backups
STAMP="$(date +%Y%m%d-%H%M%S)"
FILE="backups/vehicle-ops-${STAMP}.sql.gz"

# shellcheck disable=SC1091
set -a; . ./.env; set +a

echo "==> أخذ نسخة من قاعدة البيانات"
docker compose exec -T db sh -c "exec mariadb-dump --single-transaction --quick -u root -p\"\$MARIADB_ROOT_PASSWORD\" \"$DB_DATABASE\"" \
    | gzip > "$FILE"

echo "  • تم: $FILE ($(du -h "$FILE" | cut -f1))"

# الاحتفاظ بآخر 14 نسخة فقط
ls -1t backups/vehicle-ops-*.sql.gz 2>/dev/null | tail -n +15 | xargs -r rm -f
echo "==> اكتمل. انقل النسخ لمكان خارج السيرفر دورياً."
