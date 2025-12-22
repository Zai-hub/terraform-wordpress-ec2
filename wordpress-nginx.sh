#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASS="password"

# Pick package manager
if command -v dnf >/dev/null 2>&1; then
  PM="dnf"
else
  PM="yum"
fi

$PM -y update

# Install required packages
$PM -y install nginx php php-fpm php-mysqlnd curl-minimal tar unzip

# Install MariaDB server (Amazon Linux 2023 package name)
$PM -y install mariadb105-server || $PM -y install mariadb-server || $PM -y install mariadb


# Enable and start services
systemctl enable --now nginx
systemctl enable --now mariadb
systemctl enable --now php-fpm

# Configure PHP-FPM to work with NGINX (critical fix)
PHPFPM_CONF="/etc/php-fpm.d/www.conf"
sed -i 's/^user = .*/user = nginx/' "$PHPFPM_CONF"
sed -i 's/^group = .*/group = nginx/' "$PHPFPM_CONF"
sed -i 's/^listen = .*/listen = \/run\/php-fpm\/www.sock/' "$PHPFPM_CONF"
grep -q '^listen.owner' "$PHPFPM_CONF" && sed -i 's/^listen.owner.*/listen.owner = nginx/' "$PHPFPM_CONF" || echo 'listen.owner = nginx' >> "$PHPFPM_CONF"
grep -q '^listen.group' "$PHPFPM_CONF" && sed -i 's/^listen.group.*/listen.group = nginx/' "$PHPFPM_CONF" || echo 'listen.group = nginx' >> "$PHPFPM_CONF"
grep -q '^listen.mode'  "$PHPFPM_CONF" && sed -i 's/^listen.mode.*/listen.mode = 0660/' "$PHPFPM_CONF" || echo 'listen.mode = 0660' >> "$PHPFPM_CONF"

systemctl restart php-fpm

# DB setup (idempotent)
mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Install WordPress
mkdir -p /var/www
cd /var/www

if [ ! -d "/var/www/wordpress" ]; then
  curl -fsSL -o latest.tar.gz https://wordpress.org/latest.tar.gz
  tar -xzf latest.tar.gz
  rm -f latest.tar.gz
fi

# Configure wp-config.php
if [ ! -f "/var/www/wordpress/wp-config.php" ]; then
  cp /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php
  sed -i "s/database_name_here/${DB_NAME}/" /var/www/wordpress/wp-config.php
  sed -i "s/username_here/${DB_USER}/" /var/www/wordpress/wp-config.php
  sed -i "s/password_here/${DB_PASS}/" /var/www/wordpress/wp-config.php
fi

# Permissions
chown -R nginx:nginx /var/www/wordpress

# NGINX config for WordPress
cat > /etc/nginx/conf.d/wordpress.conf <<'NGINXCONF'
server {
  listen 80;
  server_name _;
  root /var/www/wordpress;
  index index.php index.html;

  location / {
    try_files $uri $uri/ /index.php?$args;
  }

  location ~ \.php$ {
    include fastcgi_params;
    fastcgi_pass unix:/run/php-fpm/www.sock;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
  }
}
NGINXCONF

# Remove default nginx welcome config if present (varies by distro)
rm -f /etc/nginx/conf.d/default.conf || true

nginx -t
systemctl restart nginx
