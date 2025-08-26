# Symfony user-service (PHP 8.2 FPM + Nginx)
FROM php:8.2-fpm

# Install system deps
RUN apt-get update && apt-get install -y \
    git unzip libzip-dev libicu-dev libpng-dev libonig-dev default-mysql-client curl nginx \
  && docker-php-ext-install pdo pdo_mysql \
  && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Install PHP dependencies from repository composer.json/lock
COPY composer.json ./
COPY composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --no-scripts

# Copy application code overlays (controllers, entities, config)
COPY src/ ./src/
COPY config/ ./config/
COPY migrations/ ./migrations/
COPY public/ ./public/
COPY bin/ ./bin/
COPY symfony.lock ./symfony.lock
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose app port
EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
