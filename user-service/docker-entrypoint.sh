#!/usr/bin/env bash
set -euo pipefail

# Wait for DB
if [ -n "${DATABASE_URL:-}" ]; then
  echo "Waiting for MySQL to be ready..."
  until php -r 'try{$d=parse_url(getenv("DATABASE_URL"));$pdo=new PDO("mysql:host=".$d["host"].";port=".($d["port"]??3306), $d["user"], $d["pass"]);echo "ok\n";}catch(Exception $e){exit(1);}'; do
    sleep 2
  done
fi

# Refresh autoload and clear cache (in case code was copied after composer install)
composer dump-autoload -o || true
php bin/console cache:clear || true

# Ensure database and run migrations
php bin/console doctrine:database:create --if-not-exists || true
php bin/console doctrine:migrations:migrate --no-interaction || true

# Start PHP-FPM and Nginx
# Ensure runtime dirs
mkdir -p /run/php /var/run/nginx

# Start php-fpm in the background
php-fpm -D

# Start nginx in the foreground (container PID 1)
nginx -g 'daemon off;'
