#!/bin/bash

set -e

# Define credentials
SMF_DB="smf_db"
SMF_USER="smf_user"
SMF_PASS="smf_pass"

WDP_DB="wp_db"
WDP_USER="wp_user"
WDP_PASS="wp_pass"

SMF_DIR="/var/www/html/smf"
WDP_DIR="/var/www/html/wdp"

echo "Installing required PHP modules..."

apt update
apt install -y unzip wget php8.3-mysql php8.3-curl php8.3-xml \
php8.3-mbstring php8.3-zip php8.3-gd

echo "Resetting web directories..."
rm -rf "$SMF_DIR" "$WDP_DIR"
mkdir -p "$SMF_DIR" "$WDP_DIR"

echo "Downloading and extracting SMF..."
cd /tmp
wget -q https://download.simplemachines.org/index.php/smf_2-1-4_install.zip -O smf.zip
unzip -q smf.zip -d smf_extract
cp -r smf_extract/* "$SMF_DIR/"

echo "Downloading and extracting WordPress..."
wget -q https://wordpress.org/latest.zip -O wordpress.zip
unzip -q wordpress.zip
cp -r wordpress/* "$WDP_DIR/"

echo "Fixing permissions..."
chown -R www-data:www-data "$SMF_DIR" "$WDP_DIR"
find "$SMF_DIR" "$WDP_DIR" -type d -exec chmod 755 {} \;
find "$SMF_DIR" "$WDP_DIR" -type f -exec chmod 644 {} \;

echo "Dropping and recreating MariaDB databases and users..."
mysql -u root <<SQL
DROP DATABASE IF EXISTS $SMF_DB;
DROP DATABASE IF EXISTS $WDP_DB;
DROP USER IF EXISTS '$SMF_USER'@'localhost';
DROP USER IF EXISTS '$WDP_USER'@'localhost';

CREATE DATABASE $SMF_DB;
CREATE USER '$SMF_USER'@'localhost' IDENTIFIED BY '$SMF_PASS';
GRANT ALL PRIVILEGES ON $SMF_DB.* TO '$SMF_USER'@'localhost';

CREATE DATABASE $WDP_DB;
CREATE USER '$WDP_USER'@'localhost' IDENTIFIED BY '$WDP_PASS';
GRANT ALL PRIVILEGES ON $WDP_DB.* TO '$WDP_USER'@'localhost';

FLUSH PRIVILEGES;
SQL

echo "Configuring WordPress wp-config.php..."
cp "$WDP_DIR/wp-config-sample.php" "$WDP_DIR/wp-config.php"
sed -i "s/database_name_here/$WDP_DB/" "$WDP_DIR/wp-config.php"
sed -i "s/username_here/$WDP_USER/" "$WDP_DIR/wp-config.php"
sed -i "s/password_here/$WDP_PASS/" "$WDP_DIR/wp-config.php"

echo "Leaving SMF install.php and letting the web installer handle setup..."

echo "Cleanup..."
rm -f "$WDP_DIR"/wp-config-sample.php
rm -rf /tmp/smf_extract /tmp/smf.zip /tmp/wordpress*

echo
echo "Fresh install ready!"
echo " - WordPress: http://localhost/wdp"
echo " - SMF Forum Installer: http://localhost/smf/install.php"
echo
