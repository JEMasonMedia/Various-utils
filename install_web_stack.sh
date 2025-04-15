#!/bin/bash

set -e

echo "Updating system..."
apt update && apt upgrade -y

echo "Installing dependencies for PHP repository..."
apt install -y apt-transport-https lsb-release ca-certificates curl gnupg2

echo "Adding Sury PHP repo (for PHP 8.3)..."
curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/php.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

echo "Updating package list..."
apt update

echo "Installing Nginx, MariaDB, and PHP 8.3 with common extensions..."
apt install -y nginx mariadb-server php8.3 php8.3-fpm php8.3-mysql php8.3-cli \
php8.3-curl php8.3-xml php8.3-mbstring php8.3-zip php8.3-gd unzip wget

echo "Enabling and starting services..."
systemctl enable nginx
systemctl enable mariadb
systemctl enable php8.3-fpm

systemctl start nginx
systemctl start mariadb
systemctl start php8.3-fpm

echo
echo "LAMP-ish stack is ready:"
echo "- Nginx"
echo "- PHP 8.3"
echo "- MariaDB"
echo
